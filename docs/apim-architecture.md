# API Management Integration Architecture

This document outlines the architecture for integrating with Azure API Management (APIM) in both shared and dedicated operational modes.

## Operational Modes

The APIM integration module supports two operational modes:

### 1. Shared Mode

In shared mode, multiple projects register their APIs within a single, centralized API Management instance. This approach optimizes costs and centralizes management but requires careful namespace isolation.

**Key characteristics:**
- Uses an existing APIM instance (referenced by resource ID)
- APIs are organized under project-specific namespaces
- Path structure follows: `{projectName}/{apiVersion}/{apiPath}`
- Products can be project-specific or shared across projects
- Policies can be applied at multiple scopes (global, product, API, operation)

**When to use:**
- Enterprise environments with multiple projects/teams
- Cost optimization is a priority
- Centralized API governance is desired
- Cross-project API discovery is beneficial

### 2. Dedicated Mode

In dedicated mode, each project gets its own APIM instance. This provides maximum isolation and control but at a higher cost.

**Key characteristics:**
- Creates a new APIM instance for the project
- Complete control over all APIM settings and policies
- No namespace conflicts to manage
- Higher cost due to dedicated infrastructure
- Simplified path structure: `{apiPath}`

**When to use:**
- Projects with unique compliance requirements
- Teams needing full control over APIM configuration
- Scenarios where isolation is more important than cost
- Development or testing environments

## Resource Group Structure

### Shared Mode
- APIM instance lives in a central/shared resource group
- Project resources reference the shared APIM via resource ID
- Project-specific resources (Function Apps, etc.) remain in project resource groups

### Dedicated Mode
- APIM instance is deployed in the same resource group as other project resources
- All API-related resources are contained within the project's resource group

## Naming Conventions

### APIs
- Shared mode: `{projectName}-{apiName}`
- Dedicated mode: `{apiName}`

### Products
- Shared mode: `{projectName}-{productName}`
- Dedicated mode: `{productName}`

### Policies
- Shared mode: `{projectName}-{policyName}`
- Dedicated mode: `{policyName}`

## Isolation Patterns

### Namespace Isolation
- In shared mode, all APIs are isolated by the `{projectName}` prefix in the URL path
- Each project's APIs are contained within their own URL namespace

### Product Isolation
- APIs can be grouped into products that control visibility and access
- Subscription keys are scoped to products, providing access control

### Policy Isolation
- Global policies apply to all APIs
- Product policies apply only to APIs within that product
- API-level policies provide fine-grained control

## Decision Criteria

Consider the following factors when choosing between shared and dedicated modes:

| Factor | Shared Mode | Dedicated Mode |
|--------|------------|---------------|
| Cost | Lower (shared infrastructure) | Higher (dedicated infrastructure) |
| Isolation | Logical isolation only | Complete physical isolation |
| Control | Limited to API/product scope | Complete control of APIM instance |
| Governance | Centralized | Project-specific |
| Operations | Shared responsibility | Project team responsibility |
| Scalability | Dependent on shared instance | Independent scaling |

## Implementation Details

The `apim-integration.bicep` module implements this architecture by:

1. Supporting both operational modes via the `apimMode` parameter
2. Referencing existing APIM instances in shared mode
3. Creating new APIM instances in dedicated mode
4. Implementing proper path namespacing in shared mode
5. Supporting product creation and API association
6. Providing consistent outputs regardless of mode

## Integration with main.bicep

The main orchestrator integrates with this module by:

1. Reading APIM configuration from `bicep.config.json`
2. Determining the operational mode based on configuration
3. Passing the appropriate parameters to the APIM integration module
4. Managing dependencies between APIM and other resources
5. Exposing relevant APIM endpoints and information as outputs
