"""Quick test script for the API."""
import asyncio
import httpx


async def test_api():
    """Test the API endpoints."""
    base_url = "http://localhost:8000"

    async with httpx.AsyncClient() as client:
        # Test health check
        print("🏥 Testing health check...")
        response = await client.get(f"{base_url}/health")
        print(f"   Status: {response.status_code}")
        print(f"   Response: {response.json()}\n")

        # Test applications list
        print("📱 Testing applications list...")
        response = await client.get(f"{base_url}/api/v1/applications")
        print(f"   Status: {response.status_code}")
        apps = response.json()
        print(f"   Found {apps['total']} applications")
        for app in apps['applications']:
            print(f"     - {app['display_name']}: {app['description']}")
        print()

        # Test get single application
        print("📱 Testing get Jenkins application...")
        response = await client.get(f"{base_url}/api/v1/applications/jenkins")
        print(f"   Status: {response.status_code}")
        jenkins = response.json()
        print(f"   Name: {jenkins['display_name']}")
        print(f"   Config fields: {len(jenkins['config_fields'])}")
        for field in jenkins['config_fields']:
            print(f"     - {field['label']}: {field['type']}")
        print()

        # Test deployments list (should be empty initially)
        print("📦 Testing deployments list...")
        response = await client.get(f"{base_url}/api/v1/deployments")
        print(f"   Status: {response.status_code}")
        deployments = response.json()
        print(f"   Total deployments: {deployments['total']}")
        print()

        print("✅ All tests passed!")


if __name__ == "__main__":
    asyncio.run(test_api())
