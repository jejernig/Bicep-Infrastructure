# GitHub Environments Setup Guide

This guide explains how to set up GitHub Environments with appropriate protection rules for the Bicep Infrastructure deployment pipeline.

## Overview

GitHub Environments provide a way to configure environment-specific protection rules and secrets. The deployment pipeline uses these environments to apply different approval requirements and deployment strategies based on the target environment.

## Required Environments

The deployment pipeline requires the following environments to be configured in your GitHub repository:

1. **dev** - Development environment
2. **qa** - QA/Testing environment
3. **prod** - Production environment

## Setting Up GitHub Environments

### Step 1: Navigate to Environment Settings

1. Go to your GitHub repository
2. Click on "Settings" tab
3. In the left sidebar, click on "Environments"
4. Click "New environment" button

### Step 2: Create Development Environment

1. Name: `dev`
2. Configure environment protection rules:
   - No required reviewers (for faster development iterations)
   - No wait timer
3. Add environment secrets:
   - `RESOURCE_GROUP_DEV`: The Azure resource group for development resources
   - Any other environment-specific secrets needed for deployment

### Step 3: Create QA Environment

1. Name: `qa`
2. Configure environment protection rules:
   - Required reviewers: 1 reviewer (add appropriate team members)
   - Wait timer: 0 minutes (optional)
3. Add environment secrets:
   - `RESOURCE_GROUP_QA`: The Azure resource group for QA resources
   - Any other environment-specific secrets needed for deployment

### Step 4: Create Production Environment

1. Name: `prod`
2. Configure environment protection rules:
   - Required reviewers: 2 reviewers (add appropriate team members)
   - Wait timer: 15 minutes (recommended)
   - Add deployment branches rule to restrict which branches can deploy to production (e.g., only `main` branch)
3. Add environment secrets:
   - `RESOURCE_GROUP_PROD`: The Azure resource group for production resources
   - Any other environment-specific secrets needed for deployment

## Repository Secrets

In addition to environment-specific secrets, the following repository secrets are required:

- `AZURE_CLIENT_ID`: Azure service principal client ID
- `AZURE_TENANT_ID`: Azure tenant ID
- `AZURE_SUBSCRIPTION_ID`: Azure subscription ID

## Environment Configuration Files

The deployment pipeline uses environment-specific configuration files located in the `config/environments/` directory:

- `dev.json`: Development environment configuration
- `qa.json`: QA environment configuration
- `prod.json`: Production environment configuration

These files contain environment-specific settings that are applied during deployment.

## Protection Rules Best Practices

- **Development**: Minimal restrictions for rapid iteration
- **QA**: Moderate restrictions to ensure quality
- **Production**: Strict restrictions to prevent accidental deployments
  - Require multiple approvals
  - Limit deployment branches
  - Add wait timers
  - Consider adding environment-specific deployment gates

## Deployment Workflow

The GitHub Actions workflow will automatically use the appropriate environment based on the `environment` input parameter. This ensures that the correct protection rules and secrets are applied for each deployment.
