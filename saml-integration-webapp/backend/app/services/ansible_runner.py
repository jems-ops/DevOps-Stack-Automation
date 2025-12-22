"""Ansible Runner service for executing playbooks."""
import asyncio
import ansible_runner
from pathlib import Path
from typing import Optional, Callable, AsyncGenerator, Dict, Any
from datetime import datetime

from app.config import settings


class AnsibleRunnerService:
    """Service for running Ansible playbooks."""

    def __init__(self, project_root: Optional[Path] = None):
        """Initialize Ansible runner service.

        Args:
            project_root: Path to Ansible project root (where playbooks/ and roles/ are located)
        """
        self.project_root = project_root or settings.ANSIBLE_PROJECT_ROOT
        self.playbooks_dir = self.project_root / "playbooks"
        self.roles_dir = self.project_root / "roles"
        self.inventory_path = self.project_root / settings.ANSIBLE_INVENTORY

        # Verify paths exist
        if not self.project_root.exists():
            raise ValueError(f"Ansible project root does not exist: {self.project_root}")
        if not self.playbooks_dir.exists():
            raise ValueError(f"Playbooks directory does not exist: {self.playbooks_dir}")

    async def run_saml_integration(
        self,
        app_type: str,
        configuration: Dict[str, Any],
        callback: Optional[Callable[[Dict], None]] = None
    ) -> Dict[str, Any]:
        """Run SAML integration playbook for a specific app.

        Args:
            app_type: Application type (jenkins, sonarqube, artifactory, nexus)
            configuration: Configuration dict with all required variables
            callback: Optional callback function for real-time updates

        Returns:
            Dict containing execution results
        """
        # Map app type to playbook
        playbook = "configure-keycloak-saml-integration.yml"

        # Prepare extra vars with proper variable names for the role
        extra_vars = {
            "app": app_type,
            # Keycloak configuration
            "keycloak_hostname": configuration.get("keycloak_hostname", "keycloak.local"),
            "keycloak_base_url": configuration.get("keycloak_url", f"https://keycloak.local"),
            "keycloak_admin_api_url": configuration.get("keycloak_url", f"https://keycloak.local"),
            # Application-specific base URL
            f"{app_type}_base_url": configuration.get(f"{app_type}_url", f"https://{app_type}.local"),
            f"{app_type}_hostname": configuration.get(f"{app_type}_hostname", f"{app_type}.local"),
            # Realm
            "keycloak_saml_integration_realm_name": configuration.get("realm", "master"),
            # HTTPS configuration
            "keycloak_saml_integration_use_https": configuration.get("use_https", True),
        }

        # Run playbook
        result = await self.run_playbook(
            playbook=playbook,
            extra_vars=extra_vars,
            callback=callback
        )

        return result

    async def run_playbook(
        self,
        playbook: str,
        extra_vars: Optional[Dict[str, Any]] = None,
        inventory: Optional[str] = None,
        callback: Optional[Callable[[Dict], None]] = None,
        limit: Optional[str] = None,
        tags: Optional[list[str]] = None,
    ) -> Dict[str, Any]:
        """Execute an Ansible playbook.

        Args:
            playbook: Playbook filename (in playbooks/ directory)
            extra_vars: Dictionary of extra variables to pass to playbook
            inventory: Path to inventory file (relative to project root)
            callback: Callback function to receive real-time updates
            limit: Limit execution to specific hosts
            tags: Run only tasks with specific tags

        Returns:
            Dict with execution results:
                - status: 'success' | 'failed' | 'timeout'
                - rc: Return code
                - stdout: Standard output
                - stats: Ansible stats
                - events: List of events
        """
        # Build playbook path
        playbook_path = str(self.playbooks_dir / playbook)

        # Use default inventory if not specified
        inventory_path = inventory or str(self.inventory_path)

        # Create a temporary private data directory for ansible-runner artifacts
        import tempfile
        private_data_dir = Path(tempfile.mkdtemp(prefix="ansible_runner_"))

        # Prepare runner config
        runner_config = {
            "private_data_dir": str(private_data_dir),
            "playbook": playbook_path,
            "inventory": inventory_path,
            "extravars": extra_vars or {},
            "quiet": False,
            "verbosity": 2,
        }

        if limit:
            runner_config["limit"] = limit

        if tags:
            runner_config["tags"] = ",".join(tags)

        # Run in a thread pool since ansible_runner is synchronous
        loop = asyncio.get_event_loop()

        def _run_ansible():
            """Run Ansible in thread."""
            return ansible_runner.run(**runner_config)

        # Execute playbook
        runner_result = await loop.run_in_executor(None, _run_ansible)

        # Process results
        result = {
            "status": runner_result.status,  # 'successful', 'failed', 'timeout'
            "rc": runner_result.rc,
            "stats": runner_result.stats,
            "events": [],
            "stdout": "",
            "start_time": None,
            "end_time": None,
        }

        # Collect events and output
        if runner_result.events:
            for event in runner_result.events:
                event_data = {
                    "event": event.get("event", ""),
                    "task": event.get("event_data", {}).get("task", ""),
                    "host": event.get("event_data", {}).get("host", ""),
                    "result": event.get("event_data", {}).get("res", {}),
                    "timestamp": event.get("created", ""),
                }
                result["events"].append(event_data)

                # Call callback if provided
                if callback:
                    callback(event_data)

        # Collect stdout
        if runner_result.stdout:
            result["stdout"] = runner_result.stdout.read()

        # Cleanup temporary directory
        import shutil
        try:
            shutil.rmtree(private_data_dir)
        except Exception:
            pass  # Best effort cleanup

        return result

    async def validate_playbook(self, playbook: str) -> Dict[str, Any]:
        """Validate playbook syntax.

        Args:
            playbook: Playbook filename

        Returns:
            Dict with validation results
        """
        playbook_path = self.playbooks_dir / playbook

        if not playbook_path.exists():
            return {
                "valid": False,
                "error": f"Playbook not found: {playbook}"
            }

        # Use ansible-playbook --syntax-check
        loop = asyncio.get_event_loop()

        def _validate():
            import subprocess
            result = subprocess.run(
                ["ansible-playbook", "--syntax-check", str(playbook_path)],
                capture_output=True,
                text=True,
            )
            return result

        result = await loop.run_in_executor(None, _validate)

        return {
            "valid": result.returncode == 0,
            "error": result.stderr if result.returncode != 0 else None,
        }

    def get_available_roles(self) -> list[str]:
        """Get list of available Ansible roles.

        Returns:
            List of role names
        """
        if not self.roles_dir.exists():
            return []

        roles = []
        for role_path in self.roles_dir.iterdir():
            if role_path.is_dir() and not role_path.name.startswith("."):
                roles.append(role_path.name)

        return sorted(roles)

    def get_available_playbooks(self) -> list[str]:
        """Get list of available playbooks.

        Returns:
            List of playbook filenames
        """
        if not self.playbooks_dir.exists():
            return []

        playbooks = []
        for playbook_path in self.playbooks_dir.glob("*.yml"):
            playbooks.append(playbook_path.name)

        return sorted(playbooks)

    async def stream_playbook_output(
        self,
        playbook: str,
        extra_vars: Optional[Dict[str, Any]] = None,
    ) -> AsyncGenerator[Dict[str, Any], None]:
        """Stream playbook execution output in real-time.

        Args:
            playbook: Playbook filename
            extra_vars: Extra variables

        Yields:
            Event dictionaries as they occur
        """
        # This would require a custom callback plugin or event streaming
        # For now, we'll use the standard run_playbook with a callback

        events_queue = asyncio.Queue()

        def callback(event: Dict):
            """Callback to queue events."""
            asyncio.create_task(events_queue.put(event))

        # Start playbook execution in background
        playbook_task = asyncio.create_task(
            self.run_playbook(playbook, extra_vars, callback=callback)
        )

        # Stream events as they come
        while not playbook_task.done():
            try:
                event = await asyncio.wait_for(events_queue.get(), timeout=0.1)
                yield event
            except asyncio.TimeoutError:
                continue

        # Get remaining events
        while not events_queue.empty():
            yield await events_queue.get()

        # Yield final result
        result = await playbook_task
        yield {
            "event": "playbook_complete",
            "status": result["status"],
            "rc": result["rc"],
        }


# Singleton instance
ansible_service = AnsibleRunnerService()
