$ErrorActionPreference = 'Continue'
Set-Location C:\Data2AI-Labs\data-platform

Write-Output "=== M07: Reset Lab ==="
& .\scripts\Reset-Lab.ps1 -LearnerPrefix APP01 -Lab M07 2>&1

Write-Output ""
Write-Output "=== M07: Create azure-pipelines.yml ==="
$pipelineYaml = @'
# Azure DevOps pipeline for Terraform CI/CD
# This pipeline validates, plans, applies and audits Terraform changes.
#
# In a real project, this file would live at the repository root.
# For this lab, we create it in labs/m07-cicd-pipeline/ to keep it self-contained.

trigger:
  branches:
    include:
      - main

pr:
  branches:
    include:
      - main

pool:
  vmImage: 'ubuntu-latest'

variables:
  - group: data-platform-secrets
  - name: TF_VERSION
    value: '1.14.5'

stages:
  - stage: Validate
    jobs:
      - job: Validate
        steps:
          - task: TerraformInstaller@1
            displayName: 'Install Terraform'
            inputs:
              terraformVersion: '$(TF_VERSION)'

          - script: |
              cd labs/m06-dynamic-logic
              terraform fmt -check -recursive
            displayName: 'terraform fmt -check'

          - script: |
              cd labs/m06-dynamic-logic
              terraform init -backend=false
              terraform validate
            displayName: 'terraform validate'

          - script: |
              sudo apt-get update && sudo apt-get install -y tflint
              cd labs/m06-dynamic-logic
              tflint --recursive
            displayName: 'tflint'
            continueOnError: true

  - stage: Plan
    dependsOn: Validate
    jobs:
      - job: Plan
        steps:
          - task: TerraformInstaller@1
            displayName: 'Install Terraform'
            inputs:
              terraformVersion: '$(TF_VERSION)'

          - script: |
              cd labs/m06-dynamic-logic
              terraform init
              terraform plan -out=tfplan -input=false
            displayName: 'Terraform Plan'
            env:
              TF_VAR_snowflake_token: $(SNOWFLAKE_PAT)
              ARM_SUBSCRIPTION_ID: $(ARM_SUBSCRIPTION_ID)
              ARM_TENANT_ID: $(ARM_TENANT_ID)

          - task: PublishPipelineArtifact@1
            displayName: 'Publish tfplan'
            inputs:
              targetPath: 'labs/m06-dynamic-logic/tfplan'
              artifact: tfplan

  - stage: Approval
    dependsOn: Plan
    condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
    jobs:
      - deployment: Approval
        environment: Approval
        strategy:
          runOnce:
            deploy:
              steps:
                - script: echo "Waiting for manual approval"
                  displayName: 'Manual approval gate'

  - stage: Apply
    dependsOn: Approval
    condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
    jobs:
      - job: Apply
        steps:
          - task: TerraformInstaller@1
            displayName: 'Install Terraform'
            inputs:
              terraformVersion: '$(TF_VERSION)'

          - task: DownloadPipelineArtifact@2
            displayName: 'Download tfplan'
            inputs:
              artifact: tfplan
              targetPath: 'labs/m06-dynamic-logic/'

          - script: |
              cd labs/m06-dynamic-logic
              terraform init
              terraform apply tfplan -input=false
            displayName: 'Terraform Apply'
            env:
              TF_VAR_snowflake_token: $(SNOWFLAKE_PAT)
              ARM_SUBSCRIPTION_ID: $(ARM_SUBSCRIPTION_ID)
              ARM_TENANT_ID: $(ARM_TENANT_ID)

  - stage: Audit
    dependsOn: Apply
    condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
    jobs:
      - job: Audit
        steps:
          - task: TerraformInstaller@1
            displayName: 'Install Terraform'
            inputs:
              terraformVersion: '$(TF_VERSION)'

          - script: |
              cd labs/m06-dynamic-logic
              terraform init
              terraform plan -detailed-exitcode -input=false
            displayName: 'Drift detection (terraform plan -detailed-exitcode)'
            env:
              TF_VAR_snowflake_token: $(SNOWFLAKE_PAT)
              ARM_SUBSCRIPTION_ID: $(ARM_SUBSCRIPTION_ID)
              ARM_TENANT_ID: $(ARM_TENANT_ID)
'@

Set-Location C:\Data2AI-Labs\data-platform\labs\m07-cicd-pipeline
Set-Content -Path azure-pipelines.yml -Value $pipelineYaml -Encoding UTF8

Write-Output "=== M07: Verify file exists ==="
Test-Path azure-pipelines.yml
Get-Content azure-pipelines.yml | Select-Object -First 5

Write-Output ""
Write-Output "=== M07: Run SelfPacedLab validation ==="
Set-Location C:\Data2AI-Labs\data-platform
& .\scripts\SelfPacedLab.ps1 -Module 7 -All -Report 2>&1

Write-Output ""
Write-Output "=== M07: Verify pipeline stages ==="
$yaml = Get-Content azure-pipelines.yml -Raw
$stages = ([regex]::Matches($yaml, '- stage: (\w+)') | ForEach-Object { $_.Groups[1].Value })
Write-Output "Stages found: $($stages -join ', ')"

$hasApproval = $yaml -match 'deployment:\s*Approval'
Write-Output "Has approval gate: $hasApproval"

$hasValidate = $yaml -match 'terraform fmt -check'
Write-Output "Has fmt check: $hasValidate"

$hasPlan = $yaml -match 'terraform plan'
Write-Output "Has plan: $hasPlan"

$hasApply = $yaml -match 'terraform apply'
Write-Output "Has apply: $hasApply"

$hasAudit = $yaml -match 'detailed-exitcode'
Write-Output "Has audit/drift detection: $hasAudit"

Write-Output ""
Write-Output "=== M07 COMPLETE ==="
