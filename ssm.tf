resource "aws_ssm_document" "domain_join" {
  name          = "ad-domain-join"
  document_type = "Command"
  content = jsonencode(
    {
      "schemaVersion" : "1.0",
      "description" : "Configuration to join an instance to a domain",
      "runtimeConfig" : {
        "aws:domainJoin" : {
          "properties" : [{
            "directoryId" : aws_directory_service_directory.connector.id,
            "directoryName" : "ekant.com",
            "directoryOU" : "OU=PRD,OU=EKANT Servers,DC=cloud,DC=ekant,DC=com",
            "dnsIpAddresses" : [
              "x.x.x.x", # DNS IP Address add here
              "x.x.x.x"  # DNS IP Address add here
            ]
          }]
        }
      }
    }
  )
}

resource "aws_ssm_document" "domain_unjoin" {
  name          = "ad-domain-unjoin"
  document_type = "Automation"
  content = jsonencode(
    {
      "description" : "Automation document to remove the server from AD",
      "schemaVersion" : "0.3",
      "assumeRole" : aws_iam_role.ssm.arn,
      "parameters" : {
        "terminatingId" : {
          "type" : "String"
        }
      },
      "mainSteps" : [
        {
          "name" : "RunCommand",
          "action" : "aws:runCommand",
          "inputs" : {
            "DocumentName" : "AWS-RunPowerShellScript",
            "InstanceIds" : [
              "{{terminatingId}}"
            ],
            "Parameters" : {
              "commands" : [
                "Install-WindowsFeature RSAT-AD-PowerShell",
                "Import-Module AWSPowerShell",
                "$domain = 'ekant.com'",
                "$Secret = (Get-SECSecretValue -SecretId '${data.aws_secretsmanager_secret.adunjoin.arn}').SecretString",
                "$Json = $Secret | ConvertFrom-Json",
                "$username = $Json.username",
                "$password = $Json.password | ConvertTo-SecureString -asPlainText -Force",
                "$credential = New-Object System.Management.Automation.PSCredential($username,$password)",
                "$Computers = Get-ADComputer -Filter {(Enabled -eq $False)} -SearchBase 'OU=prd,OU=test Servers,DC=cloud,DC=ekant,DC=com' -Credential $credential | Select-Object Name, LastLogonDate, Enabled, DistinguishedName",
                "ForEach ($Item in $Computers){",
                " Remove-ADComputer -Identity $Item.DistinguishedName -Credential $credential -Confirm:$false",
                " Write-Output $($Item.Name) - Deleted",
                "}",
                "Remove-Computer -UnjoinDomaincredential $credential -PassThru -Restart -Force"
              ]
            }
          }
        }
      ]
    }
  )
}
