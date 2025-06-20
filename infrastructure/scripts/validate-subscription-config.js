#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const Ajv = require('ajv');
const addFormats = require('ajv-formats');

// Initialize Ajv
const ajv = new Ajv({ allErrors: true, verbose: true });
addFormats(ajv);

// Parse command line arguments
const args = process.argv.slice(2);
let configFile = null;
let schemaFile = null;

for (let i = 0; i < args.length; i++) {
  if (args[i] === '--config' || args[i] === '-c') {
    configFile = args[i + 1];
    i++;
  } else if (args[i] === '--schema' || args[i] === '-s') {
    schemaFile = args[i + 1];
    i++;
  } else if (args[i] === '--help' || args[i] === '-h') {
    printHelp();
    process.exit(0);
  }
}

// Default values
if (!configFile) {
  configFile = path.join(process.cwd(), 'infrastructure', 'bicep', 'templates', 'subscription-management-sample.json');
}

if (!schemaFile) {
  schemaFile = path.join(process.cwd(), 'infrastructure', 'bicep', 'subscription-config.schema.json');
}

// Create schema if it doesn't exist
if (!fs.existsSync(schemaFile)) {
  console.log(`Schema file not found at ${schemaFile}. Creating default schema...`);
  createDefaultSchema(schemaFile);
}

// Validate the configuration
try {
  const schema = JSON.parse(fs.readFileSync(schemaFile, 'utf8'));
  const config = JSON.parse(fs.readFileSync(configFile, 'utf8'));
  
  // Validate against schema
  const validate = ajv.compile(schema);
  const valid = validate(config);
  
  if (!valid) {
    console.error('❌ Configuration validation failed:');
    console.error(JSON.stringify(validate.errors, null, 2));
    process.exit(1);
  }
  
  // Additional validation logic
  validateSubscriptionConfig(config);
  
  console.log('✅ Configuration validation successful!');
  process.exit(0);
} catch (error) {
  console.error(`❌ Error during validation: ${error.message}`);
  process.exit(1);
}

// Function to create default schema
function createDefaultSchema(filePath) {
  const schema = {
    "$schema": "http://json-schema.org/draft-07/schema#",
    "type": "object",
    "properties": {
      "$schema": { "type": "string" },
      "contentVersion": { "type": "string" },
      "parameters": {
        "type": "object",
        "properties": {
          "projectName": {
            "type": "object",
            "properties": {
              "value": { "type": "string" }
            },
            "required": ["value"]
          },
          "environment": {
            "type": "object",
            "properties": {
              "value": { "type": "string", "enum": ["dev", "test", "staging", "prod"] }
            },
            "required": ["value"]
          },
          "subscriptions": {
            "type": "object",
            "properties": {
              "value": {
                "type": "array",
                "items": {
                  "type": "object",
                  "properties": {
                    "name": { "type": "string" },
                    "displayName": { "type": "string" },
                    "productName": { "type": "string" },
                    "state": { "type": "string", "enum": ["active", "suspended", "submitted", "rejected", "cancelled", "expired"] },
                    "allowTracing": { "type": "boolean" },
                    "policy": {
                      "type": "object",
                      "properties": {
                        "format": { "type": "string", "enum": ["xml", "rawxml"] },
                        "value": { "type": "string" }
                      },
                      "required": ["format", "value"]
                    }
                  },
                  "required": ["name"]
                }
              }
            }
          },
          "approvalWorkflow": {
            "type": "object",
            "properties": {
              "value": {
                "type": "object",
                "properties": {
                  "notificationEmails": {
                    "type": "array",
                    "items": { "type": "string", "format": "email" }
                  },
                  "expirationEmails": {
                    "type": "array",
                    "items": { "type": "string", "format": "email" }
                  },
                  "webhookUrl": { "type": "string", "format": "uri" },
                  "webhookCredential": { "type": "string" }
                }
              }
            }
          },
          "quotas": {
            "type": "object",
            "properties": {
              "value": {
                "type": "array",
                "items": {
                  "type": "object",
                  "properties": {
                    "name": { "type": "string" },
                    "description": { "type": "string" },
                    "calls": { "type": "integer", "minimum": 1 },
                    "renewalPeriod": { "type": "string" },
                    "rateLimit": {
                      "type": "object",
                      "properties": {
                        "calls": { "type": "integer", "minimum": 1 },
                        "renewalPeriod": { "type": "string" }
                      },
                      "required": ["calls", "renewalPeriod"]
                    },
                    "spikeArrest": {
                      "type": "object",
                      "properties": {
                        "calls": { "type": "integer", "minimum": 1 },
                        "renewalPeriod": { "type": "string" }
                      },
                      "required": ["calls", "renewalPeriod"]
                    },
                    "quotaByKey": {
                      "type": "object",
                      "properties": {
                        "calls": { "type": "integer", "minimum": 1 },
                        "renewalPeriod": { "type": "string" },
                        "headerName": { "type": "string" }
                      },
                      "required": ["calls", "renewalPeriod", "headerName"]
                    }
                  },
                  "required": ["name", "calls", "renewalPeriod"]
                }
              }
            }
          },
          "usageTracking": {
            "type": "object",
            "properties": {
              "value": {
                "type": "object",
                "properties": {
                  "applicationInsightsId": { "type": "string" },
                  "applicationInsightsKey": { "type": "string" },
                  "apis": {
                    "type": "array",
                    "items": {
                      "type": "object",
                      "properties": {
                        "name": { "type": "string" },
                        "alwaysLog": { "type": "string" },
                        "logClientIp": { "type": "boolean" },
                        "samplingPercentage": { "type": "integer", "minimum": 0, "maximum": 100 },
                        "verbosity": { "type": "string", "enum": ["error", "information", "verbose"] },
                        "requestHeaders": {
                          "type": "array",
                          "items": { "type": "string" }
                        },
                        "responseHeaders": {
                          "type": "array",
                          "items": { "type": "string" }
                        }
                      },
                      "required": ["name"]
                    }
                  }
                }
              }
            }
          },
          "lifecycleConfig": {
            "type": "object",
            "properties": {
              "value": {
                "type": "object",
                "properties": {
                  "expirationHandling": { "type": "boolean" },
                  "renewalNotification": {
                    "type": "object",
                    "properties": {
                      "daysBeforeExpiration": { "type": "integer", "minimum": 1 }
                    },
                    "required": ["daysBeforeExpiration"]
                  },
                  "gracePeriod": {
                    "type": "object",
                    "properties": {
                      "days": { "type": "integer", "minimum": 1 }
                    },
                    "required": ["days"]
                  },
                  "revocationHandling": { "type": "boolean" }
                }
              }
            }
          },
          "notificationConfig": {
            "type": "object",
            "properties": {
              "value": {
                "type": "object",
                "properties": {
                  "creationEmails": {
                    "type": "array",
                    "items": { "type": "string", "format": "email" }
                  },
                  "cancellationEmails": {
                    "type": "array",
                    "items": { "type": "string", "format": "email" }
                  },
                  "quotaEmails": {
                    "type": "array",
                    "items": { "type": "string", "format": "email" }
                  },
                  "webhookUrl": { "type": "string", "format": "uri" },
                  "webhookCredential": { "type": "string" }
                }
              }
            }
          }
        }
      }
    }
  };
  
  fs.writeFileSync(filePath, JSON.stringify(schema, null, 2));
  console.log(`Created default schema at ${filePath}`);
}

// Function to validate subscription configuration
function validateSubscriptionConfig(config) {
  const params = config.parameters;
  
  // Check if project name is provided
  if (!params.projectName || !params.projectName.value) {
    throw new Error('Project name is required');
  }
  
  // Validate subscriptions
  if (params.subscriptions && params.subscriptions.value) {
    const subscriptions = params.subscriptions.value;
    
    // Check for duplicate subscription names
    const subscriptionNames = new Set();
    for (const sub of subscriptions) {
      if (subscriptionNames.has(sub.name)) {
        throw new Error(`Duplicate subscription name found: ${sub.name}`);
      }
      subscriptionNames.add(sub.name);
    }
    
    // Validate subscription policies
    for (const sub of subscriptions) {
      if (sub.policy) {
        if (sub.policy.format === 'xml' && !isValidXml(sub.policy.value)) {
          throw new Error(`Invalid XML policy for subscription: ${sub.name}`);
        }
      }
    }
  }
  
  // Validate quotas
  if (params.quotas && params.quotas.value) {
    const quotas = params.quotas.value;
    
    // Check for duplicate quota names
    const quotaNames = new Set();
    for (const quota of quotas) {
      if (quotaNames.has(quota.name)) {
        throw new Error(`Duplicate quota name found: ${quota.name}`);
      }
      quotaNames.add(quota.name);
      
      // Validate renewal periods
      if (!isValidRenewalPeriod(quota.renewalPeriod)) {
        throw new Error(`Invalid renewal period for quota: ${quota.name}`);
      }
      
      if (quota.rateLimit && !isValidRenewalPeriod(quota.rateLimit.renewalPeriod)) {
        throw new Error(`Invalid rate limit renewal period for quota: ${quota.name}`);
      }
    }
  }
  
  // Validate usage tracking
  if (params.usageTracking && params.usageTracking.value) {
    const tracking = params.usageTracking.value;
    
    // Check if Application Insights ID is provided when APIs are configured
    if (tracking.apis && tracking.apis.length > 0 && !tracking.applicationInsightsId) {
      throw new Error('Application Insights ID is required when APIs are configured for usage tracking');
    }
    
    // Check for duplicate API names
    if (tracking.apis) {
      const apiNames = new Set();
      for (const api of tracking.apis) {
        if (apiNames.has(api.name)) {
          throw new Error(`Duplicate API name found in usage tracking: ${api.name}`);
        }
        apiNames.add(api.name);
      }
    }
  }
  
  console.log('Additional validation checks passed');
}

// Helper function to check if a string is valid XML
function isValidXml(xml) {
  try {
    // Simple XML validation - check for balanced tags
    const stack = [];
    let inTag = false;
    let inClosingTag = false;
    let tagName = '';
    
    for (let i = 0; i < xml.length; i++) {
      const char = xml[i];
      
      if (char === '<') {
        inTag = true;
        tagName = '';
        if (xml[i + 1] === '/') {
          inClosingTag = true;
          i++;
        }
      } else if (char === '>') {
        if (inTag) {
          if (!inClosingTag) {
            if (tagName !== '' && !tagName.includes(' ') && xml[i - 1] !== '/') {
              stack.push(tagName);
            }
          } else {
            if (stack.length === 0 || stack.pop() !== tagName) {
              return false;
            }
            inClosingTag = false;
          }
          inTag = false;
        }
      } else if (inTag && !char.match(/\s/)) {
        tagName += char;
      }
    }
    
    return stack.length === 0;
  } catch (e) {
    return false;
  }
}

// Helper function to check if a renewal period is valid
function isValidRenewalPeriod(period) {
  // Renewal period should be a positive integer representing seconds
  return /^\d+$/.test(period) && parseInt(period) > 0;
}

// Function to print help
function printHelp() {
  console.log(`
Subscription Configuration Validator

Usage:
  node validate-subscription-config.js [options]

Options:
  --config, -c <path>    Path to the subscription configuration file
  --schema, -s <path>    Path to the JSON schema file
  --help, -h             Show this help message

Examples:
  node validate-subscription-config.js
  node validate-subscription-config.js -c ./my-config.json
  node validate-subscription-config.js -c ./my-config.json -s ./my-schema.json
  `);
}
