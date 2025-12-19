# SAML Integration WebApp

A web application that provides a user-friendly interface to deploy SAML SSO integrations for DevOps applications using your existing Ansible roles.

## Features

- 🚀 **Quick Deployment**: Deploy SAML integrations in minutes instead of hours
- 📊 **Real-time Monitoring**: Watch Ansible playbook execution in real-time
- 📜 **Deployment History**: Track all deployments with detailed logs
- 🔐 **Secure**: JWT authentication, encrypted credentials, audit logging
- 🎨 **Modern UI**: React + TypeScript + Ant Design
- ⚡ **Fast API**: FastAPI backend with async support
- 🔄 **Job Queue**: Redis-backed task queue for concurrent deployments

## Supported Applications

- ✅ Jenkins
- ✅ SonarQube
- ✅ Artifactory
- ✅ Nexus

## Architecture

```
Frontend (React + TypeScript)
         ↓
    REST API + WebSocket
         ↓
Backend (FastAPI + Python)
         ↓
   Ansible Runner
         ↓
  Your Ansible Roles
```

## Quick Start

### Prerequisites

- Python 3.11+
- Node.js 18+
- Redis
- Docker (optional, for containerized deployment)

### Development Setup

#### 1. Backend Setup

```bash
cd saml-integration-webapp/backend

# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Create .env file
cp .env.example .env
# Edit .env with your settings

# Run database migrations
alembic upgrade head

# Start the backend server
uvicorn app.main:app --reload --port 8000
```

#### 2. Frontend Setup

```bash
cd saml-integration-webapp/frontend

# Install dependencies
npm install

# Create .env file
cp .env.example .env.local

# Start the development server
npm run dev
```

#### 3. Start Redis

```bash
# Using Docker
docker run -p 6379:6379 redis:alpine

# Or install locally
redis-server
```

#### 4. Start Worker

```bash
cd saml-integration-webapp/backend
source venv/bin/activate
python -m app.workers.deployment_worker
```

### Access the Application

- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:8000
- **API Docs**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

## Docker Deployment

```bash
# Build and start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

## Project Structure

```
saml-integration-webapp/
├── backend/                    # FastAPI backend
│   ├── app/
│   │   ├── api/               # API endpoints
│   │   │   └── v1/
│   │   │       ├── applications.py
│   │   │       ├── deployments.py
│   │   │       ├── environments.py
│   │   │       └── auth.py
│   │   ├── models/            # SQLAlchemy models
│   │   ├── schemas/           # Pydantic schemas
│   │   ├── services/          # Business logic
│   │   │   ├── ansible_runner.py
│   │   │   ├── deployment.py
│   │   │   └── queue.py
│   │   ├── workers/           # Background workers
│   │   ├── config.py          # Configuration
│   │   ├── database.py        # Database setup
│   │   └── main.py            # FastAPI app
│   ├── tests/
│   ├── requirements.txt
│   └── Dockerfile
│
├── frontend/                   # React frontend
│   ├── src/
│   │   ├── components/        # React components
│   │   ├── pages/             # Page components
│   │   ├── services/          # API clients
│   │   ├── hooks/             # Custom hooks
│   │   ├── types/             # TypeScript types
│   │   ├── App.tsx
│   │   └── main.tsx
│   ├── package.json
│   └── Dockerfile
│
├── deployment/                 # Deployment configs
│   ├── docker-compose.yml
│   ├── docker-compose.prod.yml
│   └── nginx.conf
│
└── docs/                       # Documentation
    ├── IMPLEMENTATION_PLAN.md
    ├── API.md
    └── USER_GUIDE.md
```

## Usage

### 1. Deploy a SAML Integration

1. Navigate to **New Deployment**
2. Select your application (e.g., Jenkins)
3. Choose an environment
4. Fill in the configuration form:
   - Application URL
   - Keycloak URL
   - Realm name
   - User attributes
5. Review the configuration
6. Click **Deploy**
7. Monitor the real-time deployment progress

### 2. View Deployment History

- Navigate to **History**
- Filter by application, status, or date
- Click on a deployment to view details
- Download logs if needed

### 3. Retry a Failed Deployment

- Go to deployment details
- Click **Retry**
- Optionally modify the configuration
- Deploy again

## API Examples

### List Applications

```bash
curl http://localhost:8000/api/v1/applications
```

### Create Deployment

```bash
curl -X POST http://localhost:8000/api/v1/deployments \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "app_type": "jenkins",
    "environment_id": "dev",
    "configuration": {
      "keycloak_url": "https://keycloak.local",
      "jenkins_url": "https://jenkins.local",
      "realm": "master"
    }
  }'
```

### Get Deployment Status

```bash
curl http://localhost:8000/api/v1/deployments/{deployment_id}
```

## Configuration

### Environment Variables

Create a `.env` file in the backend directory:

```env
# Database
DATABASE_URL=sqlite+aiosqlite:///./saml_integration.db

# Redis
REDIS_URL=redis://localhost:6379/0

# Ansible
ANSIBLE_PROJECT_ROOT=/path/to/jenkins-ansible-automation
ANSIBLE_INVENTORY=inventory/hosts

# Security
SECRET_KEY=your-super-secret-key-change-this-in-production
ACCESS_TOKEN_EXPIRE_MINUTES=30

# Logging
LOG_LEVEL=INFO
DEBUG=False
```

### Frontend Environment Variables

Create a `.env.local` file in the frontend directory:

```env
VITE_API_URL=http://localhost:8000
VITE_WS_URL=ws://localhost:8000
```

## Testing

### Backend Tests

```bash
cd backend
pytest
pytest --cov=app tests/  # With coverage
```

### Frontend Tests

```bash
cd frontend
npm test
npm run test:e2e  # E2E tests
```

## Development

### Adding a New Application

1. Add app configuration to `backend/app/services/applications.py`
2. Create app-specific schema in `backend/app/schemas/`
3. Update frontend to include new app in `apps.ts`
4. Add app icon/logo to `frontend/src/assets/`

### API Documentation

Visit http://localhost:8000/docs for interactive API documentation (Swagger UI).

## Troubleshooting

### Backend won't start

- Check if Redis is running: `redis-cli ping`
- Verify database connection
- Check logs: `tail -f logs/app.log`

### Deployments fail immediately

- Verify Ansible is installed: `ansible --version`
- Check Ansible project root path in `.env`
- Ensure inventory file exists
- Test playbook manually:
  ```bash
  ansible-playbook playbooks/configure-keycloak-saml-integration.yml -e "app=jenkins"
  ```

### WebSocket connection fails

- Check CORS settings in `backend/app/config.py`
- Verify WebSocket URL in frontend `.env.local`
- Check browser console for errors

## Security

- **Never commit** `.env` files
- **Rotate** JWT secret keys regularly
- **Use HTTPS** in production
- **Encrypt** sensitive data in the database
- **Audit** all deployment actions

## Contributing

1. Create a feature branch
2. Make your changes
3. Add tests
4. Run linters: `black .` and `ruff check .`
5. Submit a pull request

## License

MIT License - See LICENSE file for details

## Support

For issues and questions:
- Check the [documentation](docs/)
- Review [existing issues](../../issues)
- Create a [new issue](../../issues/new)

## Roadmap

See [IMPLEMENTATION_PLAN.md](docs/IMPLEMENTATION_PLAN.md) for detailed roadmap.

### Phase 1 (Current)
- [x] Project structure
- [x] Backend API skeleton
- [ ] Frontend basic UI
- [ ] Ansible integration
- [ ] Real-time monitoring

### Phase 2 (Next)
- [ ] User authentication
- [ ] Environment management
- [ ] Deployment history
- [ ] Configuration templates

### Phase 3 (Future)
- [ ] Role-based access control
- [ ] Slack/Teams notifications
- [ ] Multi-tenancy
- [ ] Mobile app
