#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const { program } = require('commander');
const Ajv = require('ajv');

program
  .description('Validate APIM policy configurations')
  .option('-c, --config <path>', 'Path to the configuration file', './bicep.config.json')
  .option('-s, --schema <path>', 'Path to the schema file', './bicep.config.schema.json')
  .parse(process.argv);

const options = program.opts();

// Load configuration and schema
try {
  const configPath = path.resolve(process.cwd(), options.config);
  const schemaPath = path.resolve(process.cwd(), options.schema);
  
  console.log(`Validating policy configuration in ${configPath}`);
  console.log(`Using schema from ${schemaPath}`);
  
  const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
  const schema = JSON.parse(fs.readFileSync(schemaPath, 'utf8'));
  
  // Basic schema validation
  const ajv = new Ajv({ allErrors: true });
  const validate = ajv.compile(schema);
  const valid = validate(config);
  
  if (!valid) {
    console.error('Schema validation errors:');
    console.error(validate.errors);
    process.exit(1);
  }
  
  // Check if APIM is enabled
  if (!config.featureToggles?.enableApiManagement) {
    console.log('API Management is not enabled in this configuration. Skipping policy validation.');
    process.exit(0);
  }
  
  // Get APIM configuration
  const apimConfig = config.moduleConfigurations?.apiManagement;
  if (!apimConfig) {
    console.log('No API Management configuration found. Skipping policy validation.');
    process.exit(0);
  }
  
  // Validate policy XML syntax
  validatePolicyXml(apimConfig);
  
  // Validate policy references
  validatePolicyReferences(apimConfig);
  
  // Validate policy namespacing in shared mode
  if (apimConfig.operationalMode === 'shared') {
    validatePolicyNamespacing(apimConfig, config.metadata?.projectName);
  }
  
  console.log('✅ Policy configuration validation passed!');
  process.exit(0);
  
} catch (error) {
  console.error(`Error during validation: ${error.message}`);
  process.exit(1);
}

/**
 * Validate XML syntax in policy configurations
 */
function validatePolicyXml(apimConfig) {
  console.log('Validating policy XML syntax...');
  
  const errors = [];
  
  // Check global policy
  if (apimConfig.globalPolicy?.value) {
    if (!isValidPolicyXml(apimConfig.globalPolicy.value)) {
      errors.push('Invalid XML syntax in global policy');
    }
  }
  
  // Check product policies
  if (apimConfig.products) {
    apimConfig.products.forEach((product, index) => {
      if (product.policy?.value) {
        if (!isValidPolicyXml(product.policy.value)) {
          errors.push(`Invalid XML syntax in product policy for "${product.name}" (index: ${index})`);
        }
      }
    });
  }
  
  // Check API policies
  if (apimConfig.apis) {
    apimConfig.apis.forEach((api, index) => {
      if (api.policy?.value) {
        if (!isValidPolicyXml(api.policy.value)) {
          errors.push(`Invalid XML syntax in API policy for "${api.name}" (index: ${index})`);
        }
        
        // Check operation policies
        if (api.policy.operations) {
          api.policy.operations.forEach((operation, opIndex) => {
            if (!isValidPolicyXml(operation.value)) {
              errors.push(`Invalid XML syntax in operation policy "${operation.name}" for API "${api.name}" (index: ${index}.${opIndex})`);
            }
          });
        }
      }
    });
  }
  
  // Check policy fragments
  if (apimConfig.policyFragments) {
    apimConfig.policyFragments.forEach((fragment, index) => {
      if (!isValidPolicyXml(fragment.value)) {
        errors.push(`Invalid XML syntax in policy fragment "${fragment.name}" (index: ${index})`);
      }
    });
  }
  
  if (errors.length > 0) {
    console.error('❌ Policy XML validation failed:');
    errors.forEach(error => console.error(`  - ${error}`));
    process.exit(1);
  }
  
  console.log('✅ All policy XML syntax is valid');
}

/**
 * Validate policy references (named values, fragments)
 */
function validatePolicyReferences(apimConfig) {
  console.log('Validating policy references...');
  
  const errors = [];
  const namedValues = new Set();
  const policyFragments = new Set();
  
  // Collect defined named values
  if (apimConfig.namedValues) {
    apimConfig.namedValues.forEach(nv => namedValues.add(nv.name));
  }
  
  // Collect defined policy fragments
  if (apimConfig.policyFragments) {
    apimConfig.policyFragments.forEach(fragment => policyFragments.add(fragment.name));
  }
  
  // Helper function to check references in a policy
  function checkPolicyReferences(policyValue, context) {
    if (!policyValue) return;
    
    // Check for named value references
    const namedValueRefs = extractNamedValueReferences(policyValue);
    namedValueRefs.forEach(ref => {
      if (!namedValues.has(ref)) {
        errors.push(`${context}: References undefined named value "${ref}"`);
      }
    });
    
    // Check for policy fragment references
    const fragmentRefs = extractPolicyFragmentReferences(policyValue);
    fragmentRefs.forEach(ref => {
      if (!policyFragments.has(ref)) {
        errors.push(`${context}: References undefined policy fragment "${ref}"`);
      }
    });
  }
  
  // Check global policy
  if (apimConfig.globalPolicy?.value) {
    checkPolicyReferences(apimConfig.globalPolicy.value, 'Global policy');
  }
  
  // Check product policies
  if (apimConfig.products) {
    apimConfig.products.forEach(product => {
      if (product.policy?.value) {
        checkPolicyReferences(product.policy.value, `Product policy "${product.name}"`);
      }
    });
  }
  
  // Check API policies
  if (apimConfig.apis) {
    apimConfig.apis.forEach(api => {
      if (api.policy?.value) {
        checkPolicyReferences(api.policy.value, `API policy "${api.name}"`);
        
        // Check operation policies
        if (api.policy.operations) {
          api.policy.operations.forEach(operation => {
            checkPolicyReferences(operation.value, `Operation policy "${operation.name}" in API "${api.name}"`);
          });
        }
      }
    });
  }
  
  if (errors.length > 0) {
    console.error('❌ Policy reference validation failed:');
    errors.forEach(error => console.error(`  - ${error}`));
    process.exit(1);
  }
  
  console.log('✅ All policy references are valid');
}

/**
 * Validate policy namespacing in shared mode
 */
function validatePolicyNamespacing(apimConfig, projectName) {
  console.log('Validating policy namespacing for shared mode...');
  
  if (!projectName) {
    console.error('❌ Project name is required for policy namespacing validation in shared mode');
    process.exit(1);
  }
  
  const errors = [];
  
  // Check named values are properly namespaced
  if (apimConfig.namedValues) {
    apimConfig.namedValues.forEach(nv => {
      if (!nv.name.startsWith(`${projectName}-`)) {
        errors.push(`Named value "${nv.name}" is not properly namespaced with project prefix "${projectName}-"`);
      }
    });
  }
  
  // Check policy fragments are properly namespaced
  if (apimConfig.policyFragments) {
    apimConfig.policyFragments.forEach(fragment => {
      if (!fragment.name.startsWith(`${projectName}-`)) {
        errors.push(`Policy fragment "${fragment.name}" is not properly namespaced with project prefix "${projectName}-"`);
      }
    });
  }
  
  if (errors.length > 0) {
    console.error('❌ Policy namespacing validation failed:');
    errors.forEach(error => console.error(`  - ${error}`));
    process.exit(1);
  }
  
  console.log('✅ All policy elements are properly namespaced');
}

/**
 * Check if a string is valid XML policy syntax
 */
function isValidPolicyXml(xmlString) {
  // Basic check for well-formed XML
  try {
    if (!xmlString.includes('<policies>')) {
      return false;
    }
    
    // Check for balanced policy sections
    const sections = ['inbound', 'backend', 'outbound', 'on-error'];
    for (const section of sections) {
      const openCount = (xmlString.match(new RegExp(`<${section}>`, 'g')) || []).length;
      const closeCount = (xmlString.match(new RegExp(`</${section}>`, 'g')) || []).length;
      
      if (openCount !== closeCount) {
        return false;
      }
    }
    
    // Check for balanced base elements
    const baseCount = (xmlString.match(/<base\s*\/>/g) || []).length;
    const sectionCount = sections.reduce((count, section) => {
      return count + (xmlString.includes(`<${section}>`) ? 1 : 0);
    }, 0);
    
    if (baseCount > sectionCount) {
      return false;
    }
    
    return true;
  } catch (error) {
    return false;
  }
}

/**
 * Extract named value references from policy XML
 */
function extractNamedValueReferences(policyXml) {
  const references = new Set();
  const regex = /{{([^{}]+)}}/g;
  let match;
  
  while ((match = regex.exec(policyXml)) !== null) {
    references.add(match[1]);
  }
  
  return Array.from(references);
}

/**
 * Extract policy fragment references from policy XML
 */
function extractPolicyFragmentReferences(policyXml) {
  const references = new Set();
  const regex = /<include-fragment\s+fragment-id="([^"]+)"/g;
  let match;
  
  while ((match = regex.exec(policyXml)) !== null) {
    references.add(match[1]);
  }
  
  return Array.from(references);
}
