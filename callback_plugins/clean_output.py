from __future__ import (absolute_import, division, print_function)
__metaclass__ = type

DOCUMENTATION = '''
    name: clean_output
    type: stdout
    short_description: Shows only meaningful output - results, changes, and failures
    description:
        - Displays debug output (compliance results, health summaries), changed tasks, and failures
        - Suppresses verbose intermediate task output for cleaner playbook runs
    extends_documentation_fragment:
      - default_callback
    requirements:
      - set as stdout in configuration
'''

try:
    from ansible_collections.community.general.plugins.callback.yaml import CallbackModule as BaseCallbackModule
except ImportError:
    from ansible.plugins.callback.default import CallbackModule as BaseCallbackModule


class CallbackModule(BaseCallbackModule):
    """Ansible stdout callback that only shows actionable output."""

    CALLBACK_VERSION = 2.0
    CALLBACK_TYPE = 'stdout'
    CALLBACK_NAME = 'clean_output'

    def __init__(self):
        super(CallbackModule, self).__init__()
        self._pending_task = None
        self._pending_is_conditional = False

    def set_options(self, task_keys=None, var_options=None, direct=None):
        try:
            super(CallbackModule, self).set_options(
                task_keys=task_keys, var_options=var_options, direct=direct
            )
        except Exception:
            pass
        # Ensure parent attributes exist with sensible defaults
        for attr, default in [
            ('display_skipped_hosts', False),
            ('display_ok_hosts', True),
            ('show_per_host_start', False),
            ('display_failed_stderr', True),
            ('show_custom_stats', False),
            ('show_task_path_on_failure', False),
            ('check_mode_markers', False),
        ]:
            if not hasattr(self, attr):
                setattr(self, attr, default)

    # ---- Defer task banners

    def v2_playbook_on_task_start(self, task, is_conditional):
        self._pending_task = task
        self._pending_is_conditional = is_conditional

    def v2_playbook_on_handler_task_start(self, task):
        self._pending_task = task
        self._pending_is_conditional = False

    def _flush_task_banner(self):
        if self._pending_task is not None:
            super(CallbackModule, self).v2_playbook_on_task_start(
                self._pending_task, self._pending_is_conditional
            )
            self._pending_task = None

    # ---- Runner results: only show debug, changed, failed ----

    def v2_runner_on_ok(self, result):
        action = result._task.action
        if action in ('debug', 'ansible.builtin.debug') or result.is_changed():
            self._flush_task_banner()
            super(CallbackModule, self).v2_runner_on_ok(result)

    def v2_runner_on_failed(self, result, ignore_errors=False):
        self._flush_task_banner()
        super(CallbackModule, self).v2_runner_on_failed(result, ignore_errors)

    def v2_runner_on_unreachable(self, result):
        self._flush_task_banner()
        super(CallbackModule, self).v2_runner_on_unreachable(result)

    def v2_runner_on_skipped(self, result):
        pass

    # ---- Loop items: only show changed and failed ----

    def v2_runner_item_on_ok(self, result):
        if result.is_changed():
            self._flush_task_banner()
            super(CallbackModule, self).v2_runner_item_on_ok(result)

    def v2_runner_item_on_failed(self, result):
        self._flush_task_banner()
        super(CallbackModule, self).v2_runner_item_on_failed(result)

    def v2_runner_item_on_skipped(self, result):
        pass

    # ---- Suppress include messages ----

    def v2_playbook_on_include(self, included_file):
        pass
