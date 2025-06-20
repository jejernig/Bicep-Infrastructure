#!/usr/bin/env node

/**
 * Bicep Configuration Validator
 * 
 * This script validates bicep configuration files (JSON or YAML) against their schema.
 * Usage: node validate-config.js <path-to-config-file>
 */

const fs = require('fs');
const path = require('path');
const Ajv = require('ajv');
const addFormats = require('ajv-formats');
const yaml = require('js-yaml');

// Parse command line arguments
const configPath = process.argv[2];
if (!configPath) {
  console.error('Error: Configuration file path is required');
  console.error('Usage: node validate-config.js <path-to-config-file>');
  process.exit(1);
}

// Resolve paths
const resolvedConfigPath = path.resolve(process.cwd(), configPath);
const fileExtension = path.extname(resolvedConfigPath).toLowerCase();

// Determine schema path based on file extension
let schemaPath;
if (fileExtension === '.yaml' || fileExtension === '.yml') {
  schemaPath = path.resolve(
    path.dirname(resolvedConfigPath),
    '../bicep/bicep.config.schema.yaml'
  );
} else {
  // Default to JSON schema for .json or any other extension
  schemaPath = path.resolve(
    path.dirname(resolvedConfigPath),
    '../bicep/bicep.config.schema.json'
  );
}

// Check if files exist
if (!fs.existsSync(resolvedConfigPath)) {
  console.error(`Error: Configuration file not found: ${resolvedConfigPath}`);
  process.exit(1);
}

if (!fs.existsSync(schemaPath)) {
  console.error(`Error: Schema file not found: ${schemaPath}`);
  process.exit(1);
}

// Read files
let config;
let schema;
const configContent = fs.readFileSync(resolvedConfigPath, 'utf8');
const schemaContent = fs.readFileSync(schemaPath, 'utf8');

// Parse configuration file based on extension
try {
  if (fileExtension === '.yaml' || fileExtension === '.yml') {
    config = yaml.load(configContent);
  } else {
    config = JSON.parse(configContent);
  }
} catch (error) {
  console.error(`Error parsing configuration file: ${error.message}`);
  process.exit(1);
}

// Parse schema file based on extension
try {
  if (path.extname(schemaPath).toLowerCase() === '.yaml' || 
      path.extname(schemaPath).toLowerCase() === '.yml') {
    schema = yaml.load(schemaContent);
    
    // Convert YAML schema to JSON Schema format for AJV
    schema = convertYamlSchemaToJsonSchema(schema);
  } else {
    schema = JSON.parse(schemaContent);
  }
} catch (error) {
  console.error(`Error parsing schema file: ${error.message}`);
  process.exit(1);
}

// Set up validator
const ajv = new Ajv({ allErrors: true });
addFormats(ajv);
const validate = ajv.compile(schema);

// Validate configuration
const valid = validate(config);

if (valid) {
  console.log('✅ Configuration is valid');
  process.exit(0);
} else {
  console.error('❌ Configuration validation failed:');
  
  // Format and display validation errors
  validate.errors.forEach((error, index) => {
    const path = error.instancePath || '(root)';
    const message = error.message;
    const params = error.params ? JSON.stringify(error.params) : '';
    
    console.error(`Error ${index + 1}: ${path} ${message} ${params}`);
  });
  
  process.exit(1);
}

/**
 * Converts a YAML schema to JSON Schema format
 * This is needed because our YAML schema uses a slightly different format
 * than what AJV expects for JSON Schema validation
 */
function convertYamlSchemaToJsonSchema(yamlSchema) {
  const jsonSchema = {
    $schema: "http://json-schema.org/draft-07/schema#",
    title: "Bicep Configuration Schema",
    description: "Schema for bicep.config.yaml that drives infrastructure deployment",
    type: "object",
    required: ["metadata"],
    properties: {}
  };
  
  // Convert each top-level property
  for (const [key, value] of Object.entries(yamlSchema)) {
    if (typeof value === 'object' && value !== null) {
      jsonSchema.properties[key] = convertSchemaNode(value);
    }
  }
  
  return jsonSchema;
}

/**
 * Recursively converts a schema node from YAML format to JSON Schema format
 */
function convertSchemaNode(node) {
  if (typeof node !== 'object' || node === null) {
    return node;
  }
  
  const result = {};
  
  // Copy all properties
  for (const [key, value] of Object.entries(node)) {
    if (key === 'properties' && typeof value === 'object') {
      // Handle properties object
      result[key] = {};
      for (const [propKey, propValue] of Object.entries(value)) {
        result[key][propKey] = convertSchemaNode(propValue);
      }
    } else if (key === 'items' && typeof value === 'object') {
      // Handle array items
      result[key] = convertSchemaNode(value);
    } else if (typeof value === 'object' && value !== null && !Array.isArray(value)) {
      // Recursively convert nested objects
      result[key] = convertSchemaNode(value);
    } else {
      // Copy primitive values and arrays as is
      result[key] = value;
    }
  }
  
  return result;
}
