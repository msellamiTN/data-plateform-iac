# Solution M03 — vérification

```powershell
cd C:\terraform-labs\m03-variables
terraform init
terraform validate
terraform plan
terraform apply
# Changer warehouse_auto_suspend 60 → 120 dans tfvars, plan → ~, apply
# warehouse_size = "LARGE" → plan échoue (validation)
terraform destroy
```
