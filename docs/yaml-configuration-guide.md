# YAML Configuration Guide for Bicep Infrastructure

## Introduction

This guide explains how to use YAML as the configuration format for Bicep Infrastructure deployments. YAML has been adopted as the primary configuration format due to its improved readability, AI-friendliness, and better support for comments and documentation.

## Why YAML?

YAML (YAML Ain't Markup Language) offers several advantages over JSON for infrastructure configuration:

1. **Better Readability**: YAML uses indentation for structure, making it more readable than JSON's bracket notation.
2. **Native Comment Support**: YAML allows inline and block comments, which JSON does not support natively.
3. **AI-Friendly**: YAML's structure is easier for AI models to understand and generate correctly.
4. **Reduced Syntax Noise**: No need for quotes around most strings, commas, or excessive brackets.
5. **Multi-line String Support**: YAML has built-in support for multi-line strings, which is useful for complex values.
6. **Compatible with JSON**: YAML is a superset of JSON, making migration straightforward.

## File Structure

The YAML configuration files follow the same structure as the previous JSON format:

```yaml
# Project metadata
metadata:
  projectName: myproject
  environment: dev
  location: eastus

# Resource tags
tags:
  environment: development
  project: bicep-infrastructure
  owner: infrastructure-team

# Feature toggles
featureToggles:
  enableApiManagement: true
  enableFunctionApp: true
  # Other feature toggles...

# Module configurations
moduleConfigurations:
  # Module-specific configurations
  appService:
    name: myapp
    sku: B1
    # Other app service settings...
  
  # Other modules...
```

## .NET Aspire Integration

The YAML configuration format includes support for .NET Aspire resources through the `aspire` section:

```yaml
# .NET Aspire configuration
aspire:
  containerApps:
    environment:
      name: aspire-env
      logAnalyticsWorkspaceName: aspire-logs
      zoneRedundant: false
    services:
      - name: api-service
        source:
          type: container
          image: myregistry/api:latest
        # Service configuration...
  
  registry:
    name: aspirecr
    sku: Standard
    
  monitoring:
    applicationInsights:
      name: aspire-insights
      samplingPercentage: 100
```

## Converting Between JSON and YAML

You can convert existing JSON configuration files to YAML using the included conversion script:

```bash
node infrastructure/scripts/convert-config.js --input=path/to/config.json --output=path/to/config.yaml
```

## Validation

Configuration files can be validated against the schema using the validation script:

```bash
node infrastructure/scripts/validate-config.js path/to/config.yaml
```

The script automatically detects whether the file is JSON or YAML based on the file extension.

## Sample Templates

Sample templates in YAML format are available in the `infrastructure/bicep/templates/` directory:

- `app-service-sample.yaml`: Sample configuration for App Service
- `function-app-sample.yaml`: Sample configuration for Function App
- `key-vault-sample.yaml`: Sample configuration for Key Vault
- `sql-database-sample.yaml`: Sample configuration for SQL Database
- `aspire-sample.yaml`: Sample configuration for .NET Aspire resources

## Best Practices

1. **Use Comments**: Add comments to explain complex configuration sections.
2. **Consistent Indentation**: Use 2 spaces for indentation.
3. **Group Related Settings**: Keep related settings together.
4. **Use Multi-line Strings**: For complex values, use YAML's multi-line string syntax.
5. **Validate Configurations**: Always validate your configuration files before deployment.

## Schema Reference

The full schema definition is available in `infrastructure/bicep/bicep.config.schema.yaml`.

## Migration Guide

If you're migrating from JSON to YAML, follow these steps:

1. Convert your existing JSON configuration files to YAML using the conversion script.
2. Update any references to configuration files in your deployment scripts.
3. Validate the converted YAML files against the schema.
4. Update your CI/CD pipelines to use the new YAML configuration files.

## Troubleshooting

Common issues when working with YAML configuration files:

- **Indentation Errors**: YAML is sensitive to indentation. Make sure your indentation is consistent.
- **Quote Issues**: While YAML doesn't require quotes for most strings, you should use quotes for strings that contain special characters or could be interpreted as numbers or booleans.
- **Multi-line Strings**: Use the `|` character for multi-line strings that preserve line breaks, or `>` for multi-line strings that fold line breaks.
