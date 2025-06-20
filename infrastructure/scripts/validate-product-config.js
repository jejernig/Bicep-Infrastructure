#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const { program } = require('commander');

program
  .description('Validate product configurations in APIM to ensure they follow naming conventions and requirements')
  .option('-c, --config <path>', 'Path to bicep.config.json file', './infrastructure/bicep/bicep.config.json')
  .option('-m, --mode <mode>', 'APIM operational mode (shared or dedicated)', 'shared')
  .option('-o, --output <path>', 'Path to output validation report', './infrastructure/bicep/product-validation-report.json')
  .parse(process.argv);

const options = program.opts();

// Standard product types
const STANDARD_PRODUCT_TYPES = ['internal', 'public', 'partner', 'system', 'free'];

// Main validation function
async function validateProductConfig() {
  try {
    console.log('Validating product configurations...');
    
    // Read the configuration file
    const configPath = path.resolve(process.cwd(), options.config);
    if (!fs.existsSync(configPath)) {
      console.error(`Error: Configuration file not found at ${configPath}`);
      process.exit(1);
    }
    
    const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
    
    // Check if APIM is enabled
    if (!config.featureToggles?.enableApiManagement) {
      console.log('API Management is not enabled. No validation needed.');
      process.exit(0);
    }
    
    const apimConfig = config.moduleConfigurations?.apiManagement;
    if (!apimConfig) {
      console.log('API Management configuration not found. No validation needed.');
      process.exit(0);
    }
    
    // Get operational mode
    const isSharedMode = options.mode === 'shared' || 
      (apimConfig.operationalMode === 'shared');
    
    // Extract project name and products
    const projectName = config.metadata?.projectName;
    if (!projectName) {
      console.error('Error: Project name not found in configuration.');
      process.exit(1);
    }
    
    const products = apimConfig.products || [];
    if (products.length === 0) {
      console.log('No products defined in configuration. Nothing to validate.');
      process.exit(0);
    }
    
    // Validate each product
    const validationResults = {
      projectName,
      timestamp: new Date().toISOString(),
      mode: isSharedMode ? 'shared' : 'dedicated',
      validationPassed: true,
      issues: []
    };
    
    // Check for duplicate product names
    const productNames = products.map(product => product.name);
    const duplicateNames = findDuplicates(productNames);
    
    if (duplicateNames.length > 0) {
      validationResults.validationPassed = false;
      validationResults.issues.push({
        type: 'duplicate_product_names',
        message: `Duplicate product names found: ${duplicateNames.join(', ')}`,
        severity: 'error'
      });
    }
    
    // Validate each product
    for (const product of products) {
      // Check for required properties
      if (!product.name) {
        validationResults.validationPassed = false;
        validationResults.issues.push({
          type: 'missing_required_property',
          message: 'Product is missing required "name" property',
          severity: 'error',
          product: product
        });
        continue;
      }
      
      // Check naming conventions in shared mode
      if (isSharedMode) {
        if (!product.name.startsWith(`${projectName}-`)) {
          validationResults.validationPassed = false;
          validationResults.issues.push({
            type: 'invalid_naming_convention',
            message: `Product name "${product.name}" does not follow the naming convention "{projectName}-{productType}" in shared mode`,
            severity: 'error',
            productName: product.name
          });
        }
        
        // Extract product type from name
        const productType = product.name.substring(projectName.length + 1);
        if (!STANDARD_PRODUCT_TYPES.includes(productType)) {
          validationResults.issues.push({
            type: 'non_standard_product_type',
            message: `Product type "${productType}" is not one of the standard types: ${STANDARD_PRODUCT_TYPES.join(', ')}`,
            severity: 'warning',
            productName: product.name,
            productType: productType
          });
        }
      }
      
      // Check for display name
      if (!product.displayName) {
        validationResults.issues.push({
          type: 'missing_display_name',
          message: `Product "${product.name}" is missing a display name`,
          severity: 'warning',
          productName: product.name
        });
      }
      
      // Check for description
      if (!product.description) {
        validationResults.issues.push({
          type: 'missing_description',
          message: `Product "${product.name}" is missing a description`,
          severity: 'warning',
          productName: product.name
        });
      }
      
      // Check subscription settings
      if (product.subscriptionSettings) {
        // Validate that if subscriptionRequired is false, approvalRequired should also be false
        if (product.subscriptionSettings.subscriptionRequired === false && 
            product.subscriptionSettings.approvalRequired === true) {
          validationResults.validationPassed = false;
          validationResults.issues.push({
            type: 'invalid_subscription_settings',
            message: `Product "${product.name}" has approvalRequired=true but subscriptionRequired=false, which is invalid`,
            severity: 'error',
            productName: product.name
          });
        }
      }
    }
    
    // Check for API associations
    const apis = apimConfig.apis || [];
    const apiProductNames = apis
      .filter(api => api.productName)
      .map(api => api.productName);
    
    // Find product names referenced by APIs that don't exist in products
    const missingProducts = apiProductNames.filter(name => !productNames.includes(name));
    if (missingProducts.length > 0) {
      validationResults.validationPassed = false;
      validationResults.issues.push({
        type: 'missing_referenced_products',
        message: `APIs reference products that don't exist: ${missingProducts.join(', ')}`,
        severity: 'error',
        missingProducts: missingProducts
      });
    }
    
    // Write validation report
    const outputPath = path.resolve(process.cwd(), options.output);
    fs.writeFileSync(outputPath, JSON.stringify(validationResults, null, 2));
    
    if (validationResults.validationPassed) {
      console.log('Validation passed! Product configurations are valid.');
      console.log(`Report written to ${outputPath}`);
      process.exit(0);
    } else {
      console.error('Validation failed! Product configuration issues found:');
      validationResults.issues
        .filter(issue => issue.severity === 'error')
        .forEach(issue => {
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
validateProductConfig();
