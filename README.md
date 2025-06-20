# Bicep Infrastructure

This repository contains Azure Bicep Infrastructure as Code (IaC) templates and a configuration system for deploying and managing Azure resources.

## Overview

The Bicep Infrastructure project provides a structured approach to deploying Azure resources using Bicep templates. It includes:

- A configuration system with JSON schema validation
- Bicep modules for various Azure resources
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
