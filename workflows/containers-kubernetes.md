---
description: Container and Kubernetes workflow for cloud-native deployments
---

# Container & Kubernetes

Build, optimize, and deploy containerized applications with Docker and Kubernetes.

## Overview

Containers provide consistent, portable environments for applications. Kubernetes orchestrates containers at scale with automated deployment, scaling, and management.

## Usage

```powershell
# Build optimized Docker image
.agent\scripts\Manage-Containers.ps1 -Action "build" -ImageName "myapp" -Tag "v1.0.0"

# Scan for vulnerabilities
.agent\scripts\Manage-Containers.ps1 -Action "scan" -ImageName "myapp:v1.0.0"

# Deploy to Kubernetes
.agent\scripts\Manage-Containers.ps1 -Action "deploy" -Environment "staging"

# Scale deployment
.agent\scripts\Manage-Containers.ps1 -Action "scale" -Replicas 5
```

## Docker Best Practices

### Multi-Stage Builds

```dockerfile
# Dockerfile - Multi-stage build for Node.js
FROM node:18-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy source code
COPY . .

# Build application
RUN npm run build

# Production stage
FROM node:18-alpine

WORKDIR /app

# Copy only necessary files from builder
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package*.json ./

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Change ownership
RUN chown -R nodejs:nodejs /app

# Switch to non-root user
USER nodejs

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node healthcheck.js

# Start application
CMD ["node", "dist/index.js"]
```

### Optimized .dockerignore

```
# .dockerignore
node_modules
npm-debug.log
.git
.gitignore
README.md
.env
.env.local
.vscode
.idea
*.md
.DS_Store
coverage
.nyc_output
dist
build
*.log
```

### Security Best Practices

```dockerfile
# Use specific versions, not 'latest'
FROM node:18.17.0-alpine3.18

# Run as non-root user
USER nodejs

# Use read-only root filesystem
RUN chmod -R 555 /app

# Drop capabilities
RUN apk add --no-cache libcap && \
    setcap cap_net_bind_service=+ep /usr/local/bin/node

# Scan for vulnerabilities
# docker scan myapp:latest
```

## Kubernetes Deployment

### Basic Deployment

```yaml
# k8s/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
  namespace: production
  labels:
    app: myapp
    version: v1.0.0
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
        version: v1.0.0
    spec:
      containers:
      - name: myapp
        image: myregistry.azurecr.io/myapp:v1.0.0
        ports:
        - containerPort: 3000
          name: http
        env:
        - name: NODE_ENV
          value: "production"
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: myapp-secrets
              key: db-password
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 5
        securityContext:
          runAsNonRoot: true
          runAsUser: 1001
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
```

### Service

```yaml
# k8s/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: myapp
  namespace: production
spec:
  type: ClusterIP
  selector:
    app: myapp
  ports:
  - port: 80
    targetPort: 3000
    protocol: TCP
    name: http
```

### Ingress

```yaml
# k8s/ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: myapp
  namespace: production
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - myapp.example.com
    secretName: myapp-tls
  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: myapp
            port:
              number: 80
```

### ConfigMap

```yaml
# k8s/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: myapp-config
  namespace: production
data:
  app.conf: |
    server {
      listen 80;
      server_name myapp.example.com;
    }
  LOG_LEVEL: "info"
  API_URL: "https://api.example.com"
```

### Secret

```yaml
# k8s/secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: myapp-secrets
  namespace: production
type: Opaque
data:
  # Base64 encoded values
  db-password: cGFzc3dvcmQxMjM=
  api-key: YXBpa2V5MTIz
```

## Helm Charts

### Chart Structure

```
myapp/
├── Chart.yaml
├── values.yaml
├── values-staging.yaml
├── values-production.yaml
└── templates/
    ├── deployment.yaml
    ├── service.yaml
    ├── ingress.yaml
    ├── configmap.yaml
    └── secret.yaml
```

### Chart.yaml

```yaml
apiVersion: v2
name: myapp
description: My Application Helm Chart
type: application
version: 1.0.0
appVersion: "1.0.0"
```

### values.yaml

```yaml
replicaCount: 3

image:
  repository: myregistry.azurecr.io/myapp
  tag: "v1.0.0"
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  port: 80
  targetPort: 3000

ingress:
  enabled: true
  className: nginx
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
  hosts:
    - host: myapp.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: myapp-tls
      hosts:
        - myapp.example.com

resources:
  requests:
    memory: "128Mi"
    cpu: "100m"
  limits:
    memory: "256Mi"
    cpu: "200m"

autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 10
  targetCPUUtilizationPercentage: 80
  targetMemoryUtilizationPercentage: 80
```

### Deploy with Helm

```powershell
# Install
helm install myapp ./myapp -f values-production.yaml

# Upgrade
helm upgrade myapp ./myapp -f values-production.yaml

# Rollback
helm rollback myapp 1
```

## Auto-Scaling

### Horizontal Pod Autoscaler

```yaml
# k8s/hpa.yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: myapp
  namespace: production
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: myapp
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 80
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

### Vertical Pod Autoscaler

```yaml
# k8s/vpa.yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: myapp
  namespace: production
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: myapp
  updatePolicy:
    updateMode: "Auto"
```

## Monitoring & Logging

### Prometheus Metrics

```yaml
# k8s/servicemonitor.yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: myapp
  namespace: production
spec:
  selector:
    matchLabels:
      app: myapp
  endpoints:
  - port: http
    path: /metrics
    interval: 30s
```

### Logging with Fluentd

```yaml
# k8s/fluentd-configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: fluentd-config
  namespace: kube-system
data:
  fluent.conf: |
    <source>
      @type tail
      path /var/log/containers/*.log
      pos_file /var/log/fluentd-containers.log.pos
      tag kubernetes.*
      format json
    </source>
    
    <match kubernetes.**>
      @type elasticsearch
      host elasticsearch.logging.svc.cluster.local
      port 9200
      logstash_format true
    </match>
```

## Security

### Network Policies

```yaml
# k8s/networkpolicy.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: myapp
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: myapp
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: production
    ports:
    - protocol: TCP
      port: 3000
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          name: production
    ports:
    - protocol: TCP
      port: 5432  # PostgreSQL
```

### Pod Security Policy

```yaml
# k8s/psp.yaml
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  name: restricted
spec:
  privileged: false
  allowPrivilegeEscalation: false
  requiredDropCapabilities:
    - ALL
  volumes:
    - 'configMap'
    - 'emptyDir'
    - 'projected'
    - 'secret'
    - 'downwardAPI'
    - 'persistentVolumeClaim'
  runAsUser:
    rule: 'MustRunAsNonRoot'
  seLinux:
    rule: 'RunAsAny'
  fsGroup:
    rule: 'RunAsAny'
  readOnlyRootFilesystem: true
```

## Deployment Strategies

### Rolling Update

```yaml
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
```

### Blue-Green

```powershell
# Deploy green
kubectl apply -f k8s/deployment-green.yaml

# Test green
kubectl port-forward deployment/myapp-green 8080:3000

# Switch traffic
kubectl patch service myapp -p '{"spec":{"selector":{"version":"green"}}}'

# Remove blue
kubectl delete deployment myapp-blue
```

### Canary

```yaml
# 90% stable, 10% canary
apiVersion: v1
kind: Service
metadata:
  name: myapp
spec:
  selector:
    app: myapp
  # Traffic split handled by service mesh (Istio, Linkerd)
```

## Troubleshooting

```powershell
# View logs
kubectl logs -f deployment/myapp

# Describe pod
kubectl describe pod myapp-xxx

# Execute command in pod
kubectl exec -it myapp-xxx -- /bin/sh

# Port forward
kubectl port-forward deployment/myapp 8080:3000

# Get events
kubectl get events --sort-by='.lastTimestamp'

# Check resource usage
kubectl top pods
kubectl top nodes
```

## Best Practices Checklist

- [ ] Use multi-stage builds
- [ ] Run as non-root user
- [ ] Set resource limits
- [ ] Implement health checks
- [ ] Use secrets for sensitive data
- [ ] Enable auto-scaling
- [ ] Implement network policies
- [ ] Use read-only root filesystem
- [ ] Scan images for vulnerabilities
- [ ] Tag images with versions, not 'latest'
- [ ] Use namespaces for isolation
- [ ] Implement monitoring and logging
- [ ] Test deployments in staging first
- [ ] Have rollback plan ready
