# Solution M02 — vérification

```powershell
cd C:\terraform-labs\m02-cycle-de-vie
terraform init
terraform validate
terraform plan
terraform apply
# Modifier main.tf (auto_suspend 60 → 120), terraform plan → ~, terraform apply
terraform plan -destroy
terraform destroy
terraform apply   # recréer
terraform plan     # No changes.
```
