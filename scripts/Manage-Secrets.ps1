# Manage-Secrets.ps1
# Secrets management automation for Vault, AWS Secrets Manager, and Azure Key Vault

param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("init", "get", "set", "delete", "list", "rotate", "enable-rotation")]
    [string]$Action,
    
    [ValidateSet("vault", "aws-secrets", "azure-keyvault", "aws-ssm")]
    [string]$Provider = "vault",
    
    [string]$Path,
    [string]$Value,
    [hashtable]$Metadata = @{},
    [int]$RotationDays = 90,
    [switch]$IncludeMetadata,
    [switch]$Permanent,
    [switch]$UpdateDatabase
)

$ErrorActionPreference = "Stop"

Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║              SECRETS MANAGEMENT                               ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

Write-Host "`n🔐 Provider: $Provider`n" -ForegroundColor Yellow

# ---------------------------------------------------------
# Initialize Secrets Backend
# ---------------------------------------------------------

if ($Action -eq "init") {
    Write-Host "🚀 Initializing $Provider...`n" -ForegroundColor Cyan
    
    switch ($Provider) {
        "vault" {
            Write-Host "  HashiCorp Vault Setup:" -ForegroundColor Yellow
            Write-Host "    1. Install Vault: https://www.vaultproject.io/downloads" -ForegroundColor Gray
            Write-Host "    2. Start Vault server:" -ForegroundColor Gray
            Write-Host "       vault server -dev" -ForegroundColor White
            Write-Host "    3. Set environment variables:" -ForegroundColor Gray
            Write-Host "       `$env:VAULT_ADDR='http://127.0.0.1:8200'" -ForegroundColor White
            Write-Host "       `$env:VAULT_TOKEN='<root-token>'" -ForegroundColor White
            Write-Host "`n  💡 For production, use a proper backend (Consul, S3, etc.)" -ForegroundColor Cyan
        }
        
        "aws-secrets" {
            Write-Host "  AWS Secrets Manager Setup:" -ForegroundColor Yellow
            Write-Host "    1. Install AWS CLI: https://aws.amazon.com/cli/" -ForegroundColor Gray
            Write-Host "    2. Configure credentials:" -ForegroundColor Gray
            Write-Host "       aws configure" -ForegroundColor White
            Write-Host "    3. Verify access:" -ForegroundColor Gray
            Write-Host "       aws secretsmanager list-secrets" -ForegroundColor White
            
            # Test AWS access
            try {
                $testResult = aws secretsmanager list-secrets --max-results 1 2>&1
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "`n  ✅ AWS Secrets Manager access verified" -ForegroundColor Green
                }
            }
            catch {
                Write-Host "`n  ⚠️  AWS credentials not configured" -ForegroundColor Yellow
            }
        }
        
        "azure-keyvault" {
            Write-Host "  Azure Key Vault Setup:" -ForegroundColor Yellow
            Write-Host "    1. Install Azure CLI: https://docs.microsoft.com/cli/azure/install-azure-cli" -ForegroundColor Gray
            Write-Host "    2. Login to Azure:" -ForegroundColor Gray
            Write-Host "       az login" -ForegroundColor White
            Write-Host "    3. Create Key Vault:" -ForegroundColor Gray
            Write-Host "       az keyvault create --name my-vault --resource-group my-rg --location eastus" -ForegroundColor White
            
            # Test Azure access
            try {
                $testResult = az account show 2>&1
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "`n  ✅ Azure access verified" -ForegroundColor Green
                }
            }
            catch {
                Write-Host "`n  ⚠️  Azure credentials not configured" -ForegroundColor Yellow
            }
        }
    }
}

# ---------------------------------------------------------
# Set Secret
# ---------------------------------------------------------

if ($Action -eq "set") {
    if (-not $Path -or -not $Value) {
        Write-Host "  ❌ Path and Value are required" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "🔒 Storing secret at: $Path`n" -ForegroundColor Cyan
    
    switch ($Provider) {
        "vault" {
            try {
                # Check if vault is available
                $vaultStatus = vault status 2>&1
                
                if ($LASTEXITCODE -ne 0) {
                    Write-Host "  ❌ Vault is not running or not accessible" -ForegroundColor Red
                    Write-Host "  💡 Set VAULT_ADDR and VAULT_TOKEN environment variables" -ForegroundColor Yellow
                    exit 1
                }
                
                # Store secret
                $metadataJson = $Metadata | ConvertTo-Json -Compress
                vault kv put "secret/$Path" value="$Value" metadata="$metadataJson"
                
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "  ✅ Secret stored successfully" -ForegroundColor Green
                }
            }
            catch {
                Write-Host "  ❌ Failed to store secret: $_" -ForegroundColor Red
                exit 1
            }
        }
        
        "aws-secrets" {
            try {
                # Check if secret exists
                $existing = aws secretsmanager describe-secret --secret-id $Path 2>&1
                
                if ($LASTEXITCODE -eq 0) {
                    # Update existing secret
                    aws secretsmanager update-secret --secret-id $Path --secret-string $Value
                    Write-Host "  ✅ Secret updated successfully" -ForegroundColor Green
                }
                else {
                    # Create new secret
                    aws secretsmanager create-secret --name $Path --secret-string $Value
                    Write-Host "  ✅ Secret created successfully" -ForegroundColor Green
                }
            }
            catch {
                Write-Host "  ❌ Failed to store secret: $_" -ForegroundColor Red
                exit 1
            }
        }
        
        "azure-keyvault" {
            try {
                # Extract vault name from path (format: vault-name/secret-name)
                if ($Path -match '^([^/]+)/(.+)$') {
                    $vaultName = $matches[1]
                    $secretName = $matches[2]
                    
                    az keyvault secret set --vault-name $vaultName --name $secretName --value $Value
                    
                    if ($LASTEXITCODE -eq 0) {
                        Write-Host "  ✅ Secret stored successfully" -ForegroundColor Green
                    }
                }
                else {
                    Write-Host "  ❌ Path format should be: vault-name/secret-name" -ForegroundColor Red
                    exit 1
                }
            }
            catch {
                Write-Host "  ❌ Failed to store secret: $_" -ForegroundColor Red
                exit 1
            }
        }
    }
}

# ---------------------------------------------------------
# Get Secret
# ---------------------------------------------------------

if ($Action -eq "get") {
    if (-not $Path) {
        Write-Host "  ❌ Path is required" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "🔓 Retrieving secret from: $Path`n" -ForegroundColor Cyan
    
    switch ($Provider) {
        "vault" {
            try {
                $result = vault kv get -format=json "secret/$Path" 2>&1
                
                if ($LASTEXITCODE -eq 0) {
                    $secret = $result | ConvertFrom-Json
                    
                    if ($IncludeMetadata) {
                        Write-Host "  Value: $($secret.data.data.value)" -ForegroundColor Green
                        Write-Host "  Metadata: $($secret.data.data.metadata)" -ForegroundColor Gray
                        Write-Host "  Version: $($secret.data.metadata.version)" -ForegroundColor Gray
                        Write-Host "  Created: $($secret.data.metadata.created_time)" -ForegroundColor Gray
                    }
                    else {
                        Write-Output $secret.data.data.value
                    }
                }
                else {
                    Write-Host "  ❌ Secret not found" -ForegroundColor Red
                    exit 1
                }
            }
            catch {
                Write-Host "  ❌ Failed to retrieve secret: $_" -ForegroundColor Red
                exit 1
            }
        }
        
        "aws-secrets" {
            try {
                $result = aws secretsmanager get-secret-value --secret-id $Path --output json | ConvertFrom-Json
                
                if ($IncludeMetadata) {
                    Write-Host "  Value: $($result.SecretString)" -ForegroundColor Green
                    Write-Host "  ARN: $($result.ARN)" -ForegroundColor Gray
                    Write-Host "  Version: $($result.VersionId)" -ForegroundColor Gray
                    Write-Host "  Created: $($result.CreatedDate)" -ForegroundColor Gray
                }
                else {
                    Write-Output $result.SecretString
                }
            }
            catch {
                Write-Host "  ❌ Failed to retrieve secret: $_" -ForegroundColor Red
                exit 1
            }
        }
        
        "azure-keyvault" {
            try {
                if ($Path -match '^([^/]+)/(.+)$') {
                    $vaultName = $matches[1]
                    $secretName = $matches[2]
                    
                    $result = az keyvault secret show --vault-name $vaultName --name $secretName --output json | ConvertFrom-Json
                    
                    if ($IncludeMetadata) {
                        Write-Host "  Value: $($result.value)" -ForegroundColor Green
                        Write-Host "  ID: $($result.id)" -ForegroundColor Gray
                        Write-Host "  Created: $($result.attributes.created)" -ForegroundColor Gray
                    }
                    else {
                        Write-Output $result.value
                    }
                }
            }
            catch {
                Write-Host "  ❌ Failed to retrieve secret: $_" -ForegroundColor Red
                exit 1
            }
        }
    }
}

# ---------------------------------------------------------
# List Secrets
# ---------------------------------------------------------

if ($Action -eq "list") {
    Write-Host "📋 Listing secrets...`n" -ForegroundColor Cyan
    
    switch ($Provider) {
        "vault" {
            $listPath = if ($Path) { "secret/metadata/$Path" } else { "secret/metadata/" }
            vault kv list $listPath
        }
        
        "aws-secrets" {
            aws secretsmanager list-secrets --output table
        }
        
        "azure-keyvault" {
            if ($Path -match '^([^/]+)') {
                $vaultName = $matches[1]
                az keyvault secret list --vault-name $vaultName --output table
            }
            else {
                Write-Host "  ❌ Vault name required" -ForegroundColor Red
            }
        }
    }
}

# ---------------------------------------------------------
# Rotate Secret
# ---------------------------------------------------------

if ($Action -eq "rotate") {
    if (-not $Path) {
        Write-Host "  ❌ Path is required" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "🔄 Rotating secret at: $Path`n" -ForegroundColor Cyan
    
    # Generate new password
    $newPassword = -join ((65..90) + (97..122) + (48..57) + (33, 35, 36, 37, 38, 42, 43, 45, 61) | Get-Random -Count 32 | ForEach-Object { [char]$_ })
    
    Write-Host "  Generated new secret" -ForegroundColor Gray
    
    # Store new secret
    & $PSCommandPath -Action "set" -Provider $Provider -Path $Path -Value $newPassword
    
    if ($UpdateDatabase) {
        Write-Host "`n  💡 Remember to update database with new password" -ForegroundColor Yellow
        Write-Host "  New password: $newPassword" -ForegroundColor White
    }
}

# ---------------------------------------------------------
# Delete Secret
# ---------------------------------------------------------

if ($Action -eq "delete") {
    if (-not $Path) {
        Write-Host "  ❌ Path is required" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "🗑️  Deleting secret at: $Path`n" -ForegroundColor Red
    
    if (-not $Permanent) {
        Write-Host "  ⚠️  This will soft-delete the secret (recoverable)" -ForegroundColor Yellow
    }
    else {
        Write-Host "  ⚠️  This will PERMANENTLY delete the secret" -ForegroundColor Red
    }
    
    $confirm = Read-Host "  Type 'delete' to confirm"
    if ($confirm -ne "delete") {
        Write-Host "  ❌ Cancelled" -ForegroundColor Yellow
        exit 0
    }
    
    switch ($Provider) {
        "vault" {
            if ($Permanent) {
                vault kv metadata delete "secret/$Path"
            }
            else {
                vault kv delete "secret/$Path"
            }
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "  ✅ Secret deleted" -ForegroundColor Green
            }
        }
        
        "aws-secrets" {
            if ($Permanent) {
                aws secretsmanager delete-secret --secret-id $Path --force-delete-without-recovery
            }
            else {
                aws secretsmanager delete-secret --secret-id $Path --recovery-window-in-days 7
            }
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "  ✅ Secret deleted" -ForegroundColor Green
            }
        }
        
        "azure-keyvault" {
            if ($Path -match '^([^/]+)/(.+)$') {
                $vaultName = $matches[1]
                $secretName = $matches[2]
                
                az keyvault secret delete --vault-name $vaultName --name $secretName
                
                if ($Permanent) {
                    az keyvault secret purge --vault-name $vaultName --name $secretName
                }
                
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "  ✅ Secret deleted" -ForegroundColor Green
                }
            }
        }
    }
}

Write-Host ""
