# Manage-Containers.ps1
# Container and Kubernetes management automation

param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("build", "scan", "push", "deploy", "scale", "rollback", "logs")]
    [string]$Action,
    
    [string]$ImageName,
    [string]$Tag = "latest",
    [string]$Registry,
    [ValidateSet("dev", "staging", "production")]
    [string]$Environment = "dev",
    [int]$Replicas = 3,
    [string]$Namespace = "default",
    [switch]$MultiStage
)

$ErrorActionPreference = "Stop"

Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║          CONTAINER & KUBERNETES MANAGER                       ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

Write-Host "`n🐳 Action: $Action | Environment: $Environment`n" -ForegroundColor Yellow

# ---------------------------------------------------------
# Build Docker Image
# ---------------------------------------------------------

if ($Action -eq "build") {
    if (-not $ImageName) {
        Write-Host "  ❌ ImageName is required" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "🔨 Building Docker image: $ImageName:$Tag`n" -ForegroundColor Cyan
    
    # Check if Dockerfile exists
    if (-not (Test-Path "Dockerfile")) {
        Write-Host "  ❌ Dockerfile not found" -ForegroundColor Red
        
        if ($MultiStage) {
            Write-Host "`n  💡 Creating multi-stage Dockerfile..." -ForegroundColor Yellow
            
            $dockerfile = @"
# Multi-stage build
FROM node:18-alpine AS builder

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .
RUN npm run build

# Production stage
FROM node:18-alpine

WORKDIR /app

COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package*.json ./

RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001 && \
    chown -R nodejs:nodejs /app

USER nodejs

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node healthcheck.js || exit 1

CMD ["node", "dist/index.js"]
"@
            
            $dockerfile | Set-Content "Dockerfile"
            Write-Host "  ✅ Created Dockerfile" -ForegroundColor Green
        }
        else {
            exit 1
        }
    }
    
    # Build image
    Write-Host "  Building image..." -ForegroundColor Gray
    docker build -t "${ImageName}:${Tag}" .
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`n  ✅ Image built successfully" -ForegroundColor Green
        
        # Show image size
        $imageInfo = docker images "${ImageName}:${Tag}" --format "{{.Size}}"
        Write-Host "  📦 Image size: $imageInfo" -ForegroundColor Cyan
    }
    else {
        Write-Host "`n  ❌ Build failed" -ForegroundColor Red
        exit 1
    }
}

# ---------------------------------------------------------
# Scan Image for Vulnerabilities
# ---------------------------------------------------------

if ($Action -eq "scan") {
    if (-not $ImageName) {
        Write-Host "  ❌ ImageName is required" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "🔍 Scanning image for vulnerabilities: $ImageName:$Tag`n" -ForegroundColor Cyan
    
    # Check if Trivy is installed
    try {
        $trivyVersion = trivy --version 2>$null
        
        if ($trivyVersion) {
            Write-Host "  Running Trivy scan..." -ForegroundColor Gray
            trivy image --severity HIGH, CRITICAL "${ImageName}:${Tag}"
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "`n  ✅ Scan complete" -ForegroundColor Green
            }
        }
        else {
            Write-Host "  ⚠️  Trivy not installed" -ForegroundColor Yellow
            Write-Host "  💡 Install: https://aquasecurity.github.io/trivy/" -ForegroundColor Cyan
        }
    }
    catch {
        Write-Host "  ⚠️  Trivy not available" -ForegroundColor Yellow
    }
}

# ---------------------------------------------------------
# Push Image to Registry
# ---------------------------------------------------------

if ($Action -eq "push") {
    if (-not $ImageName -or -not $Registry) {
        Write-Host "  ❌ ImageName and Registry are required" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "📤 Pushing image to registry...`n" -ForegroundColor Cyan
    
    $fullImageName = "${Registry}/${ImageName}:${Tag}"
    
    # Tag image
    docker tag "${ImageName}:${Tag}" $fullImageName
    
    # Push image
    docker push $fullImageName
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`n  ✅ Image pushed successfully" -ForegroundColor Green
        Write-Host "  📦 $fullImageName" -ForegroundColor Cyan
    }
    else {
        Write-Host "`n  ❌ Push failed" -ForegroundColor Red
        exit 1
    }
}

# ---------------------------------------------------------
# Deploy to Kubernetes
# ---------------------------------------------------------

if ($Action -eq "deploy") {
    Write-Host "🚀 Deploying to Kubernetes ($Environment)...`n" -ForegroundColor Cyan
    
    # Check if kubectl is available
    try {
        $kubectlVersion = kubectl version --client --short 2>$null
        
        if (-not $kubectlVersion) {
            Write-Host "  ❌ kubectl not installed" -ForegroundColor Red
            Write-Host "  💡 Install: https://kubernetes.io/docs/tasks/tools/" -ForegroundColor Yellow
            exit 1
        }
    }
    catch {
        Write-Host "  ❌ kubectl not available" -ForegroundColor Red
        exit 1
    }
    
    # Check for k8s manifests
    $k8sDir = "k8s/$Environment"
    
    if (-not (Test-Path $k8sDir)) {
        Write-Host "  ⚠️  No manifests found in $k8sDir" -ForegroundColor Yellow
        Write-Host "  💡 Creating basic deployment..." -ForegroundColor Cyan
        
        New-Item -ItemType Directory -Path $k8sDir -Force | Out-Null
        
        # Create basic deployment
        $deployment = @"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $ImageName
  namespace: $Namespace
spec:
  replicas: $Replicas
  selector:
    matchLabels:
      app: $ImageName
  template:
    metadata:
      labels:
        app: $ImageName
    spec:
      containers:
      - name: $ImageName
        image: ${ImageName}:${Tag}
        ports:
        - containerPort: 3000
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
"@
        
        $deployment | Set-Content "$k8sDir/deployment.yaml"
        Write-Host "  ✅ Created $k8sDir/deployment.yaml" -ForegroundColor Green
    }
    
    # Apply manifests
    Write-Host "  Applying manifests..." -ForegroundColor Gray
    kubectl apply -f $k8sDir/ --namespace=$Namespace
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`n  ✅ Deployment successful" -ForegroundColor Green
        
        # Wait for rollout
        Write-Host "`n  ⏳ Waiting for rollout..." -ForegroundColor Cyan
        kubectl rollout status deployment/$ImageName --namespace=$Namespace
    }
    else {
        Write-Host "`n  ❌ Deployment failed" -ForegroundColor Red
        exit 1
    }
}

# ---------------------------------------------------------
# Scale Deployment
# ---------------------------------------------------------

if ($Action -eq "scale") {
    if (-not $ImageName) {
        Write-Host "  ❌ ImageName is required" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "📊 Scaling deployment to $Replicas replicas...`n" -ForegroundColor Cyan
    
    kubectl scale deployment/$ImageName --replicas=$Replicas --namespace=$Namespace
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✅ Scaled successfully" -ForegroundColor Green
    }
    else {
        Write-Host "  ❌ Scaling failed" -ForegroundColor Red
        exit 1
    }
}

# ---------------------------------------------------------
# Rollback Deployment
# ---------------------------------------------------------

if ($Action -eq "rollback") {
    if (-not $ImageName) {
        Write-Host "  ❌ ImageName is required" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "⏮️  Rolling back deployment...`n" -ForegroundColor Yellow
    
    kubectl rollout undo deployment/$ImageName --namespace=$Namespace
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✅ Rollback successful" -ForegroundColor Green
        
        # Wait for rollout
        kubectl rollout status deployment/$ImageName --namespace=$Namespace
    }
    else {
        Write-Host "  ❌ Rollback failed" -ForegroundColor Red
        exit 1
    }
}

# ---------------------------------------------------------
# View Logs
# ---------------------------------------------------------

if ($Action -eq "logs") {
    if (-not $ImageName) {
        Write-Host "  ❌ ImageName is required" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "📋 Viewing logs for $ImageName...`n" -ForegroundColor Cyan
    
    kubectl logs -f deployment/$ImageName --namespace=$Namespace --tail=100
}

Write-Host ""
