# Bicep Configuration Naming Conventions and Best Practices

This document outlines the naming conventions and best practices for the Bicep infrastructure configuration files.

## Directory Structure

```
infrastructure/
├── bicep/
│   ├── bicep.config.json         # Main configuration file
│   ├── bicep.config.schema.json  # JSON Schema definition
│   ├── main.bicep                # Main Bicep orchestration file
│   ├── modules/                  # Bicep modules
│   └── templates/                # Example configuration templates
├── scripts/                      # Utility scripts
└── docs/                         # Documentation
```

## Naming Conventions

### Resource Naming

All Azure resources should follow a consistent naming pattern:

```
{projectName}-{resourceType}-{environment}[-{instance}]
```

Where:
- `projectName`: The project identifier (e.g., "phantomline")
- `resourceType`: Abbreviated resource type (see table below)
- `environment`: Environment identifier (dev, test, staging, prod)
- `instance`: Optional instance number or identifier for multiple instances

#### Resource Type Abbreviations

| Resource Type | Abbreviation | Example |
|---------------|--------------|---------|
| API Management | apim | phantomline-apim-dev |
| Function App | func | phantomline-func-prod |
| SignalR | signalr | phantomline-signalr-staging |
| Redis Cache | redis | phantomline-redis-dev |
| Key Vault | kv | phantomline-kv-prod |
| OpenAI | ai | phantomline-ai-dev |
| Container Registry | acr | phantomline-acr-prod |
| Storage Account | st | phantomlinestprod (no hyphens for storage accounts) |
| Container Instance | ci | phantomline-ci-dev-001 |
| SQL Server | sql | phantomline-sql-prod |
| SQL Database | sqldb | phantomline-sqldb-dev |

### Configuration File Naming

- Main configuration: `bicep.config.json`
- Environment-specific configurations: `bicep.config.{environment}.json`
- Custom configurations: `bicep.config.{purpose}.json`

## Best Practices

### Configuration Management

1. **Version Control**: Always store configuration files in version control.
2. **Environment Separation**: Use separate configuration files for different environments.
3. **Secrets Management**: Never store secrets in configuration files. Use Key Vault references instead.
4. **Validation**: Always validate configuration files against the schema before deployment.

### Feature Toggles

1. **Default to False**: New features should default to disabled (false).
2. **Gradual Rollout**: Enable features progressively across environments.
3. **Clean Up**: Remove feature toggles once a feature is fully adopted.

### Module Configuration

1. **Minimal Configuration**: Only specify the properties that differ from defaults.
2. **Consistent SKUs**: Use consistent SKUs across related resources.
3. **Capacity Planning**: Document capacity requirements for each environment.

### Security Best Practices

1. **Least Privilege**: Configure resources with the minimum required permissions.
2. **Network Security**: Use private endpoints and VNETs where possible.
3. **Key Rotation**: Implement regular key rotation for all secrets.
4. **Audit Logging**: Enable diagnostic settings and audit logs for all resources.

### Performance Best Practices

1. **Right-Sizing**: Choose appropriate SKUs based on workload requirements.
2. **Auto-Scaling**: Configure auto-scaling rules for variable workloads.
3. **Geo-Distribution**: Consider geo-redundant options for production environments.

### Cost Optimization

1. **Dev/Test Subscriptions**: Use dev/test subscriptions for non-production environments.
2. **Resource Scheduling**: Implement start/stop schedules for dev environments.
3. **Reserved Instances**: Consider reserved instances for stable production workloads.
4. **Cost Tags**: Use consistent tagging for cost allocation and tracking.

## Configuration File Structure

The configuration file should be structured in the following order:

1. `$schema`: Reference to the schema file
2. `metadata`: Project metadata and environment settings
3. `tags`: Resource tagging information
4. `featureToggles`: Feature toggle flags
5. `moduleConfigurations`: Module-specific configurations
6. `bicepSettings`: Bicep linter and formatting settings

## Validation Rules

1. All configuration files must validate against the schema.
2. Required fields must be provided for each enabled module.
3. Resource names must follow the naming convention.
4. SKUs must be appropriate for the environment.
