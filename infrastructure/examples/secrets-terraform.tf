# Terraform Integration with Secrets Management

## Using HashiCorp Vault with Terraform

terraform {
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure Vault provider
provider "vault" {
  address = "https://vault.example.com:8200"
  # Token from environment variable VAULT_TOKEN
}

# Read database password from Vault
data "vault_generic_secret" "db_password" {
  path = "secret/prod/db/password"
}

# Use secret in RDS instance
resource "aws_db_instance" "main" {
  identifier = "production-db"
  engine     = "mysql"
  
  username = "admin"
  password = data.vault_generic_secret.db_password.data["value"]
  
  instance_class    = "db.t3.micro"
  allocated_storage = 20
}

# Store generated secret back to Vault
resource "vault_generic_secret" "api_key" {
  path = "secret/prod/api/key"
  
  data_json = jsonencode({
    value = random_password.api_key.result
  })
}

resource "random_password" "api_key" {
  length  = 32
  special = true
}

## Using AWS Secrets Manager with Terraform

# Read secret from AWS Secrets Manager
data "aws_secretsmanager_secret" "db_password" {
  name = "prod/db/password"
}

data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = data.aws_secretsmanager_secret.db_password.id
}

# Use secret in RDS instance
resource "aws_db_instance" "main" {
  identifier = "production-db"
  engine     = "mysql"
  
  username = "admin"
  password = jsondecode(data.aws_secretsmanager_secret_version.db_password.secret_string)["password"]
  
  instance_class    = "db.t3.micro"
  allocated_storage = 20
}

# Create secret in AWS Secrets Manager
resource "aws_secretsmanager_secret" "api_key" {
  name                    = "prod/api/key"
  recovery_window_in_days = 7
}

resource "aws_secretsmanager_secret_version" "api_key" {
  secret_id = aws_secretsmanager_secret.api_key.id
  secret_string = jsonencode({
    api_key = random_password.api_key.result
  })
}

# Enable automatic rotation
resource "aws_secretsmanager_secret_rotation" "db_password" {
  secret_id           = aws_secretsmanager_secret.db_password.id
  rotation_lambda_arn = aws_lambda_function.rotate_secret.arn
  
  rotation_rules {
    automatically_after_days = 30
  }
}

## Using Azure Key Vault with Terraform

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Reference existing Key Vault
data "azurerm_key_vault" "main" {
  name                = "my-key-vault"
  resource_group_name = "my-resource-group"
}

# Read secret from Key Vault
data "azurerm_key_vault_secret" "db_password" {
  name         = "db-password"
  key_vault_id = data.azurerm_key_vault.main.id
}

# Use secret in SQL Database
resource "azurerm_mssql_server" "main" {
  name                         = "production-sql"
  resource_group_name          = azurerm_resource_group.main.name
  location                     = azurerm_resource_group.main.location
  version                      = "12.0"
  administrator_login          = "sqladmin"
  administrator_login_password = data.azurerm_key_vault_secret.db_password.value
}

# Create secret in Key Vault
resource "azurerm_key_vault_secret" "api_key" {
  name         = "api-key"
  value        = random_password.api_key.result
  key_vault_id = data.azurerm_key_vault.main.id
}

## Best Practices

# 1. Never hardcode secrets
# BAD:
resource "aws_db_instance" "bad" {
  password = "hardcoded-password"  # NEVER DO THIS
}

# GOOD:
resource "aws_db_instance" "good" {
  password = data.vault_generic_secret.db_password.data["value"]
}

# 2. Use sensitive = true for outputs
output "db_password" {
  value     = data.vault_generic_secret.db_password.data["value"]
  sensitive = true  # Prevents showing in logs
}

# 3. Store Terraform state securely
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true  # Encrypt state file
    dynamodb_table = "terraform-locks"
  }
}

# 4. Use random providers for generating secrets
resource "random_password" "db_password" {
  length  = 32
  special = true
  
  lifecycle {
    ignore_changes = [
      # Don't regenerate on every apply
      length,
      special
    ]
  }
}

# 5. Implement secret rotation
resource "aws_secretsmanager_secret_rotation" "example" {
  secret_id           = aws_secretsmanager_secret.example.id
  rotation_lambda_arn = aws_lambda_function.rotate.arn
  
  rotation_rules {
    automatically_after_days = 90
  }
}
