# SAML Integration WebApp - Implementation Plan

## Overview
A web application that provides a user-friendly interface to deploy SAML SSO integrations for DevOps applications (Jenkins, SonarQube, Artifactory, Nexus) using existing Ansible roles as the backend engine.

## Architecture

### High-Level Architecture
```
┌──────────────────────────────────────────────────────┐
│                 Frontend (React)                     │
│  - Application Selection                             │
│  - Configuration Forms                               │
│  - Real-time Deployment Monitor                      │
│  - Deployment History                                │
└────────────────┬─────────────────────────────────────┘
                 │ REST API + WebSocket
┌────────────────▼─────────────────────────────────────┐
│           Backend API (FastAPI)                      │
│  - API Endpoints                                     │
│  - Authentication & Authorization                    │
│  - Ansible Runner Integration                        │
│  - Job Queue Management (Redis)                      │
└────────────────┬─────────────────────────────────────┘
                 │
    ┌────────────┼────────────┐
    │            │            │
    ▼            ▼            ▼
┌───────┐   ┌────────┐   ┌──────────────┐
│Redis  │   │SQLite/ │   │Ansible Roles │
│Queue  │   │Postgres│   │  (Existing)  │
└───────┘   └────────┘   └──────────────┘
```

### Technology Stack

#### Frontend
- **Framework**: React 18 + TypeScript
- **Build Tool**: Vite
- **UI Library**: Ant Design (antd)
- **State Management**: Zustand (lightweight) or React Query
- **HTTP Client**: Axios
- **WebSocket**: Socket.io-client
- **Styling**: TailwindCSS + Ant Design

#### Backend
- **Framework**: FastAPI (Python 3.11+)
- **Async Runtime**: uvicorn + asyncio
- **Task Queue**: Python RQ (Redis Queue)
- **Ansible Integration**: ansible-runner
- **Database**: SQLite (dev) / PostgreSQL (prod)
- **ORM**: SQLAlchemy 2.0
- **Authentication**: JWT tokens (python-jose)
- **Validation**: Pydantic v2
- **WebSocket**: Socket.io (socketio)

#### Infrastructure
- **Containerization**: Docker + Docker Compose
- **Reverse Proxy**: Nginx (optional)
- **Secret Management**: Ansible Vault integration
- **Monitoring**: Built-in logging + optional Prometheus

## Database Schema

### Tables

#### 1. deployments
```sql
CREATE TABLE deployments (
    id UUID PRIMARY KEY,
    app_type VARCHAR(50) NOT NULL,  -- jenkins, sonarqube, artifactory, nexus
    status VARCHAR(20) NOT NULL,     -- pending, running, success, failed, cancelled
    created_at TIMESTAMP DEFAULT NOW(),
    started_at TIMESTAMP,
    completed_at TIMESTAMP,
    created_by VARCHAR(100),
    error_message TEXT,
    playbook_output TEXT,
    configuration JSONB              -- stores the form inputs
);
```

#### 2. applications
```sql
CREATE TABLE applications (
    id UUID PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    display_name VARCHAR(100),
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    config_schema JSONB,             -- JSON schema for validation
    default_config JSONB,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);
```

#### 3. environments
```sql
CREATE TABLE environments (
    id UUID PRIMARY KEY,
    name VARCHAR(50) NOT NULL,       -- dev, staging, prod
    keycloak_url VARCHAR(255),
    vault_path VARCHAR(255),
    ansible_inventory_path VARCHAR(255),
    created_at TIMESTAMP DEFAULT NOW()
);
```

#### 4. credentials (encrypted)
```sql
CREATE TABLE credentials (
    id UUID PRIMARY KEY,
    environment_id UUID REFERENCES environments(id),
    credential_type VARCHAR(50),     -- keycloak_admin, app_admin, vault_token
    encrypted_value TEXT NOT NULL,   -- encrypted with app secret key
    created_at TIMESTAMP DEFAULT NOW(),
    expires_at TIMESTAMP
);
```

#### 5. users
```sql
CREATE TABLE users (
    id UUID PRIMARY KEY,
    username VARCHAR(100) UNIQUE NOT NULL,
    email VARCHAR(255),
    hashed_password VARCHAR(255),
    is_active BOOLEAN DEFAULT true,
    is_admin BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT NOW()
);
```

## API Design

### REST Endpoints

#### Applications
- `GET /api/v1/applications` - List all supported applications
- `GET /api/v1/applications/{app_name}` - Get app details and config schema
- `GET /api/v1/applications/{app_name}/defaults` - Get default configuration

#### Deployments
- `POST /api/v1/deployments` - Create new deployment
- `GET /api/v1/deployments` - List deployments (with pagination)
- `GET /api/v1/deployments/{deployment_id}` - Get deployment details
- `GET /api/v1/deployments/{deployment_id}/logs` - Stream deployment logs
- `DELETE /api/v1/deployments/{deployment_id}` - Cancel running deployment
- `POST /api/v1/deployments/{deployment_id}/retry` - Retry failed deployment

#### Environments
- `GET /api/v1/environments` - List environments
- `POST /api/v1/environments` - Create environment
- `PUT /api/v1/environments/{env_id}` - Update environment
- `DELETE /api/v1/environments/{env_id}` - Delete environment

#### System
- `GET /api/v1/health` - Health check
- `GET /api/v1/version` - API version info
- `GET /api/v1/ansible/roles` - List available Ansible roles
- `POST /api/v1/ansible/validate` - Validate Ansible configuration

#### Authentication
- `POST /api/v1/auth/login` - User login
- `POST /api/v1/auth/logout` - User logout
- `POST /api/v1/auth/refresh` - Refresh JWT token
- `GET /api/v1/auth/me` - Get current user

### WebSocket Events

#### Client → Server
- `deployment:start` - Start deployment
- `deployment:cancel` - Cancel deployment
- `deployment:subscribe` - Subscribe to deployment updates

#### Server → Client
- `deployment:status` - Deployment status change
- `deployment:log` - New log line
- `deployment:progress` - Progress update (percentage)
- `deployment:complete` - Deployment finished
- `deployment:error` - Deployment error

## Frontend UI Components

### Pages

#### 1. Dashboard
- Overview of recent deployments
- Quick stats (success rate, active deployments)
- Quick action buttons for each app

#### 2. New Deployment
- **Step 1**: Select application (cards with logos)
- **Step 2**: Select environment (dropdown)
- **Step 3**: Configure SAML settings (dynamic form)
  - Keycloak URL
  - Application URL
  - Realm settings
  - User attributes
  - Advanced options (collapsible)
- **Step 4**: Review and deploy
  - Summary of configuration
  - Validation status
  - Deploy button

#### 3. Deployment Monitor
- Real-time task execution view
- Ansible playbook output (terminal-like)
- Progress bar per task
- Success/failure indicators
- Cancel button
- Download logs button

#### 4. Deployment History
- Table view with filters
  - By app type
  - By status
  - By date range
  - By user
- Actions: View details, Retry, Clone config

#### 5. Settings
- Environment management
- Credential management
- User preferences
- System configuration

### Key UI Components

#### AppSelector
```typescript
interface App {
  id: string;
  name: string;
  displayName: string;
  description: string;
  icon: string;
  isActive: boolean;
}

<AppSelector
  apps={apps}
  onSelect={(app) => setSelectedApp(app)}
/>
```

#### ConfigurationForm
```typescript
interface ConfigField {
  name: string;
  label: string;
  type: 'text' | 'url' | 'select' | 'checkbox' | 'password';
  required: boolean;
  defaultValue?: any;
  validation?: RegExp;
  helpText?: string;
}

<ConfigurationForm
  schema={configSchema}
  initialValues={defaults}
  onSubmit={handleDeploy}
/>
```

#### DeploymentMonitor
```typescript
<DeploymentMonitor
  deploymentId={id}
  onComplete={() => navigate('/history')}
/>
```

#### LogViewer
```typescript
<LogViewer
  logs={deploymentLogs}
  isStreaming={isRunning}
  canDownload={true}
/>
```

## Backend Implementation Details

### Project Structure
```
backend/
├── app/
│   ├── __init__.py
│   ├── main.py                 # FastAPI app entry point
│   ├── config.py              # Configuration settings
│   ├── database.py            # Database connection
│   ├── dependencies.py        # Dependency injection
│   │
│   ├── api/
│   │   ├── __init__.py
│   │   ├── v1/
│   │   │   ├── __init__.py
│   │   │   ├── applications.py
│   │   │   ├── deployments.py
│   │   │   ├── environments.py
│   │   │   └── auth.py
│   │   └── websocket.py
│   │
│   ├── models/
│   │   ├── __init__.py
│   │   ├── deployment.py
│   │   ├── application.py
│   │   ├── environment.py
│   │   └── user.py
│   │
│   ├── schemas/
│   │   ├── __init__.py
│   │   ├── deployment.py
│   │   ├── application.py
│   │   └── auth.py
│   │
│   ├── services/
│   │   ├── __init__.py
│   │   ├── ansible_runner.py  # Ansible integration
│   │   ├── deployment.py      # Deployment orchestration
│   │   ├── queue.py           # Redis queue management
│   │   └── vault.py           # Vault integration
│   │
│   └── workers/
│       ├── __init__.py
│       └── deployment_worker.py
│
├── tests/
├── requirements.txt
├── pyproject.toml
└── Dockerfile
```

### Key Service Implementations

#### 1. Ansible Runner Service
```python
class AnsibleRunnerService:
    def __init__(self, ansible_project_root: str):
        self.project_root = ansible_project_root

    async def run_playbook(
        self,
        playbook: str,
        extra_vars: dict,
        inventory: str = "inventory/hosts",
        callback: Optional[Callable] = None
    ) -> dict:
        """Execute Ansible playbook and stream output"""

    async def validate_playbook(self, playbook: str) -> bool:
        """Validate playbook syntax"""

    def get_available_roles(self) -> List[str]:
        """List available Ansible roles"""
```

#### 2. Deployment Service
```python
class DeploymentService:
    async def create_deployment(
        self,
        app_type: str,
        configuration: dict,
        user_id: str
    ) -> Deployment:
        """Create and queue new deployment"""

    async def execute_deployment(self, deployment_id: str):
        """Execute deployment (called by worker)"""

    async def cancel_deployment(self, deployment_id: str):
        """Cancel running deployment"""

    async def get_deployment_logs(
        self,
        deployment_id: str,
        follow: bool = False
    ) -> AsyncGenerator[str, None]:
        """Stream deployment logs"""
```

#### 3. Queue Service (Redis)
```python
class QueueService:
    def __init__(self, redis_url: str):
        self.redis = Redis.from_url(redis_url)
        self.queue = Queue(connection=self.redis)

    def enqueue_deployment(self, deployment_id: str, priority: str = 'normal'):
        """Add deployment to queue"""

    def get_job_status(self, job_id: str) -> dict:
        """Get job execution status"""
```

## Security Considerations

### 1. Authentication & Authorization
- JWT tokens with refresh mechanism
- Role-based access control (admin, deployer, viewer)
- API key support for programmatic access

### 2. Credential Management
- Encrypt sensitive data at rest (Fernet encryption)
- Integration with Ansible Vault for existing secrets
- Optional: HashiCorp Vault integration
- Never log sensitive information

### 3. Input Validation
- Pydantic models for all inputs
- JSON schema validation for configurations
- Sanitize Ansible extra_vars to prevent injection

### 4. Audit Logging
- Log all deployment actions with user context
- Track configuration changes
- Retention policy for logs

### 5. Network Security
- HTTPS only in production
- CORS configuration
- Rate limiting on API endpoints
- WebSocket authentication

## Deployment Strategy

### Development
```bash
# Backend
cd backend
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload

# Frontend
cd frontend
npm install
npm run dev

# Redis
docker run -p 6379:6379 redis:alpine
```

### Production (Docker Compose)
```yaml
version: '3.8'

services:
  backend:
    build: ./backend
    environment:
      - DATABASE_URL=postgresql://user:pass@db:5432/saml_integration
      - REDIS_URL=redis://redis:6379
      - ANSIBLE_PROJECT_ROOT=/ansible
    volumes:
      - ../:/ansible:ro
    depends_on:
      - db
      - redis

  worker:
    build: ./backend
    command: python -m app.workers.deployment_worker
    volumes:
      - ../:/ansible:ro
    depends_on:
      - redis
      - db

  frontend:
    build: ./frontend
    ports:
      - "3000:80"

  db:
    image: postgres:15-alpine
    environment:
      - POSTGRES_DB=saml_integration
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=pass
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
    depends_on:
      - backend
      - frontend

volumes:
  postgres_data:
```

## Feature Roadmap

### Phase 1: MVP (Week 1-2)
- [ ] Basic backend API structure
- [ ] Ansible runner integration
- [ ] Simple frontend with app selection
- [ ] Deploy Jenkins SAML integration
- [ ] Real-time log streaming
- [ ] SQLite database

### Phase 2: Core Features (Week 3-4)
- [ ] Support all apps (Jenkins, SonarQube, Artifactory, Nexus)
- [ ] Deployment history
- [ ] Configuration validation
- [ ] Environment management
- [ ] User authentication
- [ ] PostgreSQL migration

### Phase 3: Enhanced UX (Week 5-6)
- [ ] Configuration templates
- [ ] Clone deployment config
- [ ] Retry failed deployments
- [ ] Deployment scheduling
- [ ] Email notifications
- [ ] Export/import configurations

### Phase 4: Production Ready (Week 7-8)
- [ ] Role-based access control
- [ ] Audit logging
- [ ] API documentation (Swagger)
- [ ] Monitoring and alerting
- [ ] Backup and restore
- [ ] Kubernetes deployment manifests

### Phase 5: Advanced Features (Future)
- [ ] Multi-tenancy support
- [ ] CI/CD pipeline integration
- [ ] Slack/Teams notifications
- [ ] Configuration drift detection
- [ ] Automated rollback
- [ ] GraphQL API
- [ ] Mobile app

## Testing Strategy

### Backend
- Unit tests: pytest + pytest-asyncio
- Integration tests: testcontainers
- API tests: httpx + pytest
- Coverage target: >80%

### Frontend
- Unit tests: Vitest + React Testing Library
- E2E tests: Playwright
- Component tests: Storybook

### Ansible
- Molecule tests for roles
- Integration tests with test inventory

## Monitoring and Observability

### Metrics
- Deployment success/failure rate
- Average deployment duration
- Queue depth
- API response times
- Active WebSocket connections

### Logging
- Structured JSON logs
- Log levels: DEBUG, INFO, WARNING, ERROR
- Separate logs for: API, workers, Ansible output

### Health Checks
- API health endpoint
- Database connectivity
- Redis connectivity
- Ansible availability
- Worker process status

## Documentation Requirements

1. **User Guide**
   - How to deploy each application
   - Configuration options explained
   - Troubleshooting common issues

2. **Developer Guide**
   - How to add new applications
   - API documentation
   - Architecture diagrams

3. **Operations Guide**
   - Installation instructions
   - Configuration management
   - Backup and restore procedures
   - Monitoring setup

## Success Metrics

- Reduce SAML integration time from 30 minutes to 5 minutes
- 95%+ deployment success rate
- Support 10+ concurrent deployments
- API response time < 200ms (p95)
- Zero credential exposure incidents

## Next Steps

1. Review and approve this plan
2. Set up development environment
3. Create initial project scaffolding
4. Implement Phase 1 MVP
5. User testing and feedback
6. Iterate based on feedback
