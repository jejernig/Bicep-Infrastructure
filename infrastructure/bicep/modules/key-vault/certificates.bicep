@description('Name of the Key Vault')
param keyVaultName string

@description('Array of certificates to create')
param certificates array = []

// Reference the Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

// Create certificates
resource keyVaultCertificates 'Microsoft.KeyVault/vaults/certificates@2022-07-01' = [for certificate in certificates: {
  name: '${keyVaultName}/${certificate.name}'
  properties: {
    certificatePolicy: {
      keyProperties: {
        exportable: contains(certificate, 'exportable') ? certificate.exportable : true
        keySize: contains(certificate, 'keySize') ? certificate.keySize : 2048
        keyType: contains(certificate, 'keyType') ? certificate.keyType : 'RSA'
        reuseKey: contains(certificate, 'reuseKey') ? certificate.reuseKey : false
      }
      secretProperties: {
        contentType: contains(certificate, 'contentType') ? certificate.contentType : 'application/x-pkcs12'
      }
      issuerParameters: {
        name: contains(certificate, 'issuerName') ? certificate.issuerName : 'Self'
      }
      x509CertificateProperties: {
        subject: contains(certificate, 'subject') ? certificate.subject : 'CN=example.com'
        validityInMonths: contains(certificate, 'validityInMonths') ? certificate.validityInMonths : 12
        subjectAlternativeNames: contains(certificate, 'subjectAlternativeNames') ? {
          dnsNames: certificate.subjectAlternativeNames
        } : null
      }
      lifetimeActions: [
        {
          trigger: {
            daysBeforeExpiry: contains(certificate, 'daysBeforeExpiry') ? certificate.daysBeforeExpiry : 30
          }
          action: {
            actionType: 'AutoRenew'
          }
        }
      ]
      attributes: {
        enabled: contains(certificate, 'enabled') ? certificate.enabled : true
      }
    }
  }
}]

// Outputs
output certificatesCount int = length(certificates)
output certificateNames array = [for (certificate, i) in certificates: certificate.name]
