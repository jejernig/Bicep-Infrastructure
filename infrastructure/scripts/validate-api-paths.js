#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const { program } = require('commander');

program
  .description('Validate API paths in shared APIM mode to prevent conflicts')
  .option('-c, --config <path>', 'Path to bicep.config.json file', './infrastructure/bicep/bicep.config.json')
  .option('-m, --mode <mode>', 'APIM operational mode (shared or dedicated)', 'shared')
  .option('-o, --output <path>', 'Path to output validation report', './infrastructure/bicep/validation-report.json')
  .parse(process.argv);

const options = program.opts();

// Main validation function
async function validateApiPaths() {
  try {
    console.log('Validating API paths for conflicts...');
    
    // Read the configuration file
    const configPath = path.resolve(process.cwd(), options.config);
    if (!fs.existsSync(configPath)) {
      console.error(`Error: Configuration file not found at ${configPath}`);
      process.exit(1);
    }
    
    const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
    
    // Check if APIM is enabled and in shared mode
    if (!config.featureToggles?.enableApiManagement) {
      console.log('API Management is not enabled. No validation needed.');
      process.exit(0);
    }
    
    const apimConfig = config.moduleConfigurations?.apiManagement;
    if (!apimConfig) {
      console.log('API Management configuration not found. No validation needed.');
      process.exit(0);
    }
    
    // Only validate in shared mode
    const isSharedMode = options.mode === 'shared' || 
      (apimConfig.operationalMode === 'shared');
    
    if (!isSharedMode) {
      console.log('API Management is in dedicated mode. No path conflict validation needed.');
      process.exit(0);
    }
    
    // Extract project name and APIs
    const projectName = config.metadata?.projectName;
    if (!projectName) {
      console.error('Error: Project name not found in configuration.');
      process.exit(1);
    }
    
    const apis = apimConfig.apis || [];
    if (apis.length === 0) {
      console.log('No APIs defined in configuration. Nothing to validate.');
      process.exit(0);
    }
    
    // Validate each API path
    const validationResults = {
      projectName,
      timestamp: new Date().toISOString(),
      mode: 'shared',
      validationPassed: true,
      issues: []
    };
    
    // Check for duplicate API names within the project
    const apiNames = apis.map(api => api.name);
    const duplicateNames = findDuplicates(apiNames);
    
    if (duplicateNames.length > 0) {
      validationResults.validationPassed = false;
      validationResults.issues.push({
        type: 'duplicate_api_names',
        message: `Duplicate API names found within the project: ${duplicateNames.join(', ')}`,
        severity: 'error'
      });
    }
    
    // Check for invalid path formats
    for (const api of apis) {
      if (!api.path) {
        validationResults.validationPassed = false;
        validationResults.issues.push({
          type: 'missing_path',
          message: `API '${api.name}' is missing a path`,
          severity: 'error',
          apiName: api.name
        });
        continue;
      }
      
      if (api.path.startsWith('/')) {
        validationResults.validationPassed = false;
        validationResults.issues.push({
          type: 'invalid_path_format',
          message: `API '${api.name}' has a path that starts with a slash: ${api.path}`,
          severity: 'error',
          apiName: api.name,
          path: api.path
        });
      }
      
      // Check for path segments that could conflict with other projects
      if (api.path.includes('/')) {
        const segments = api.path.split('/');
        if (segments[0] !== projectName) {
          validationResults.issues.push({
            type: 'path_namespace_warning',
            message: `API '${api.name}' path does not start with project name: ${api.path}`,
            severity: 'warning',
            apiName: api.name,
            path: api.path
          });
        }
      }
    }
    
    // Write validation report
    const outputPath = path.resolve(process.cwd(), options.output);
    fs.writeFileSync(outputPath, JSON.stringify(validationResults, null, 2));
    
    if (validationResults.validationPassed) {
      console.log('Validation passed! No API path conflicts found.');
      console.log(`Report written to ${outputPath}`);
      process.exit(0);
    } else {
      console.error('Validation failed! API path conflicts or issues found:');
      validationResults.issues.forEach(issue => {
        console.error(`- [${issue.severity.toUpperCase()}] ${issue.message}`);
      });
      console.error(`Full report written to ${outputPath}`);
      process.exit(1);
    }
  } catch (error) {
    console.error('Error during validation:', error);
    process.exit(1);
  }
}

// Helper function to find duplicates in an array
function findDuplicates(array) {
  const seen = {};
  const duplicates = [];
  
  for (const item of array) {
    if (seen[item]) {
      if (!duplicates.includes(item)) {
        duplicates.push(item);
      }
    } else {
      seen[item] = true;
    }
  }
  
  return duplicates;
}

// Run the validation
validateApiPaths();
