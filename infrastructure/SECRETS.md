# Secrets Management - Quick Reference

## 🔐 Quick Commands

### HashiCorp Vault

```powershell
# Store secret
.agent\scripts\Manage-Secrets.ps1 -Action "set" -Provider "vault" `
    -Path "prod/db/password" -Value "SecurePassword123!"

# Retrieve secret
.agent\scripts\Manage-Secrets.ps1 -Action "get" -Provider "vault" `
    -Path "prod/db/password"

# Rotate secret
.agent\scripts\Manage-Secrets.ps1 -Action "rotate" -Provider "vault" `
    -Path "prod/db/password"

# List secrets
.agent\scripts\Manage-Secrets.ps1 -Action "list" -Provider "vault" `
    -Path "prod/"
```

### AWS Secrets Manager

```powershell
# Store secret
.agent\scripts\Manage-Secrets.ps1 -Action "set" -Provider "aws-secrets" `
    -Path "prod/db/password" -Value "SecurePassword123!"

# Retrieve secret
.agent\scripts\Manage-Secrets.ps1 -Action "get" -Provider "aws-secrets" `
    -Path "prod/db/password"

# Enable rotation
.agent\scripts\Manage-Secrets.ps1 -Action "enable-rotation" -Provider "aws-secrets" `
    -Path "prod/db/password" -RotationDays 30
```

### Azure Key Vault

```powershell
# Store secret (format: vault-name/secret-name)
.agent\scripts\Manage-Secrets.ps1 -Action "set" -Provider "azure-keyvault" `
    -Path "my-vault/db-password" -Value "SecurePassword123!"

# Retrieve secret
.agent\scripts\Manage-Secrets.ps1 -Action "get" -Provider "azure-keyvault" `
    -Path "my-vault/db-password"
```

## 📋 Common Patterns

### Application Configuration

```powershell
# Store database connection string
.agent\scripts\Manage-Secrets.ps1 -Action "set" -Path "prod/db/connection-string" `
    -Value "Server=myserver;Database=mydb;User=admin;Password=secret;"

# Store API keys
.agent\scripts\Manage-Secrets.ps1 -Action "set" -Path "prod/api/stripe-key" `
    -Value "sk_live_..."

# Store OAuth credentials
.agent\scripts\Manage-Secrets.ps1 -Action "set" -Path "prod/oauth/google" `
    -Value '{"client_id":"...","client_secret":"..."}'
```

### Certificate Management

```powershell
# Store SSL certificate
.agent\scripts\Manage-Secrets.ps1 -Action "set" -Path "prod/ssl/cert" `
    -Value (Get-Content cert.pem -Raw)

# Store private key
.agent\scripts\Manage-Secrets.ps1 -Action "set" -Path "prod/ssl/key" `
    -Value (Get-Content key.pem -Raw)
```

## 🔄 Rotation Schedule

| Secret Type | Rotation Frequency |
|-------------|-------------------|
| Database passwords | Every 90 days |
| API keys | Every 90 days |
| Service accounts | Every 180 days |
| SSL certificates | Before expiration |
| OAuth tokens | Per provider policy |

## 🚨 Emergency Procedures

### Compromised Secret

```powershell
# 1. Immediately rotate
.agent\scripts\Manage-Secrets.ps1 -Action "rotate" -Path "prod/api/key"

# 2. Audit access logs
# Check who accessed the secret

# 3. Update applications
# Deploy new secret to all services

# 4. Revoke old secret
# Ensure old version is no longer valid
```

## 🔒 Security Checklist

- [ ] Never commit secrets to Git
- [ ] Use `.gitignore` for sensitive files
- [ ] Enable audit logging
- [ ] Implement least privilege access
- [ ] Rotate secrets regularly
- [ ] Use encryption at rest
- [ ] Monitor secret access
- [ ] Have break-glass procedures
- [ ] Test secret recovery
- [ ] Document secret locations

## 📚 Learn More

- [Secrets Management Workflow](../workflows/secrets-management.md)
- [Terraform Integration](examples/secrets-terraform.tf)
- [HashiCorp Vault Docs](https://www.vaultproject.io/docs)
- [AWS Secrets Manager Docs](https://docs.aws.amazon.com/secretsmanager/)
- [Azure Key Vault Docs](https://docs.microsoft.com/azure/key-vault/)
