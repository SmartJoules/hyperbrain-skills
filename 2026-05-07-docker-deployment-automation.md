# Docker Deployment Automation - Complete Infrastructure Setup

**Date:** 2026-05-07  
**Project:** JouleTRACK On-Premise Deployment  
**Category:** DevOps/Infrastructure/Automation

## 🎯 Learning Summary

Successfully developed and implemented a complete Docker-based deployment automation system for JouleTRACK on-premise infrastructure. This system handles full-stack deployment including dependencies, services, monitoring, and configuration management.

## 🔧 Technical Achievements

### 1. **Infrastructure Automation**
- Deployed 5 core services via Docker Compose:
  - Redis (caching, sessions)
  - Apache Kafka (message streaming)
  - PostgreSQL (primary database)
  - InfluxDB (time-series data)
  - MongoDB (NoSQL storage)

### 2. **Service Deployment**
- Successfully deployed cloud-to-onprem-config-sync service with:
  - Two separate containers (consumer + cron job)
  - Host networking configuration for Kafka connectivity
  - AWS credentials integration
  - Environment variable management

### 3. **Key Problem Solutions**

#### **Issue:** Kafka Connection Timeout
**Problem:** Docker containers couldn't connect to Kafka running on host
**Solution:** Used `network_mode: host` in docker-compose.yml to bypass Docker networking
**Learning:** Docker container networking vs host networking for local service access

#### **Issue:** AWS Credentials Management
**Problem:** Need secure AWS credential passing to containers
**Solution:** 
- Global AWS credential setup (~/.aws/credentials)
- Environment variable passing
- Volume mounting of AWS credentials directory
**Learning:** Multiple approaches to credential management in containerized environments

#### **Issue:** Package Lock File Missing
**Problem:** Docker build failed - no package-lock.json for `npm ci`
**Solution:** Generated package-lock.json via `npm install` before building
**Learning:** Difference between `npm install` and `npm ci`, build optimization

## 📚 Key Learnings

### Docker Compose Patterns
```yaml
# Host networking for local service access
network_mode: host

# Volume mounting for credentials
volumes:
  - ~/.aws:/root/.aws:ro

# Environment variable passing
environment:
  - AWS_ACCESS_KEY_ID
  - AWS_SECRET_ACCESS_KEY
```

### Docker Networking Understanding
- **Bridge Network:** Default, containers isolated, need port mapping
- **Host Network:** Containers share host network stack, no isolation
- **When to use:** Local development, accessing services on host machine

### Service Discovery in Docker
- `localhost` in host networking = actual host machine
- `host.docker.internal` in bridge networking = host machine
- Service names work within same Docker network

## 🛠️ Automation Script Development

Created comprehensive bash automation script (`deploy-all.sh`) with:
- Command-line argument parsing
- Dependency detection and installation
- Repository cloning and management
- Docker service orchestration
- Health monitoring setup
- Error handling and colored output

## 📊 Deployment Architecture

```
┌─────────────────────────────────────────────────────┐
│          On-Premise Infrastructure                   │
├─────────────────────────────────────────────────────┤
│  Docker Services:                                  │
│  ├─ Redis (6379)                                   │
│  ├─ Kafka (9092) + Zookeeper (2181)                │
│  ├─ PostgreSQL (5432)                              │
│  ├─ InfluxDB (8086)                                │
│  └─ MongoDB (27017)                                │
├─────────────────────────────────────────────────────┤
│  Application Services:                             │
│  ├─ cloud-sqs-sync-consumer (7001)                 │
│  ├─ sqs-cron-job (scheduled tasks)                 │
│  ├─ JouleTrack-API (1337)                          │
│  └─ jt-api-v2 (1338)                               │
├─────────────────────────────────────────────────────┤
│  Monitoring:                                       │
│  └─ joule-monitor.sh (health checks)               │
└─────────────────────────────────────────────────────┘
```

## 🚀 Deployment Process Flow

1. **Setup Phase:**
   - Parse AWS credentials from command-line args
   - Install dependencies (Docker, Node.js, PM2)
   - Clone/update repositories

2. **Infrastructure Phase:**
   - Generate secure passwords
   - Start core services via Docker Compose
   - Wait for health checks

3. **Application Phase:**
   - Build Docker images
   - Deploy services with proper configuration
   - Setup PM2 for API services

4. **Finalization Phase:**
   - Run site-onboarding service
   - Setup monitoring cron jobs
   - Generate deployment report

## 🔐 Security Considerations

- **Credential Management:** Environment variables + volume mounts
- **Password Generation:** OpenSSL for secure random passwords
- **Network Security:** Host networking only for trusted local services
- **Access Control:** Proper file permissions for credential files

## 📈 Performance Optimizations

- **Docker Multi-stage Builds:** Separate build and runtime environments
- **Alpine Images:** Minimal base images for smaller footprint
- **Resource Limits:** Memory limits for containers
- **Health Checks:** Automatic service monitoring and restart

## 🎓 Resources & References

### Docker Commands Used
```bash
# Build and start services
docker compose up -d --build

# View logs
docker compose logs -f [service]

# Execute in container
docker exec -it [container] sh

# Clean up
docker compose down -v
```

### Useful Tools
- **Docker Compose V2:** `docker compose` (not `docker-compose`)
- **Expect:** For automating interactive SSH commands
- **PM2:** Node.js process manager for API services

## 💡 Best Practices Learned

1. **Always use specific versions** for Docker images (not `latest`)
2. **Generate package-lock.json** before Docker builds
3. **Use host networking** for local service access
4. **Secure credentials** via environment variables, not in files
5. **Health checks** essential for container orchestration
6. **Volume mounting** better than copying for credentials
7. **Monitoring** should be set up during deployment, not after

## 🔄 Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| Kafka connection timeout | Use `network_mode: host` |
| npm ci fails | Generate package-lock.json first |
| AWS credentials missing | Mount ~/.aws volume |
| Container restart loops | Check logs, verify env variables |
| Port conflicts | Use `docker compose ps` to check |

## 📝 Future Improvements

1. **Kubernetes Migration:** For better orchestration
2. **Service Mesh:** Istio for service-to-service communication
3. **Secrets Management:** HashiCorp Vault integration
4. **CI/CD Pipeline:** GitHub Actions for automated deployments
5. **Monitoring Stack:** Prometheus + Grafana + AlertManager
6. **Backup Automation:** Automated database backups

## 🎯 Impact & Results

- **Deployment Time:** Reduced from manual hours to automated minutes
- **Reliability:** Health monitoring prevents service failures
- **Scalability:** Easy to add new services and environments
- **Security:** Centralized credential management
- **Maintainability:** Single script handles entire infrastructure

---

**Tags:** `#docker` `#devops` `#automation` `#infrastructure` `#deployment` `#kafka` `#aws` `#bash-scripting` `#docker-compose` `#microservices`