# M03 — Troubleshooting

## 1. `Error: Invalid value for variable` au `plan`

**Symptôme :** le plan échoue avec votre message de `validation`.

**Diagnostic :** ouvrez `terraform.tfvars` et vérifiez la valeur de la variable
ciblée.

**Correction :** remettez une valeur valide (ex: `warehouse_size = "X-SMALL"`,
`warehouse_auto_suspend = 60`). La validation protège le compte : c'est un
comportement normal, pas un bug.

## 2. `Error: Database already exists`

**Symptôme :** le `apply` échoue parce que la database existe déjà.

**Diagnostic :** dans Snowsight :

```sql
SHOW DATABASES LIKE 'APP01_M03%';
```

**Correction :**

```sql
DROP DATABASE APP01_M03_RAW_DEV;
```

Puis `terraform apply`.

## 3. `plan` ignore votre `-var`

**Symptôme :** `terraform plan -var "warehouse_size=SMALL"` ne change rien.

**Diagnostic :** vérifiez la syntaxe. Le signe `=` doit être collé, sans espace :
`-var="warehouse_size=SMALL"` (correct), `-var="warehouse_size = SMALL"` (incorrect).

**Correction :** corrigez la syntaxe et relancez.
