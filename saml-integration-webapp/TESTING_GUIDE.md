# SAML Integration WebApp - Testing Guide

Complete guide to test the full-stack SAML Integration WebApp.

## Prerequisites

- Python 3.11+
- Node.js 18+
- Redis running
- Your Ansible project with roles

## Quick Start

### Terminal 1: Start Redis

```bash
docker run --name saml-redis -p 6379:6379 -d redis:alpine
```

### Terminal 2: Start Backend

```bash
cd saml-integration-webapp/backend

# Create virtual environment (if not done)
python3 -m venv venv
source venv/bin/activate

# Install dependencies (if not done)
pip install -r requirements.txt

# Create .env file
cp .env.example .env

# Edit .env - SET YOUR ANSIBLE_PROJECT_ROOT
# Example: ANSIBLE_PROJECT_ROOT=/Users/jimi/jenkins-ansible-automation
nano .env

# Start backend
python -m app.main
```

**Expected output:**
```
🚀 Starting SAML Integration API v1.0.0
📁 Ansible Project Root: /Users/jimi/jenkins-ansible-automation
📊 Initializing database...
✅ Database initialized
INFO:     Started server process [12345]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Uvicorn running on http://0.0.0.0:8000
```

### Terminal 3: Start Frontend

```bash
cd saml-integration-webapp/frontend

# Install dependencies (first time only)
npm install

# Start development server
npm run dev
```

**Expected output:**
```
  VITE v5.0.11  ready in 234 ms

  ➜  Local:   http://localhost:3000/
  ➜  Network: use --host to expose
  ➜  press h to show help
```

## Testing Workflow

### 1. Test Backend API (http://localhost:8000/docs)

#### Health Check
```bash
curl http://localhost:8000/health
```

**Expected:**
```json
{
  "status": "healthy",
  "app": "SAML Integration API",
  "version": "1.0.0"
}
```

#### List Applications
```bash
curl http://localhost:8000/api/v1/applications
```

**Expected:** JSON with 4 applications (jenkins, sonarqube, artifactory, nexus)

#### Get Application Details
```bash
curl http://localhost:8000/api/v1/applications/jenkins
```

**Expected:** Jenkins configuration schema with 3 fields

### 2. Test Frontend (http://localhost:3000)

#### Step 1: Application Selection

1. Open http://localhost:3000 in your browser
2. You should see **4 application cards**:
   - Jenkins (red icon)
   - SonarQube (blue icon)
   - JFrog Artifactory (green icon)
   - Nexus Repository (blue icon)
3. Each card should show:
   - Application icon
   - Display name
   - Description text
4. Cards should be hoverable with visual feedback

**Test:** Click on Jenkins

#### Step 2: Configuration Form

1. You should see the configuration form for Jenkins
2. Form should have these fields:
   - **Jenkins URL** (required, URL validation)
   - **Keycloak URL** (required, URL validation)
   - **Keycloak Realm** (required, default: "master")
3. Each field should have help text below it
4. There should be a blue info alert at the top
5. **← Back to Applications** button at the top
6. **Deploy SAML Integration** button at the bottom

**Test:** Click the back button → Should return to app selection

**Test:** Try submitting without filling fields → Should show validation errors

**Test:** Fill in test values:
```
Jenkins URL: http://192.168.201.10
Keycloak URL: http://192.168.201.15
Keycloak Realm: master
```

**Test:** Click "Deploy SAML Integration"

#### Step 3: Deployment Status

1. You should immediately see:
   - Status badge: "PENDING" or "RUNNING"
   - Deployment ID
   - Application: JENKINS
   - Created timestamp
2. Status should change to "RUNNING" within a few seconds
3. You should see a blue spinning alert: "Deployment in Progress"
4. The page polls every 3 seconds for updates

**What happens in background:**
- Backend creates deployment record (status: pending)
- Background task starts Ansible playbook execution
- Status updates to: running → success/failed
- Frontend polls deployment endpoint every 3s

**When deployment completes:**
- Status changes to "SUCCESS" (green) or "FAILED" (red)
- Green success alert or red error alert appears
- Deployment duration is shown
- Ansible playbook output appears in terminal-style box
- Two buttons appear:
  - "View All Deployments" (placeholder)
  - "New Deployment" (returns to app selection)

### 3. Test End-to-End with Mock Deployment

If you don't want to run actual Ansible playbooks yet, you can test with mock data:

#### Backend Test Script

```bash
cd saml-integration-webapp/backend
source venv/bin/activate
python test_api.py
```

**Expected output:**
```
🏥 Testing health check...
   Status: 200
   Response: {'status': 'healthy', ...}

📱 Testing applications list...
   Status: 200
   Found 4 applications
     - Jenkins: Jenkins CI/CD automation server...
     - SonarQube: SonarQube code quality...
     - JFrog Artifactory: JFrog Artifactory...
     - Nexus Repository: Sonatype Nexus...

📱 Testing get Jenkins application...
   Status: 200
   Name: Jenkins
   Config fields: 3
     - Jenkins URL: url
     - Keycloak URL: url
     - Keycloak Realm: text

📦 Testing deployments list...
   Status: 200
   Total deployments: 0

✅ All tests passed!
```

### 4. Test Real SAML Deployment

**Prerequisites:**
- Ansible inventory configured
- Target servers accessible
- Vault credentials available
- Keycloak and application instances running

#### Create Real Deployment via Frontend

1. Select **Jenkins** from app selector
2. Fill in REAL values:
   ```
   Jenkins URL: https://jenkins.local
   Keycloak URL: https://keycloak.local
   Keycloak Realm: master
   ```
3. Click "Deploy SAML Integration"
4. Watch the deployment status page
5. After 2-5 minutes, should see SUCCESS
6. Check Ansible output in the terminal-style box

#### Verify Deployment via Backend Logs

Check Terminal 2 (backend) for logs:
```
INFO: Started deployment <uuid>
INFO: Executing Ansible playbook...
INFO: Deployment <uuid> completed with status: success
```

#### Verify in Database

```bash
cd saml-integration-webapp/backend
source venv/bin/activate
python

>>> from app.database import AsyncSessionLocal
>>> from app.models.deployment import Deployment
>>> from sqlalchemy import select
>>> 
>>> async def check():
...     async with AsyncSessionLocal() as session:
...         result = await session.execute(select(Deployment))
...         deployments = result.scalars().all()
...         for d in deployments:
...             print(f"{d.id} - {d.app_type} - {d.status}")
... 
>>> import asyncio
>>> asyncio.run(check())
```

### 5. Test Error Scenarios

#### Invalid URL
1. Enter an invalid URL: `not-a-url`
2. Try to submit
3. **Expected:** Red validation error below field

#### Backend Down
1. Stop the backend (Ctrl+C in Terminal 2)
2. Try to load frontend
3. **Expected:** Error message "Failed to load applications"

#### Network Error During Deployment
1. Start a deployment
2. While running, stop the backend
3. **Expected:** Frontend continues polling, shows error in console

### 6. Test Browser Compatibility

Test in these browsers:
- ✅ Chrome/Edge (recommended)
- ✅ Firefox
- ✅ Safari

**Note:** Ant Design works best in modern browsers

### 7. Test Responsive Design

1. Open browser DevTools (F12)
2. Toggle device toolbar (Ctrl+Shift+M)
3. Test different screen sizes:
   - Mobile (375px): Cards stack vertically
   - Tablet (768px): 2 cards per row
   - Desktop (1200px+): 4 cards per row

## Troubleshooting

### Backend won't start

**Error:** `ModuleNotFoundError: No module named 'app'`

**Solution:**
```bash
cd backend
source venv/bin/activate
pip install -r requirements.txt
python -m app.main
```

---

**Error:** `Ansible project root does not exist`

**Solution:** Update `ANSIBLE_PROJECT_ROOT` in `.env`:
```bash
pwd  # Get absolute path
# Edit .env with absolute path
ANSIBLE_PROJECT_ROOT=/Users/jimi/jenkins-ansible-automation
```

---

**Error:** `sqlalchemy.exc.OperationalError: (sqlite3.OperationalError) unable to open database file`

**Solution:** Make sure you have write permissions in the backend directory

### Frontend won't start

**Error:** `Cannot find module 'react'`

**Solution:**
```bash
cd frontend
rm -rf node_modules package-lock.json
npm install
```

---

**Error:** `Failed to load applications`

**Solution:** Check if backend is running on port 8000:
```bash
curl http://localhost:8000/health
```

### Deployment stuck in "running"

**Symptom:** Deployment status stays "running" forever

**Debug:**
1. Check backend logs in Terminal 2
2. Check for Ansible errors:
   ```bash
   tail -f backend/ansible.log  # if logging enabled
   ```
3. Check database:
   ```bash
   sqlite3 backend/saml_integration.db "SELECT * FROM deployments;"
   ```

**Common causes:**
- Ansible playbook syntax error
- Inventory not accessible
- Target hosts unreachable

### CORS errors in browser console

**Error:** `Access to XMLHttpRequest blocked by CORS policy`

**Solution:** Check backend CORS settings in `backend/app/config.py`:
```python
CORS_ORIGINS = [
    "http://localhost:3000",
    "http://localhost:5173",
]
```

Make sure your frontend URL is in the list.

## Performance Testing

### Load Test

```bash
# Install hey
brew install hey  # macOS
# or download from https://github.com/rakyll/hey

# Test applications endpoint
hey -n 100 -c 10 http://localhost:8000/api/v1/applications

# Test deployments list
hey -n 100 -c 10 http://localhost:8000/api/v1/deployments
```

**Expected:**
- Response time < 100ms for applications endpoint
- Response time < 200ms for deployments list
- 0 errors

### Concurrent Deployments

1. Open 3 browser tabs
2. Start a deployment in each tab (different apps)
3. All should execute successfully
4. Check backend logs for concurrent execution

## Cleanup

### Stop All Services

```bash
# Terminal 1: Stop Redis
docker stop saml-redis
docker rm saml-redis

# Terminal 2: Stop Backend (Ctrl+C)

# Terminal 3: Stop Frontend (Ctrl+C)
```

### Clean Database

```bash
cd backend
rm saml_integration.db
```

### Clean Frontend Build

```bash
cd frontend
rm -rf dist node_modules
```

## Success Criteria

- ✅ Backend starts without errors
- ✅ Frontend loads and shows 4 application cards
- ✅ Can navigate: select app → configure → back
- ✅ Form validation works
- ✅ Can create a deployment
- ✅ Deployment status updates in real-time
- ✅ Can see Ansible output when deployment completes
- ✅ Can start a new deployment
- ✅ Backend API responds with correct data
- ✅ No console errors in browser

## Next Steps

Once testing is complete:
1. Deploy to production (see IMPLEMENTATION_PLAN.md)
2. Set up monitoring and alerting
3. Configure HTTPS
4. Set up user authentication
5. Add deployment history page
6. Implement WebSocket for real-time updates

## Getting Help

If you encounter issues:
1. Check the logs (backend terminal)
2. Check browser console (F12)
3. Review this guide again
4. Check the QUICKSTART.md
5. Review API docs at http://localhost:8000/docs

Happy testing! 🚀
