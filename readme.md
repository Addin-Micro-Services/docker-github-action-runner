# GitHub Actions Self-Hosted Runners - Docker Setup

![GitHub Actions](https://img.shields.io/badge/GitHub%20Actions-2088FF?style=for-the-badge&logo=github-actions&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![Ubuntu](https://img.shields.io/badge/Ubuntu-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)

A flexible, production-ready setup for running GitHub Actions self-hosted runners in Docker containers with organization-level access across multiple repositories.

## 🚀 Quick Start

### Prerequisites

- Docker & Docker Compose installed
- GitHub organization admin access
- Linux/macOS host system
- Minimum: 6GB RAM, 4 CPU cores

### 1. Clone or Create Project

```bash
mkdir github-org-runners
cd github-org-runners
```

### 2. Create Required Files

Save these files in your project directory:

- [`Dockerfile`](#dockerfile)
- [`entrypoint.sh`](#entrypoint-script) (make executable)
- [`docker-compose.yml`](#docker-compose)
- [`manage-runners.sh`](#management-script) (make executable)
- [`.gitignore`](#gitignore)

```bash
# Make scripts executable
chmod +x entrypoint.sh manage-runners.sh
```

### 3. Configuration Setup

```bash
# Create environment configuration
./manage-runners.sh create-env

# Edit with your settings
nano .env
```

Configure your `.env` file:

```bash
# Required: Get from https://github.com/YOUR-ORG/settings/actions/runners
GITHUB_ORG_TOKEN=ghp_your_actual_token_here
GITHUB_URL=https://github.com/YOUR-ORG

# Optional: Customize as needed
RUNNER_LABELS=docker,self-hosted,linux,org,production
MEMORY_LIMIT=2G
CPU_LIMIT=2.0
RUNNER_VERSION=2.326.0
RUNNER_HASH=9c74af9b4352bbc99aecc7353b47bcdfcd1b2a0f6d15af54a99f54a0c14a1de8
```

### 4. Start Runners

```bash
# Option 1: Start default runners (1 & 2)
docker-compose up -d

# Option 2: Start all runners (1, 2, 3, 4)
docker-compose --profile extra up -d

# Option 3: Start specific runners
docker-compose up -d github-runner-1 github-runner-3
```

### 5. Verify Setup

```bash
# Check runner status
./manage-runners.sh monitor

# View logs
docker-compose logs -f github-runner-1
```

## 📋 Configuration Reference

### Environment Variables (.env)

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `GITHUB_ORG_TOKEN` | ✅ | - | Organization runner token |
| `GITHUB_URL` | ✅ | - | GitHub organization URL |
| `RUNNER_LABELS` | ❌ | `docker,self-hosted,linux,org` | Runner labels (comma-separated) |
| `MEMORY_LIMIT` | ❌ | `2G` | Memory limit per runner |
| `CPU_LIMIT` | ❌ | `2.0` | CPU cores per runner |
| `RUNNER_VERSION` | ❌ | `2.326.0` | GitHub runner version |
| `RUNNER_HASH` | ❌ | Latest hash | SHA256 hash for verification |
| `DOCKER_GID` | ❌ | Auto-detected | Docker group ID |

### Getting Your GitHub Token

1. Go to your organization: `https://github.com/YOUR-ORG/settings/actions/runners`
2. Click **"New self-hosted runner"**
3. Copy the token from the configuration command
4. Add to your `.env` file

## 🎯 Runner Management

### Available Runners

| Runner | Container Name | Labels | Purpose |
|--------|----------------|--------|---------|
| Runner 1 | `github-runner-1` | `primary` | Primary runner (default) |
| Runner 2 | `github-runner-2` | `secondary` | Secondary runner (default) |
| Runner 3 | `github-runner-3` | `additional` | Extra runner (profile: extra) |
| Runner 4 | `github-runner-4` | `additional` | Extra runner (profile: extra) |

### Management Commands

```bash
# Start/Stop
./manage-runners.sh up                    # Start default (1 & 2)
./manage-runners.sh up github-runner-1    # Start specific runner
./manage-runners.sh up-extra              # Start all 4 runners
./manage-runners.sh down                  # Stop all runners

# Monitoring
./manage-runners.sh monitor               # Status & resource usage
./manage-runners.sh logs 1                # View runner 1 logs
./manage-runners.sh logs                  # View all logs

# Maintenance
./manage-runners.sh restart 2             # Restart runner 2
./manage-runners.sh build                 # Rebuild images
./manage-runners.sh cleanup               # Clean up everything
```

### Direct Docker Compose

```bash
# Start specific combinations
docker-compose up -d github-runner-1 github-runner-2
docker-compose up -d github-runner-1 github-runner-3 github-runner-4

# Check status
docker-compose ps

# View logs
docker-compose logs -f github-runner-1

# Stop runners
docker-compose down
```

## 🔧 Workflow Integration

### Basic Usage

```yaml
# .github/workflows/build.yml
name: Build and Test

on: [push, pull_request]

jobs:
  build:
    runs-on: [self-hosted, docker, linux, org]
    steps:
      - uses: actions/checkout@v4
      
      - name: Build Docker image
        run: docker build -t myapp .
        
      - name: Run tests
        run: docker run --rm myapp npm test
```

### Targeting Specific Runners

```yaml
jobs:
  primary-build:
    runs-on: [self-hosted, primary]    # Targets github-runner-1
    
  secondary-build:
    runs-on: [self-hosted, secondary]  # Targets github-runner-2
    
  parallel-tests:
    runs-on: [self-hosted, additional] # Targets github-runner-3 or 4
```

### Custom Labels

```bash
# In .env file
RUNNER_LABELS=docker,self-hosted,linux,production,x86_64,gpu
```

```yaml
jobs:
  gpu-training:
    runs-on: [self-hosted, gpu]
    
  production-deploy:
    runs-on: [self-hosted, production]
```

## 📊 Scaling Strategies

### Scenario-Based Scaling

| Use Case | Recommended Setup | Command |
|----------|------------------|---------|
| **Single Team** | 1 runner | `docker-compose up -d github-runner-1` |
| **Small Organization** | 2 runners (default) | `docker-compose up -d` |
| **High Activity** | 4 runners | `docker-compose --profile extra up -d` |
| **Mixed Workloads** | Custom selection | `docker-compose up -d github-runner-1 github-runner-3` |

### Resource Planning

| Runners | Host CPU | Host RAM | Use Case |
|---------|----------|----------|----------|
| 1 runner | 4+ cores | 6+ GB | Light usage, small team |
| 2 runners | 6+ cores | 8+ GB | Standard usage (recommended) |
| 4 runners | 10+ cores | 12+ GB | High throughput, large organization |

### Custom Resource Limits

```bash
# Light setup
MEMORY_LIMIT=1G
CPU_LIMIT=1.0

# Standard setup (recommended)
MEMORY_LIMIT=2G
CPU_LIMIT=2.0

# Heavy workloads
MEMORY_LIMIT=4G
CPU_LIMIT=3.0
```

## 🐳 Docker Features

### Docker-on-Host Capabilities

Your workflows can use Docker commands directly:

```yaml
steps:
  - name: Build and push
    run: |
      docker build -t myapp:${{ github.sha }} .
      docker push myapp:${{ github.sha }}
      
  - name: Docker Compose services
    run: |
      docker-compose up -d database
      docker-compose run --rm app npm test
      docker-compose down
      
  - name: Multi-stage builds
    run: |
      docker build --target production -t myapp:prod .
      docker build --target test -t myapp:test .
```

### Image Cleanup

Docker images are automatically managed, but you can add explicit cleanup:

```yaml
steps:
  - name: Cleanup old images
    run: docker image prune -f --filter "until=24h"
```

## 🔒 Security Best Practices

### Repository Access

- ✅ **Use with private repositories only**
- ✅ **Organization-level runners for centralized control**
- ✅ **Token stored securely in .env (not in git)**
- ✅ **Regular token rotation**

### Runner Security

```bash
# Recommended: Use runner groups for access control
# GitHub Organization > Settings > Actions > Runner groups
```

### Network Security

```yaml
# Optional: Restrict network access in docker-compose.yml
networks:
  runner-network:
    driver: bridge
    driver_opts:
      com.docker.network.bridge.enable_icc: "false"
```

## 🛠️ Troubleshooting

### Common Issues

#### Runner Not Appearing in GitHub

```bash
# Check configuration
cat .env

# Verify logs
./manage-runners.sh logs 1

# Check token validity
curl -H "Authorization: token $GITHUB_ORG_TOKEN" \
     https://api.github.com/user
```

#### Docker Permission Issues

```bash
# Check Docker group
groups $USER

# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker

# Verify Docker access
docker ps
```

#### Resource Exhaustion

```bash
# Check current usage
./manage-runners.sh monitor

# Reduce resource limits
# Edit .env:
MEMORY_LIMIT=1G
CPU_LIMIT=1.0

# Restart with new limits
docker-compose down && docker-compose up -d
```

#### Hash Validation Errors

```bash
# Skip hash validation
# In .env:
RUNNER_HASH=

# Or update to latest version
RUNNER_VERSION=2.327.0
RUNNER_HASH=new_hash_for_2.327.0
```

### Log Analysis

```bash
# Runner-specific logs
docker-compose logs github-runner-1

# All logs with timestamps
docker-compose logs -t

# Follow logs in real-time
docker-compose logs -f

# Last 50 lines
docker-compose logs --tail=50
```

### Performance Monitoring

```bash
# Resource usage
docker stats

# Detailed runner status
./manage-runners.sh monitor

# System resources
htop
df -h
```

## 🔄 Maintenance

### Updating Runner Version

1. **Check for new releases**: https://github.com/actions/runner/releases
2. **Update .env**:
   ```bash
   RUNNER_VERSION=2.327.0
   RUNNER_HASH=new_sha256_hash
   ```
3. **Rebuild and restart**:
   ```bash
   docker-compose down
   docker-compose build --no-cache
   docker-compose up -d
   ```

### Regular Maintenance

```bash
# Weekly cleanup
./manage-runners.sh cleanup

# Update base images
docker-compose pull
docker-compose build --no-cache

# Check for security updates
docker scout quickview
```

### Backup Configuration

```bash
# Backup configuration (exclude secrets)
tar -czf runner-backup.tar.gz \
    Dockerfile entrypoint.sh docker-compose.yml manage-runners.sh \
    --exclude=.env
```

## 📚 Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Self-hosted Runner Documentation](https://docs.github.com/en/actions/hosting-your-own-runners)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [GitHub Runner Releases](https://github.com/actions/runner/releases)

## 📝 License

This setup is provided as-is for educational and production use. Ensure compliance with your organization's security policies and GitHub's terms of service.

---

**Need help?** Open an issue or check the troubleshooting section above.