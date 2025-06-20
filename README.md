# Bicep Infrastructure Template Repository

This repository serves as a template for Azure Bicep Infrastructure as Code (IaC) deployments. It contains reusable workflows, configuration structures, and documentation to standardize infrastructure deployments across projects.

## Overview

The Bicep Infrastructure project provides a structured approach to deploying Azure resources using Bicep templates. It includes:

- A configuration system with JSON schema validation
- Bicep modules for various Azure resources
- GitHub Actions workflows for deployment and teardown
- Environment-specific configuration management
- Deployment scripts and utilities
- Documentation and best practices

## Getting Started

### Prerequisites

- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- [Bicep CLI](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/install)
- [Node.js](https://nodejs.org/) (for configuration validation)

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/jejernig/Bicep-Infrastructure.git
   cd Bicep-Infrastructure
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

## Using as a Template Repository

This repository is designed to be used as a template for all your Bicep infrastructure projects. Here's how to use it:

### For New Projects

1. Click the "Use this template" button in GitHub to create a new repository based on this template
2. Clone your new repository
3. Configure environment-specific settings in `config/environments/` directory
4. Set up GitHub Environments and secrets (see [GitHub Environments Setup](./docs/github-environments-setup.md))
5. Customize Bicep templates as needed for your project
6. Deploy using the provided GitHub Actions workflows

For detailed instructions, see the [Template Repository Setup Guide](./docs/template-repository-setup.md).

### For Existing Projects

1. Copy the following directories to your project:
   - `.github/workflows/` - Contains deployment and teardown workflows
   - `config/environments/` - For environment-specific configurations
   - `docs/` - Documentation including GitHub Environments setup

2. Set up GitHub Environments and secrets as described in the documentation

3. Create environment-specific configuration files that conform to the provided schema (`config/environments/environment.schema.json`)

For detailed instructions, see the [Template Repository Setup Guide](./docs/template-repository-setup.md).

### Required GitHub Secrets

For each project using these workflows, you need to set up the following secrets:

- `AZURE_CLIENT_ID` - Service Principal ID for Azure authentication
- `AZURE_TENANT_ID` - Azure Tenant ID
- `AZURE_SUBSCRIPTION_ID` - Azure Subscription ID
- `RESOURCE_GROUP_DEV` - Resource group name for dev environment
- `RESOURCE_GROUP_QA` - Resource group name for QA environment
- `RESOURCE_GROUP_PROD` - Resource group name for production environment

## GitHub Actions Workflows

This template includes two main GitHub Actions workflows for infrastructure management:

### Deploy Infrastructure Workflow

**File:** `.github/workflows/deploy-infrastructure.yml`

This workflow handles the deployment of Bicep infrastructure to Azure. Key features include:

- Environment-specific configuration loading from `config/environments/{environment}.json`
- Parameter preparation based on environment settings
- Validation of Bicep templates before deployment
- What-If analysis to preview changes
- Deployment with detailed output capturing
- Generation of deployment summaries and reports
- Storage of deployment history for auditing

**Usage:**

1. Navigate to Actions > Deploy Infrastructure
2. Select the environment (dev, qa, prod)
3. Provide an optional configuration path if needed
4. Run the workflow

### Teardown Infrastructure Workflow

**File:** `.github/workflows/teardown-infrastructure.yml`

This workflow safely tears down infrastructure in a specific environment. Key features include:

- Confirmation validation to prevent accidental deletions
- Additional protection for production environments
- Resource deletion in the correct dependency order
- Detailed teardown reporting
- History tracking of all teardown operations

**Usage:**

1. Navigate to Actions > Teardown Infrastructure
2. Select the environment (dev, qa, prod)
3. Confirm by typing the environment name again
4. Run the workflow

## Configuration System

### Overview

The configuration system uses a `bicep.config.json` file to define the parameters and settings for your infrastructure deployment. The file is validated against a JSON schema to ensure correctness.

### Configuration File Structure

The `bicep.config.json` file has the following structure:

```json
{
  "$schema": "./bicep.config.schema.json",
  "metadata": {
    "projectName": "yourproject",
    "environment": "dev",
    "location": "eastus"
  },
  "tags": {
    "environment": "dev",
    "project": "YourProject"
  },
  "featureToggles": {
    "enableApiManagement": true,
    "enableFunctionApp": true,
    ...
  },
  "moduleConfigurations": {
    "apiManagement": { ... },
    "functionApp": { ... },
    ...
  },
  "bicepSettings": {
    "linterEnabled": true,
    ...
  }
}
```

### Key Components

- **metadata**: Core project information
- **tags**: Resource tags applied to all resources
- **featureToggles**: Enable/disable specific modules
- **moduleConfigurations**: Settings for each module
- **bicepSettings**: Bicep linter and formatting settings

### Validation

To validate your configuration file:

```bash
npm run validate
```

Or validate a specific configuration file:

```bash
node ./infrastructure/scripts/validate-config.js ./path/to/your/config.json
```

### Templates

Example configuration templates are available in the `infrastructure/bicep/templates/` directory:

- `minimal-dev.json`: Minimal configuration for development environments
- `standard-prod.json`: Standard configuration for production environments
- `comprehensive.json`: Comprehensive configuration with all features enabled

## Deployment

### Basic Deployment

To deploy the infrastructure using the default configuration:

```bash
az login
az account set --subscription <subscription-id>
az deployment sub create \
  --location eastus \
  --template-file infrastructure/bicep/main.bicep \
  --parameters @infrastructure/bicep/bicep.config.json
```

### Environment-Specific Deployment

For environment-specific deployments, create a configuration file for each environment and use it for deployment:

```bash
az deployment sub create \
  --location eastus \
  --template-file infrastructure/bicep/main.bicep \
  --parameters @infrastructure/bicep/bicep.config.prod.json
```

## Module Documentation

### Available Modules

- **API Management**: API gateway for managing APIs
- **Function App**: Serverless compute service
- **SignalR**: Real-time web functionality
- **Redis Cache**: In-memory data store
- **Key Vault**: Secrets management
- **OpenAI**: AI services integration
- **Container Registry**: Docker image registry
- **Storage Account**: Cloud storage
- **Container Instance**: Containerized applications
- **SQL Database**: Relational database

### Module Configuration

Each module has specific configuration options available in the `moduleConfigurations` section of the configuration file. Refer to the [schema file](./infrastructure/bicep/bicep.config.schema.json) for detailed information on available options.

## Best Practices

For naming conventions and best practices, see the [Naming Conventions and Best Practices](./docs/naming-conventions.md) document.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
