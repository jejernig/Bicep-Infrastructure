# Bicep Infrastructure Template Repository Setup Guide

This guide provides detailed instructions for setting up and using the Bicep Infrastructure Template Repository across your projects.

## Setting Up the Template Repository

### Option 1: Create a New Repository from Template

1. **Make this repository a template**:
   - Go to the repository settings in GitHub
   - Check "Template repository" under the Repository section
   - Save changes

2. **Create new repositories from this template**:
   - Click the "Use this template" button on the repository page
   - Select the organization and provide a name for the new repository
   - Choose public or private visibility
   - Click "Create repository from template"

### Option 2: Copy to Existing Projects

For existing projects where you want to implement this infrastructure pipeline:

1. **Copy the essential directories**:
   ```bash
   # Clone this template repository
   git clone https://github.com/your-org/bicep-infrastructure-template.git
   
   # Copy the necessary directories to your project
   cp -r bicep-infrastructure-template/.github/workflows/ your-project/.github/
   cp -r bicep-infrastructure-template/config/ your-project/
   cp -r bicep-infrastructure-template/docs/ your-project/
   
   # If needed, copy the infrastructure directory with Bicep templates
   cp -r bicep-infrastructure-template/infrastructure/ your-project/
   ```

2. **Commit and push the changes to your project repository**

## Required Configuration for Each Project

For each project using this template, you need to:

### 1. Set Up GitHub Environments

Create three environments in your GitHub repository:
- `dev`
- `qa`
- `prod`

Configure protection rules as described in [GitHub Environments Setup](./github-environments-setup.md).

### 2. Configure Repository Secrets

Add the following secrets to your repository:

- `AZURE_CLIENT_ID` - Service Principal ID for Azure authentication
- `AZURE_TENANT_ID` - Azure Tenant ID
- `AZURE_SUBSCRIPTION_ID` - Azure Subscription ID
- `RESOURCE_GROUP_DEV` - Resource group name for dev environment
- `RESOURCE_GROUP_QA` - Resource group name for QA environment
- `RESOURCE_GROUP_PROD` - Resource group name for production environment

### 3. Create Environment Configuration Files

Customize the environment configuration files in `config/environments/`:

- `dev.json` - Development environment settings
- `qa.json` - QA environment settings
- `prod.json` - Production environment settings

Each file should follow this structure:

```json
{
  "environment": "dev",
  "deploymentSettings": {
    "enableResourceLocks": false,
    "enableDiagnostics": true,
    "enableAutomatedBackups": false,
    "resourceTags": {
      "Environment": "Development",
      "CostCenter": "IT-Dev",
      "ManagedBy": "DevOps"
    }
  },
  "approvalRequirements": {
    "requiredApprovers": 0,
    "timeoutMinutes": 60
  },
  "alertSettings": {
    "notificationEmails": ["dev-alerts@example.com"],
    "alertThresholds": {
      "cpuThreshold": 80,
      "memoryThreshold": 80,
      "storageThreshold": 85
    }
  }
}
```

### 4. Customize Bicep Templates

Adapt the Bicep templates in the `infrastructure/bicep/` directory to match your project's specific infrastructure requirements.

## Using the Workflows

### Deploy Infrastructure

1. Navigate to the Actions tab in your repository
2. Select the "Deploy Infrastructure" workflow
3. Click "Run workflow"
4. Select the target environment (dev, qa, prod)
5. Optionally specify a custom configuration path
6. Click "Run workflow"

The workflow will:
- Validate your configuration
- Perform a What-If analysis to preview changes
- Deploy the infrastructure
- Generate and store deployment outputs
- Create a deployment summary

### Teardown Infrastructure

1. Navigate to the Actions tab in your repository
2. Select the "Teardown Infrastructure" workflow
3. Click "Run workflow"
4. Select the target environment (dev, qa, prod)
5. Type the environment name again to confirm deletion
6. Click "Run workflow"

The workflow will:
- Validate your confirmation
- Delete resources in reverse dependency order
- Generate a teardown report
- Store the teardown history

## Best Practices

1. **Version Control**: Always commit deployment and teardown history to maintain an audit trail
2. **Environment Protection**: Use GitHub Environment protection rules to prevent accidental deployments
3. **Configuration Management**: Keep environment-specific settings in the appropriate config files
4. **Documentation**: Maintain documentation of your infrastructure components
5. **Testing**: Test workflows in development environments before using in production

## Troubleshooting

If you encounter issues with the workflows:

1. Check the workflow run logs for detailed error messages
2. Verify that all required secrets are correctly configured
3. Ensure your Azure Service Principal has appropriate permissions
4. Validate your environment configuration files against the expected schema
5. Check that your Bicep templates are valid and deployable

For additional help, refer to the [GitHub Actions documentation](https://docs.github.com/en/actions) or [Azure Bicep documentation](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/).
