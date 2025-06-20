# Bicep Infrastructure GitHub Actions Workflows

This directory contains GitHub Actions workflows for deploying and managing Azure infrastructure using Bicep templates.

## Available Workflows

### 1. Deploy Infrastructure (`deploy-infrastructure.yml`)

This workflow deploys Bicep infrastructure to Azure based on the provided configuration file.

#### Workflow Inputs:
- **environment**: Target environment for deployment (dev, qa, prod)
- **configPath**: Path to the configuration YAML file

#### Usage:
1. Navigate to the "Actions" tab in the GitHub repository
2. Select "Deploy Infrastructure" workflow
3. Click "Run workflow"
4. Select the target environment and provide the configuration file path
5. Click "Run workflow" to start the deployment

#### Required Secrets:
- `AZURE_CLIENT_ID`: Azure service principal client ID
- `AZURE_TENANT_ID`: Azure tenant ID
- `AZURE_SUBSCRIPTION_ID`: Azure subscription ID
- `RESOURCE_GROUP_DEV`: Resource group name for dev environment
- `RESOURCE_GROUP_QA`: Resource group name for QA environment
- `RESOURCE_GROUP_PROD`: Resource group name for production environment

### 2. Teardown Infrastructure (`teardown-infrastructure.yml`)

This workflow safely removes Azure resources deployed by the Bicep templates in reverse dependency order.

#### Workflow Inputs:
- **environment**: Target environment for teardown (dev, qa, prod)
- **confirmation**: Confirmation text (must match environment name)

#### Usage:
1. Navigate to the "Actions" tab in the GitHub repository
2. Select "Teardown Infrastructure" workflow
3. Click "Run workflow"
4. Select the target environment and type the environment name again for confirmation
5. Click "Run workflow" to start the teardown process

#### Safety Features:
- Requires explicit confirmation by typing the environment name
- Production teardown is restricted to admin users
- Resources are deleted in reverse dependency order to respect resource relationships

## Environment Protection Rules

- **Production**: Requires approval from at least one reviewer
- **QA**: Requires approval from at least one reviewer
- **Dev**: No approval required

## Deployment Outputs

Deployment outputs are saved as artifacts and are available for 30 days after the workflow run. These outputs can be used by other workflows or for reference.
