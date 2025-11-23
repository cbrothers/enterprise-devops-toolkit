# Setup-Logging.ps1
# Logging strategy and configuration advisor

param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("analyze", "recommend", "configure", "aggregate", "test")]
    [string]$Action,
    
    [ValidateSet("serilog", "winston", "structlog", "custom")]
    [string]$Framework,
    
    [ValidateSet("elk", "loki", "splunk", "cloudwatch")]
    [string]$Stack,
    
    [string]$OutputDir = "logging"
)

$ErrorActionPreference = "Continue"

Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║              LOGGING STRATEGY ADVISOR                         ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

# Ensure output directory exists
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

# ---------------------------------------------------------
# Analyze Current Logging
# ---------------------------------------------------------

if ($Action -eq "analyze") {
    Write-Host "`n🔍 Analyzing current logging setup...`n" -ForegroundColor Cyan
    
    # Find log files
    Write-Host "  Searching for log files:" -ForegroundColor Yellow
    $logFiles = Get-ChildItem -Path "." -Recurse -Include "*.log" -File -ErrorAction SilentlyContinue | Select-Object -First 10
    
    if ($logFiles) {
        Write-Host "    ✅ Found $($logFiles.Count) log file(s)" -ForegroundColor Green
        
        foreach ($log in $logFiles) {
            $size = [Math]::Round($log.Length / 1MB, 2)
            Write-Host "       - $($log.Name) ($size MB)" -ForegroundColor Gray
            
            # Sample first line to detect format
            $firstLine = Get-Content $log.FullName -First 1 -ErrorAction SilentlyContinue
            if ($firstLine) {
                if ($firstLine -match '^\{.*\}$') {
                    Write-Host "         Format: JSON (structured) ✅" -ForegroundColor Green
                }
                else {
                    Write-Host "         Format: Plain text (unstructured) ⚠️" -ForegroundColor Yellow
                }
            }
        }
    }
    else {
        Write-Host "    ⚠️  No log files found" -ForegroundColor Yellow
    }
    
    # Check for logging frameworks
    Write-Host "`n  Checking for logging frameworks:" -ForegroundColor Yellow
    
    # Check package.json
    if (Test-Path "package.json") {
        $packageJson = Get-Content "package.json" | ConvertFrom-Json
        if ($packageJson.dependencies.winston) {
            Write-Host "    ✅ Winston detected (Node.js)" -ForegroundColor Green
        }
        if ($packageJson.dependencies.pino) {
            Write-Host "    ✅ Pino detected (Node.js)" -ForegroundColor Green
        }
    }
    
    # Check for .NET projects
    $csprojFiles = Get-ChildItem -Filter "*.csproj" -File
    if ($csprojFiles) {
        foreach ($csproj in $csprojFiles) {
            $content = Get-Content $csproj.FullName -Raw
            if ($content -match 'Serilog') {
                Write-Host "    ✅ Serilog detected (.NET)" -ForegroundColor Green
            }
        }
    }
    
    # Recommendations
    Write-Host "`n💡 Recommendations:" -ForegroundColor Cyan
    if (-not $logFiles) {
        Write-Host "    - Implement application logging" -ForegroundColor Yellow
    }
    Write-Host "    - Use structured logging (JSON format)" -ForegroundColor Gray
    Write-Host "    - Implement log rotation" -ForegroundColor Gray
    Write-Host "    - Set up centralized log aggregation" -ForegroundColor Gray
}

# ---------------------------------------------------------
# Recommend Logging Strategy
# ---------------------------------------------------------

if ($Action -eq "recommend") {
    Write-Host "`n🎯 Logging Strategy Recommendations`n" -ForegroundColor Cyan
    
    Write-Host "  📋 Logging Levels:" -ForegroundColor Yellow
    Write-Host "    TRACE  - Very detailed (development only)" -ForegroundColor Gray
    Write-Host "    DEBUG  - Detailed diagnostics" -ForegroundColor Gray
    Write-Host "    INFO   - General information" -ForegroundColor Green
    Write-Host "    WARN   - Warning messages" -ForegroundColor Yellow
    Write-Host "    ERROR  - Error messages" -ForegroundColor Red
    Write-Host "    FATAL  - Critical errors" -ForegroundColor Magenta
    
    Write-Host "`n  📝 What to Log:" -ForegroundColor Yellow
    Write-Host "    ✅ User actions (login, purchases)" -ForegroundColor Green
    Write-Host "    ✅ API calls (endpoint, duration)" -ForegroundColor Green
    Write-Host "    ✅ Errors with context" -ForegroundColor Green
    Write-Host "    ✅ Performance metrics" -ForegroundColor Green
    Write-Host "    ✅ Security events" -ForegroundColor Green
    
    Write-Host "`n  ❌ What NOT to Log:" -ForegroundColor Yellow
    Write-Host "    ❌ Passwords or secrets" -ForegroundColor Red
    Write-Host "    ❌ Credit card numbers" -ForegroundColor Red
    Write-Host "    ❌ PII without redaction" -ForegroundColor Red
    Write-Host "    ❌ Session tokens" -ForegroundColor Red
    
    Write-Host "`n  🏗️  Recommended Stack:" -ForegroundColor Yellow
    Write-Host "    Small: File-based + Loki" -ForegroundColor Gray
    Write-Host "    Medium: ELK Stack or Splunk Cloud" -ForegroundColor Gray
    Write-Host "    Large: ELK Stack + Kafka" -ForegroundColor Gray
}

# ---------------------------------------------------------
# Generate Logging Configuration
# ---------------------------------------------------------

if ($Action -eq "configure" -and $Framework) {
    Write-Host "`n⚙️  Generating $Framework configuration...`n" -ForegroundColor Cyan
    
    switch ($Framework) {
        "serilog" {
            $serilogConfig = @"
// Serilog Configuration (.NET)
using Serilog;

Log.Logger = new LoggerConfiguration()
    .MinimumLevel.Information()
    .MinimumLevel.Override("Microsoft", LogEventLevel.Warning)
    .Enrich.FromLogContext()
    .Enrich.WithMachineName()
    .Enrich.WithThreadId()
    .WriteTo.Console(
        outputTemplate: "[{Timestamp:HH:mm:ss} {Level:u3}] {Message:lj}{NewLine}{Exception}")
    .WriteTo.File(
        path: "logs/app-.txt",
        rollingInterval: RollingInterval.Day,
        retainedFileCountLimit: 30,
        outputTemplate: "{Timestamp:yyyy-MM-dd HH:mm:ss.fff zzz} [{Level:u3}] {Message:lj}{NewLine}{Exception}")
    .WriteTo.Elasticsearch(new ElasticsearchSinkOptions(new Uri("http://localhost:9200"))
    {
        AutoRegisterTemplate = true,
        IndexFormat = "app-logs-{0:yyyy.MM.dd}"
    })
    .CreateLogger();

// Usage example
Log.Information("User {UserId} logged in from {IpAddress}", userId, ipAddress);
Log.Error(exception, "Failed to process order {OrderId}", orderId);
"@
            
            $configPath = Join-Path $OutputDir "serilog-config.cs"
            $serilogConfig | Set-Content $configPath
            Write-Host "  ✅ Created $configPath" -ForegroundColor Green
        }
        
        "winston" {
            $winstonConfig = @"
// Winston Configuration (Node.js)
const winston = require('winston');

const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.json()
  ),
  defaultMeta: { service: 'my-app' },
  transports: [
    new winston.transports.File({ 
      filename: 'logs/error.log', 
      level: 'error',
      maxsize: 10485760, // 10MB
      maxFiles: 5
    }),
    new winston.transports.File({ 
      filename: 'logs/combined.log',
      maxsize: 10485760,
      maxFiles: 10
    })
  ]
});

// Add console in development
if (process.env.NODE_ENV !== 'production') {
  logger.add(new winston.transports.Console({
    format: winston.format.simple()
  }));
}

// Usage example
logger.info('User login', { userId: 123, ipAddress: '192.168.1.1' });
logger.error('Payment failed', { orderId: 456, error: err.message });

module.exports = logger;
"@
            
            $configPath = Join-Path $OutputDir "winston-config.js"
            $winstonConfig | Set-Content $configPath
            Write-Host "  ✅ Created $configPath" -ForegroundColor Green
        }
        
        "custom" {
            $customConfig = @"
# Custom PowerShell Logging
function Write-StructuredLog {
    param(
        [Parameter(Mandatory=`$true)]
        [ValidateSet("TRACE", "DEBUG", "INFO", "WARN", "ERROR", "FATAL")]
        [string]`$Level,
        
        [Parameter(Mandatory=`$true)]
        [string]`$Message,
        
        [hashtable]`$Properties = @{},
        
        [System.Exception]`$Exception
    )
    
    `$logEntry = @{
        Timestamp = (Get-Date).ToUniversalTime().ToString("o")
        Level = `$Level
        Message = `$Message
        Properties = `$Properties
        MachineName = `$env:COMPUTERNAME
        ProcessId = `$PID
    }
    
    if (`$Exception) {
        `$logEntry.Exception = @{
            Message = `$Exception.Message
            StackTrace = `$Exception.StackTrace
            Type = `$Exception.GetType().FullName
        }
    }
    
    `$json = `$logEntry | ConvertTo-Json -Compress
    
    # Write to file
    `$logFile = "logs/app-`$(Get-Date -Format 'yyyy-MM-dd').log"
    Add-Content -Path `$logFile -Value `$json
    
    # Write to console in development
    if (`$env:ENVIRONMENT -ne "Production") {
        `$color = switch (`$Level) {
            "ERROR" { "Red" }
            "WARN" { "Yellow" }
            "INFO" { "Green" }
            default { "Gray" }
        }
        Write-Host "[`$Level] `$Message" -ForegroundColor `$color
    }
}

# Usage examples
Write-StructuredLog -Level "INFO" -Message "Application started"
Write-StructuredLog -Level "ERROR" -Message "Database connection failed" -Properties @{ ConnectionString = "..." } -Exception `$ex
"@
            
            $configPath = Join-Path $OutputDir "custom-logging.ps1"
            $customConfig | Set-Content $configPath
            Write-Host "  ✅ Created $configPath" -ForegroundColor Green
        }
    }
}

# ---------------------------------------------------------
# Setup Log Aggregation
# ---------------------------------------------------------

if ($Action -eq "aggregate" -and $Stack) {
    Write-Host "`n📦 Setting up $Stack log aggregation...`n" -ForegroundColor Cyan
    
    switch ($Stack) {
        "elk" {
            Write-Host "  ELK Stack Setup:" -ForegroundColor Yellow
            Write-Host "    1. Install Elasticsearch" -ForegroundColor Gray
            Write-Host "    2. Install Logstash" -ForegroundColor Gray
            Write-Host "    3. Install Kibana" -ForegroundColor Gray
            Write-Host "`n  💡 Docker Compose example created" -ForegroundColor Cyan
            
            $dockerCompose = @"
version: '3.7'
services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.11.0
    environment:
      - discovery.type=single-node
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
    ports:
      - 9200:9200
    
  logstash:
    image: docker.elastic.co/logstash/logstash:8.11.0
    volumes:
      - ./logstash.conf:/usr/share/logstash/pipeline/logstash.conf
    depends_on:
      - elasticsearch
    
  kibana:
    image: docker.elastic.co/kibana/kibana:8.11.0
    ports:
      - 5601:5601
    depends_on:
      - elasticsearch
"@
            
            $composePath = Join-Path $OutputDir "docker-compose-elk.yml"
            $dockerCompose | Set-Content $composePath
            Write-Host "  ✅ Created $composePath" -ForegroundColor Green
        }
        
        "loki" {
            Write-Host "  Loki + Grafana Setup:" -ForegroundColor Yellow
            Write-Host "    1. Install Loki" -ForegroundColor Gray
            Write-Host "    2. Install Promtail (log shipper)" -ForegroundColor Gray
            Write-Host "    3. Configure Grafana data source" -ForegroundColor Gray
        }
    }
}

Write-Host ""
