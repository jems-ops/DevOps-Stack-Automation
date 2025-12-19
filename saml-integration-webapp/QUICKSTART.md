# SAML Integration WebApp - Quick Start Guide

Get up and running in 5 minutes!

## Prerequisites

- Python 3.11+
- Node.js 18+
- Redis
- Git

## Step 1: Clone and Setup (if not already in the repo)

```bash
cd jenkins-ansible-automation/saml-integration-webapp
```

## Step 2: Backend Setup

```bash
cd backend

# Create virtual environment
python3 -m venv venv

# Activate virtual environment
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Create environment file
cp .env.example .env

# Edit .env - Set ANSIBLE_PROJECT_ROOT to absolute path
# Example: ANSIBLE_PROJECT_ROOT=/Users/yourname/jenkins-ansible-automation
nano .env  # or use your favorite editor

# Test the backend
python -m app.main
```

The backend should start on http://localhost:8000

Visit http://localhost:8000/docs to see the API documentation!

##  Step 3: Start Redis

In a new terminal:

```bash
# Option 1: Using Docker (recommended)
docker run --name saml-redis -p 6379:6379 -d redis:alpine

# Option 2: Local Redis (if installed)
redis-server
```

## Step 4: Frontend Setup (Optional for Phase 1)

In a new terminal:

```bash
cd saml-integration-webapp/frontend

# Install dependencies
npm install

# Create environment file
echo "VITE_API_URL=http://localhost:8000" > .env.local
echo "VITE_WS_URL=ws://localhost:8000" >> .env.local

# Start development server
npm run dev
```

Frontend will be available at http://localhost:5173

## Step 5: Test the API

### Check Health

```bash
curl http://localhost:8000/health
```

Expected response:
```json
{
  "status": "healthy",
  "app": "SAML Integration API",
  "version": "1.0.0"
}
```

### List Available Roles (will be implemented)

```bash
curl http://localhost:8000/api/v1/ansible/roles
```

## Quick Docker Setup (Alternative)

If you prefer using Docker for everything:

```bash
cd saml-integration-webapp/deployment

# Start all services
docker-compose up -d

# View logs
docker-compose logs -f backend

# Stop all services
docker-compose down
```

Access:
- Backend API: http://localhost:8000
- Frontend: http://localhost:3000
- API Docs: http://localhost:8000/docs

## Next Steps

### 1. Test Ansible Integration

```bash
# Make sure you're in the backend venv
cd backend
source venv/bin/activate

# Test Ansible service
python -c "
from app.services.ansible_runner import ansible_service
print('Available roles:', ansible_service.get_available_roles())
print('Available playbooks:', ansible_service.get_available_playbooks())
"
```

### 2. Explore the API

Visit http://localhost:8000/docs for interactive API documentation.

### 3. Start Developing

#### Backend Development

```bash
cd backend

# Run with auto-reload
uvicorn app.main:app --reload --port 8000

# Run tests
pytest

# Format code
black app/
ruff check app/
```

#### Frontend Development

```bash
cd frontend

# Development mode
npm run dev

# Build for production
npm run build

# Run tests
npm test
```

## Project Structure Overview

```
saml-integration-webapp/
├── backend/              # FastAPI application
│   ├── app/
│   │   ├── api/         # REST API endpoints
│   │   ├── services/    # Business logic
│   │   ├── models/      # Database models
│   │   ├── schemas/     # Pydantic schemas
│   │   └── main.py      # Application entry
│   └── requirements.txt
│
├── frontend/            # React application
│   ├── src/
│   │   ├── components/  # React components
│   │   ├── pages/       # Page components
│   │   └── services/    # API clients
│   └── package.json
│
├── deployment/          # Docker configs
│   └── docker-compose.yml
│
└── docs/                # Documentation
    └── IMPLEMENTATION_PLAN.md
```

## Common Issues

### Backend won't start

**Error**: `ModuleNotFoundError: No module named 'app'`

**Solution**: Make sure you're in the `backend` directory and have activated the venv:
```bash
cd backend
source venv/bin/activate
python -m app.main
```

---

**Error**: `Ansible project root does not exist`

**Solution**: Update `ANSIBLE_PROJECT_ROOT` in `.env` to the absolute path:
```bash
# Find your project root
pwd  # Should be something like /Users/you/jenkins-ansible-automation

# Update .env
ANSIBLE_PROJECT_ROOT=/Users/you/jenkins-ansible-automation
```

### Redis connection fails

**Error**: `redis.exceptions.ConnectionError`

**Solution**: Make sure Redis is running:
```bash
# Check if Redis is running
redis-cli ping
# Should return: PONG

# If not running, start it:
docker run -p 6379:6379 -d redis:alpine
```

### Frontend can't connect to backend

**Error**: `Network Error` or CORS errors

**Solution**:
1. Check if backend is running on port 8000
2. Verify `VITE_API_URL` in `frontend/.env.local`
3. Check CORS settings in `backend/app/config.py`

## Development Workflow

### Adding a New API Endpoint

1. Create schema in `backend/app/schemas/`
2. Create route in `backend/app/api/v1/`
3. Include router in `backend/app/main.py`
4. Test with `curl` or `/docs`
5. Create frontend service in `frontend/src/services/`
6. Use in React components

### Adding a New Application Support

1. Add configuration to `roles/keycloak_saml_integration/vars/apps/`
2. Create app card in frontend
3. Define configuration schema
4. Test deployment

## Environment Variables Reference

### Backend

| Variable | Description | Default |
|----------|-------------|---------|
| `DATABASE_URL` | Database connection string | `sqlite+aiosqlite:///./saml_integration.db` |
| `REDIS_URL` | Redis connection string | `redis://localhost:6379/0` |
| `ANSIBLE_PROJECT_ROOT` | Path to Ansible project | (required) |
| `SECRET_KEY` | JWT secret key | (change in production!) |
| `DEBUG` | Enable debug mode | `False` |

### Frontend

| Variable | Description | Default |
|----------|-------------|---------|
| `VITE_API_URL` | Backend API URL | `http://localhost:8000` |
| `VITE_WS_URL` | WebSocket URL | `ws://localhost:8000` |

## Testing

### Backend Tests

```bash
cd backend
pytest tests/
pytest --cov=app tests/  # With coverage
```

### Frontend Tests

```bash
cd frontend
npm test
npm run test:ui  # Interactive UI
```

## Production Deployment

See [IMPLEMENTATION_PLAN.md](docs/IMPLEMENTATION_PLAN.md) for production deployment guide.

Quick production checklist:
- [ ] Change `SECRET_KEY` to a strong random value
- [ ] Set `DEBUG=False`
- [ ] Use PostgreSQL instead of SQLite
- [ ] Enable HTTPS
- [ ] Set up proper logging
- [ ] Configure monitoring
- [ ] Set up backups

## Getting Help

- 📚 Documentation: [docs/](docs/)
- 🐛 Issues: Create an issue in the repository
- 💬 Discussions: Use GitHub Discussions

## Next Phase Features

The current implementation provides:
- ✅ Basic backend structure
- ✅ Ansible integration service
- ✅ Configuration management
- ✅ Docker setup

Coming soon:
- [ ] Complete API endpoints (deployments, applications)
- [ ] Database models and migrations
- [ ] User authentication
- [ ] Frontend UI
- [ ] Real-time WebSocket updates
- [ ] Deployment history

## Contributing

1. Create a feature branch
2. Make your changes
3. Add tests
4. Submit a pull request

Happy coding! 🚀
