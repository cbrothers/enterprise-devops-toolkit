# Container & Kubernetes - Quick Reference

## 🐳 Docker Commands

### Build Image
```powershell
# Basic build
.agent\scripts\Manage-Containers.ps1 -Action "build" -ImageName "myapp" -Tag "v1.0.0"

# Multi-stage build
.agent\scripts\Manage-Containers.ps1 -Action "build" -ImageName "myapp" -Tag "v1.0.0" -MultiStage
```

### Scan for Vulnerabilities
```powershell
.agent\scripts\Manage-Containers.ps1 -Action "scan" -ImageName "myapp" -Tag "v1.0.0"
```

### Push to Registry
```powershell
.agent\scripts\Manage-Containers.ps1 -Action "push" `
    -ImageName "myapp" `
    -Tag "v1.0.0" `
    -Registry "myregistry.azurecr.io"
```

## ☸️ Kubernetes Commands

### Deploy
```powershell
# Deploy to staging
.agent\scripts\Manage-Containers.ps1 -Action "deploy" -Environment "staging"

# Deploy to production
.agent\scripts\Manage-Containers.ps1 -Action "deploy" -Environment "production"
```

### Scale
```powershell
.agent\scripts\Manage-Containers.ps1 -Action "scale" `
    -ImageName "myapp" `
    -Replicas 5
```

### Rollback
```powershell
.agent\scripts\Manage-Containers.ps1 -Action "rollback" -ImageName "myapp"
```

### View Logs
```powershell
.agent\scripts\Manage-Containers.ps1 -Action "logs" -ImageName "myapp"
```

## 📦 Helm Commands

```powershell
# Install chart
helm install myapp ./kubernetes/helm/myapp -f values-production.yaml

# Upgrade
helm upgrade myapp ./kubernetes/helm/myapp -f values-production.yaml

# Rollback
helm rollback myapp 1

# List releases
helm list

# Uninstall
helm uninstall myapp
```

## 🔧 Common kubectl Commands

```powershell
# Get resources
kubectl get pods
kubectl get deployments
kubectl get services

# Describe resource
kubectl describe pod myapp-xxx

# View logs
kubectl logs -f deployment/myapp

# Execute command
kubectl exec -it myapp-xxx -- /bin/sh

# Port forward
kubectl port-forward deployment/myapp 8080:3000

# Scale
kubectl scale deployment/myapp --replicas=5

# Rollout status
kubectl rollout status deployment/myapp

# Rollout history
kubectl rollout history deployment/myapp

# Rollback
kubectl rollout undo deployment/myapp
```

## 📋 Available Templates

### Kubernetes Manifests
- `kubernetes/manifests/production.yaml` - Complete production setup
- Includes: Deployment, Service, Ingress, HPA, NetworkPolicy, PDB

### Helm Charts
- `kubernetes/helm/myapp/` - Full Helm chart
- Customizable via `values.yaml`

## 🔒 Security Checklist

- [ ] Use multi-stage builds
- [ ] Run as non-root user (UID 1001)
- [ ] Set resource limits
- [ ] Implement health checks
- [ ] Use read-only root filesystem
- [ ] Drop all capabilities
- [ ] Scan images with Trivy
- [ ] Use specific image tags (not 'latest')
- [ ] Enable network policies
- [ ] Set pod disruption budgets

## 📊 Monitoring

### Prometheus Metrics
- Exposed on `/metrics` endpoint
- Scraped automatically with annotations

### Logging
- Logs sent to stdout/stderr
- Collected by Fluentd/Fluent Bit
- Aggregated in Elasticsearch/Loki

## 📚 Learn More

- [Container & Kubernetes Workflow](../workflows/containers-kubernetes.md)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Helm Documentation](https://helm.sh/docs/)
