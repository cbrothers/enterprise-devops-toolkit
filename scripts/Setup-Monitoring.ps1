# Setup-Monitoring.ps1
# Monitoring and observability configuration advisor

param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("analyze", "recommend", "configure", "alerts", "dashboard")]
    [string]$Action,
    
    [ValidateSet("prometheus", "datadog", "newrelic", "cloudwatch", "elk")]
    [string]$Stack,
    
    [ValidateSet("small", "medium", "large")]
    [string]$Scale = "medium",
    
    [string]$OutputDir = "monitoring"
)

$ErrorActionPreference = "Continue"

Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║          MONITORING & OBSERVABILITY ADVISOR                   ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

# Ensure output directory exists
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

# ---------------------------------------------------------
# Analyze Current Monitoring
# ---------------------------------------------------------

if ($Action -eq "analyze") {
    Write-Host "`n🔍 Analyzing current monitoring setup...`n" -ForegroundColor Cyan
    
    $findings = @{
        Metrics = @()
        Logs    = @()
        Traces  = @()
        Gaps    = @()
    }
    
    # Check for common monitoring tools
    Write-Host "  Checking for monitoring tools:" -ForegroundColor Yellow
    
    # Prometheus
    try {
        $promResponse = Invoke-WebRequest -Uri "http://localhost:9090" -Method Head -TimeoutSec 2 -ErrorAction SilentlyContinue
        if ($promResponse) {
            Write-Host "    ✅ Prometheus detected (port 9090)" -ForegroundColor Green
            $findings.Metrics += "Prometheus"
        }
    }
    catch {}
    
    # Grafana
    try {
        $grafanaResponse = Invoke-WebRequest -Uri "http://localhost:3000" -Method Head -TimeoutSec 2 -ErrorAction SilentlyContinue
        if ($grafanaResponse) {
            Write-Host "    ✅ Grafana detected (port 3000)" -ForegroundColor Green
            $findings.Metrics += "Grafana"
        }
    }
    catch {}
    
    # Elasticsearch
    try {
        $esResponse = Invoke-WebRequest -Uri "http://localhost:9200" -Method Head -TimeoutSec 2 -ErrorAction SilentlyContinue
        if ($esResponse) {
            Write-Host "    ✅ Elasticsearch detected (port 9200)" -ForegroundColor Green
            $findings.Logs += "Elasticsearch"
        }
    }
    catch {}
    
    if ($findings.Metrics.Count -eq 0 -and $findings.Logs.Count -eq 0) {
        Write-Host "    ⚠️  No monitoring tools detected" -ForegroundColor Yellow
        $findings.Gaps += "No monitoring infrastructure found"
    }
    
    # Check for log files
    Write-Host "`n  Checking for application logs:" -ForegroundColor Yellow
    $logFiles = Get-ChildItem -Path "." -Recurse -Include "*.log" -File -ErrorAction SilentlyContinue | Select-Object -First 5
    if ($logFiles) {
        Write-Host "    ✅ Found $($logFiles.Count) log file(s)" -ForegroundColor Green
        foreach ($log in $logFiles) {
            Write-Host "       - $($log.Name)" -ForegroundColor Gray
        }
    }
    else {
        Write-Host "    ⚠️  No log files found" -ForegroundColor Yellow
        $findings.Gaps += "No application logging detected"
    }
    
    # Summary
    Write-Host "`n📋 Analysis Summary:" -ForegroundColor Cyan
    if ($findings.Gaps.Count -gt 0) {
        Write-Host "`n  Gaps identified:" -ForegroundColor Yellow
        $findings.Gaps | ForEach-Object { Write-Host "    - $_" -ForegroundColor Yellow }
        Write-Host "`n  💡 Run with -Action 'recommend' for suggestions" -ForegroundColor Cyan
    }
    else {
        Write-Host "  ✅ Basic monitoring infrastructure detected" -ForegroundColor Green
    }
}

# ---------------------------------------------------------
# Recommend Monitoring Stack
# ---------------------------------------------------------

if ($Action -eq "recommend") {
    Write-Host "`n🎯 Monitoring Stack Recommendations`n" -ForegroundColor Cyan
    
    Write-Host "  Scale: $Scale`n" -ForegroundColor Gray
    
    switch ($Scale) {
        "small" {
            Write-Host "  Recommended Stack (Small Team/Startup):" -ForegroundColor Yellow
            Write-Host "    📊 Metrics: Prometheus + Grafana" -ForegroundColor Green
            Write-Host "       - Free and open source" -ForegroundColor Gray
            Write-Host "       - Easy to set up" -ForegroundColor Gray
            Write-Host "       - Great community support" -ForegroundColor Gray
            
            Write-Host "`n    📝 Logs: Loki + Grafana" -ForegroundColor Green
            Write-Host "       - Integrates with Grafana" -ForegroundColor Gray
            Write-Host "       - Low resource usage" -ForegroundColor Gray
            Write-Host "       - Simple query language" -ForegroundColor Gray
            
            Write-Host "`n    🔍 Traces: Jaeger (optional)" -ForegroundColor Green
            Write-Host "       - Only if needed for microservices" -ForegroundColor Gray
            
            Write-Host "`n    💰 Estimated Cost: $0-100/month (infrastructure only)" -ForegroundColor Cyan
        }
        
        "medium" {
            Write-Host "  Recommended Stack (Medium Business):" -ForegroundColor Yellow
            Write-Host "    📊 Metrics: DataDog or New Relic" -ForegroundColor Green
            Write-Host "       - Managed service (less ops overhead)" -ForegroundColor Gray
            Write-Host "       - Excellent integrations" -ForegroundColor Gray
            Write-Host "       - Built-in alerting" -ForegroundColor Gray
            
            Write-Host "`n    📝 Logs: DataDog Logs or Splunk Cloud" -ForegroundColor Green
            Write-Host "       - Integrated with metrics" -ForegroundColor Gray
            Write-Host "       - Powerful search" -ForegroundColor Gray
            Write-Host "       - Compliance features" -ForegroundColor Gray
            
            Write-Host "`n    🔍 Traces: DataDog APM" -ForegroundColor Green
            Write-Host "       - Full observability in one platform" -ForegroundColor Gray
            
            Write-Host "`n    💰 Estimated Cost: $500-2000/month" -ForegroundColor Cyan
        }
        
        "large" {
            Write-Host "  Recommended Stack (Enterprise):" -ForegroundColor Yellow
            Write-Host "    📊 Metrics: Prometheus + Thanos" -ForegroundColor Green
            Write-Host "       - Multi-cluster support" -ForegroundColor Gray
            Write-Host "       - Long-term storage" -ForegroundColor Gray
            Write-Host "       - High availability" -ForegroundColor Gray
            
            Write-Host "`n    📝 Logs: ELK Stack or Splunk Enterprise" -ForegroundColor Green
            Write-Host "       - Massive scale" -ForegroundColor Gray
            Write-Host "       - Advanced analytics" -ForegroundColor Gray
            Write-Host "       - Compliance ready" -ForegroundColor Gray
            
            Write-Host "`n    🔍 Traces: Jaeger or custom solution" -ForegroundColor Green
            Write-Host "       - Distributed tracing at scale" -ForegroundColor Gray
            
            Write-Host "`n    💰 Estimated Cost: $5000+/month" -ForegroundColor Cyan
        }
    }
}

# ---------------------------------------------------------
# Generate Configuration
# ---------------------------------------------------------

if ($Action -eq "configure" -and $Stack) {
    Write-Host "`n⚙️  Generating $Stack configuration...`n" -ForegroundColor Cyan
    
    switch ($Stack) {
        "prometheus" {
            $prometheusConfig = @"
# Prometheus Configuration
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  # Application metrics
  - job_name: 'application'
    static_configs:
      - targets: ['localhost:9090']
    
  # Node exporter (system metrics)
  - job_name: 'node'
    static_configs:
      - targets: ['localhost:9100']

# Alerting configuration
alerting:
  alertmanagers:
    - static_configs:
        - targets: ['localhost:9093']

# Alert rules
rule_files:
  - 'alerts.yml'
"@
            
            $configPath = Join-Path $OutputDir "prometheus.yml"
            $prometheusConfig | Set-Content $configPath
            Write-Host "  ✅ Created $configPath" -ForegroundColor Green
            
            # Alert rules
            $alertRules = @"
groups:
  - name: application_alerts
    interval: 30s
    rules:
      - alert: HighErrorRate
        expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.05
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "High error rate detected"
          description: "Error rate is {{ `$value }} errors/sec"
          
      - alert: HighLatency
        expr: histogram_quantile(0.95, http_request_duration_seconds_bucket) > 2
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "High latency detected"
          description: "P95 latency is {{ `$value }}s"
"@
            
            $alertsPath = Join-Path $OutputDir "alerts.yml"
            $alertRules | Set-Content $alertsPath
            Write-Host "  ✅ Created $alertsPath" -ForegroundColor Green
        }
        
        "datadog" {
            Write-Host "  DataDog Setup Instructions:" -ForegroundColor Yellow
            Write-Host "    1. Sign up at https://www.datadoghq.com" -ForegroundColor Gray
            Write-Host "    2. Install DataDog agent:" -ForegroundColor Gray
            Write-Host "       DD_API_KEY=<your-key> bash -c \"`$(curl -L https://s3.amazonaws.com/dd-agent/scripts/install_script.sh)\"" -ForegroundColor White
            Write-Host "    3. Configure integrations in DataDog UI" -ForegroundColor Gray
        }
    }
}

# ---------------------------------------------------------
# Generate Alert Configuration
# ---------------------------------------------------------

if ($Action -eq "alerts") {
    Write-Host "`n🚨 Generating alert configuration...`n" -ForegroundColor Cyan
    
    $alertDoc = @"
# Alert Configuration Guide

## Alert Levels

### Critical (Page immediately)
- Service completely down
- Data loss occurring
- Security breach
- Payment processing failed

### High (Notify team)
- Error rate > 5%
- Latency p95 > 2s
- Disk space > 90%
- Memory pressure

### Medium (Create ticket)
- Error rate > 1%
- Latency p95 > 1s
- Disk space > 80%
- Certificate expiring < 30 days

### Low (Log only)
- Minor issues
- Informational events
- Trend warnings

## Alert Best Practices

1. **Alert on symptoms, not causes**
   - Bad: "CPU > 80%"
   - Good: "Request latency > 2s"

2. **Include actionable information**
   - Link to runbook
   - Include relevant metrics
   - Suggest first steps

3. **Set appropriate thresholds**
   - Use percentiles, not averages
   - Account for normal variance
   - Test with historical data

4. **Use time windows**
   - Avoid flapping alerts
   - Typical: 5m for critical, 15m for warnings

## Example Alerts

### High Error Rate
\`\`\`
Condition: Error rate > 5% for 5 minutes
Action: Page on-call engineer
Runbook: docs/runbooks/high-error-rate.md
\`\`\`

### Disk Space Critical
\`\`\`
Condition: Disk usage > 90%
Action: Notify ops team
Runbook: docs/runbooks/disk-space.md
\`\`\`

### Certificate Expiring
\`\`\`
Condition: SSL cert expires < 30 days
Action: Create ticket
Runbook: docs/runbooks/renew-cert.md
\`\`\`
"@
    
    $alertDocPath = Join-Path $OutputDir "alert-guide.md"
    $alertDoc | Set-Content $alertDocPath
    Write-Host "  ✅ Created $alertDocPath" -ForegroundColor Green
}

# ---------------------------------------------------------
# Generate Dashboard
# ---------------------------------------------------------

if ($Action -eq "dashboard") {
    Write-Host "`n📊 Generating dashboard templates...`n" -ForegroundColor Cyan
    
    Write-Host "  Dashboard types:" -ForegroundColor Yellow
    Write-Host "    - Executive: High-level metrics" -ForegroundColor Gray
    Write-Host "    - Operations: System health" -ForegroundColor Gray
    Write-Host "    - Developer: Application metrics" -ForegroundColor Gray
    Write-Host "    - Business: User metrics" -ForegroundColor Gray
    
    Write-Host "`n  💡 Import these into Grafana or your monitoring tool" -ForegroundColor Cyan
}

Write-Host ""
