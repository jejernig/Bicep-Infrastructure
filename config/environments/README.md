# Environment-Specific Configuration

This directory contains environment-specific configuration files used by the GitHub Actions deployment pipeline.

## Available Environments

- **dev.json**: Development environment configuration
- **qa.json**: QA/Testing environment configuration
- **prod.json**: Production environment configuration

## Configuration Structure

Each environment configuration file follows this structure:

```json
{
  "environment": "environment-name",
  "deploymentSettings": {
    "enableResourceLocks": boolean,
    "enableDiagnostics": boolean,
    "enableAutomatedBackups": boolean,
    "resourceTags": {
      "TagKey": "TagValue"
    }
  },
  "approvalRequirements": {
    "requiredApprovers": number,
    "timeoutMinutes": number
  },
  "alertSettings": {
    "notificationEmails": ["email@example.com"],
    "alertThresholds": {
      "cpuThreshold": number,
      "memoryThreshold": number,
      "storageThreshold": number
    }
  }
}
```

## Usage in Deployment Pipeline

These configuration files are used by the GitHub Actions deployment pipeline to apply environment-specific settings during infrastructure deployment. The appropriate file is selected based on the `environment` input parameter in the workflow.

## Adding a New Environment

To add a new environment:

1. Create a new JSON file named `{environment-name}.json` in this directory
2. Follow the configuration structure above
3. Configure appropriate settings for the new environment
4. Update the GitHub Actions workflow to include the new environment in the `environment` input options

## Environment Protection Rules

- **Production**: Requires approval from at least 2 reviewers
- **QA**: Requires approval from at least 1 reviewer
- **Dev**: No approval required

These protection rules should be configured in the GitHub repository settings under "Environments".
