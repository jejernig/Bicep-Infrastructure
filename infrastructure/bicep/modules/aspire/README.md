# .NET Aspire Module

This module provides infrastructure as code (IaC) for deploying .NET Aspire applications using Azure Container Apps. It includes components for managing the Container Apps Environment, individual Container Apps, and related resources.

## Features

- **Container Apps Environment**: Deploy a managed environment for your containerized applications
- **Container Apps**: Deploy and manage containerized applications with ease
- **Integrated Logging**: Built-in support for Azure Monitor and Log Analytics
- **Networking**: Configure ingress, networking, and scaling options
- **Secrets Management**: Secure handling of environment variables and secrets
- **CI/CD Ready**: Designed for seamless integration with CI/CD pipelines

## Prerequisites

- Azure subscription with appropriate permissions
- Azure CLI installed and configured
- Bicep CLI installed
- .NET 8.0 or later (for local development)

## Module Components

### 1. Container App Environment (`container-app-environment.bicep`)

Creates a Container Apps Environment which is a secure boundary around a group of container apps.

**Key Features:**
- Network isolation with custom VNet integration
- Zone redundancy
- Internal load balancing
- Log Analytics integration

### 2. Container App (`container-app.bicep`)

Deploys a containerized application within the Container Apps Environment.

**Key Features:**
- Multiple container support
- Environment variables and secrets
- Custom scaling rules
- Ingress configuration
- Traffic splitting between revisions
- Private container registry support

### 3. Main Module (`main.bicep`)

Orchestrates the deployment of the Container Apps Environment and Container Apps.

## Usage

### 1. Configuration

Create a YAML configuration file (e.g., `aspire-config.yaml`) with your application settings:

```yaml
moduleConfigurations:
  aspire:
    containerAppEnvironment:
      name: "aspire-${environment}-env"
      internalLoadBalancerEnabled: false
      logAnalyticsWorkspaceId: "/subscriptions/.../resourceGroups/.../workspaces/..."
      # Additional environment settings...
    
    containerApps:
      - name: "myapp-api-${environment}"
        containerImage: "myregistry.azurecr.io/myapp-api"
        containerImageTag: "latest"
        containerPort: 8080
        replicas: 2
        resources:
          cpu: 0.5
          memory: "1Gi"
        env:
          - name: "ASPNETCORE_ENVIRONMENT"
            value: "Production"
          - name: "ConnectionStrings__Database"
            secretRef: "db-connection"
        secrets:
          - name: "db-connection"
            value: "Server=..."
        ingress:
          external: true
          targetPort: 8080
          allowInsecure: false
          traffic:
            - latestRevision: true
              weight: 100
        registry:
          server: "myregistry.azurecr.io"
          username: "myregistry"
          passwordSecretRef: "registry-password"
```

### 2. Deployment

Deploy using Azure CLI:

```bash
# Login to Azure
az login

# Set your subscription
az account set --subscription "your-subscription-id"

# Create a resource group
az group create --name my-resource-group --location eastus

# Deploy the infrastructure
az deployment group create \
  --resource-group my-resource-group \
  --template-file ./main.bicep \
  --parameters @./aspire-config.yaml
```

## Advanced Scenarios

### Private Endpoints

To enable private endpoints for your Container Apps Environment, configure the following:

```yaml
containerAppEnvironment:
  name: "aspire-${environment}-env"
  internalLoadBalancerEnabled: true
  infrastructureSubnetId: "/subscriptions/.../subnets/container-apps"
  # Additional private networking settings...
```

### Custom Scaling

Configure custom scaling rules for your Container Apps:

```yaml
containerApps:
  - name: "myapp-api-${environment}"
    # ... other settings ...
    scale:
      minReplicas: 1
      maxReplicas: 10
      rules:
        - name: http-rule
          http:
            metadata:
              concurrentRequests: "100"
```

### Dapr Integration

Enable Dapr for your Container Apps:

```yaml
containerApps:
  - name: "myapp-api-${environment}"
    # ... other settings ...
    dapr:
      enabled: true
      appPort: 50001
      appProtocol: "http"
      components:
        - name: statestore
          type: state.azure.blobstorage
          version: v1
          metadata:
            - name: accountName
              value: "mystorageaccount"
            - name: containerName
              value: "mystate"
            - name: accountKey
              secretRef: "storage-account-key"
```

## Best Practices

1. **Naming Conventions**: Use consistent naming patterns for resources
2. **Tags**: Apply appropriate tags for cost management and organization
3. **Secrets Management**: Use Azure Key Vault for sensitive information
4. **Monitoring**: Enable Azure Monitor and configure alerts
5. **CI/CD**: Integrate with GitHub Actions or Azure DevOps for automated deployments

## Troubleshooting

### Common Issues

1. **Deployment Failures**: Check the Azure Portal deployment logs for detailed error messages
2. **Container Startup Issues**: Use the Container Apps console to view container logs
3. **Networking Problems**: Verify NSGs and route tables if using custom VNet
4. **Authentication Errors**: Ensure service principals have the correct RBAC assignments

### Debugging

To debug deployment issues:

```bash
# Get deployment details
az deployment group show \
  --resource-group my-resource-group \
  --name deployment-name

# Get container logs
az containerapp logs show \
  --name myapp-api \
  --resource-group my-resource-group \
  --follow
```

## Related Documentation

- [Azure Container Apps Documentation](https://docs.microsoft.com/azure/container-apps/)
- [.NET Aspire Documentation](https://learn.microsoft.com/dotnet/aspire/)
- [Bicep Documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
