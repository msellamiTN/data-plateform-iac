# secrets/

This directory holds local secret files that are **never committed to Git**.

The `.gitignore` excludes all files in `secrets/` except this README, so the directory exists in the clone without exposing any secret.

> `[KV-FIRST]` **In KV-first mode, this directory is NOT needed.**
> Learners authenticate with their AAD account and fetch all secrets
> from Azure Key Vault. The files below are **fallback/recovery only**.

## Secret distribution architecture

Three authentication modes exist, chosen by `Learner-Login.ps1` / `learner-login.sh` flags:

| Mode | When | Azure required | What it does |
|---|---|---|---|
| **`-SnowflakeOnly`** | **Days 1–3 (initiation)** | No | Reads `secrets/snowflake_pat.txt`, sets `TF_VAR_snowflake_token` + `LEARNER_PREFIX`. No `az login`, no browser popup. |
| **KV-first** (default) | Days 4–5 + Day 0 setup | Yes | AAD browser login → fetch SP creds + PAT from Key Vault → set `ARM_*` + `TF_VAR_snowflake_token`. |
| **`-ForceFallback`** | Recovery only | Yes | Same as KV-first but reads `secrets/shared-sp.txt` + `secrets/snowflake_pat.txt` locally instead of Key Vault. |

```
┌─────────────────────────────────────────────────────────────┐
│  Azure Key Vault (kvdata2aitfsecretsmsn)                    │
│                                                             │
│  Secrets:                                                   │
│  • ArmClientId, ArmClientSecret, ArmTenantId, ArmSubId      │
│  • SnowflakePAT  ← shared PAT (all learners)                │
│  • SnowflakePassword-APP01..APP12 ← web login passwords     │
│  • SnowflakeOrganization, SnowflakeAccount, SnowflakeUser   │
│                                                             │
│  Access:                                                    │
│  • Data2AI-Learners group → Key Vault Secrets User (AAD)    │
│  • Shared SP → Key Vault Secrets User                       │
│  • WIF CI SP → Key Vault Secrets User                       │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│  Learner-Login.ps1 (KV-first mode)                          │
│                                                             │
│  1. Load config/shared.env (committed, no secrets)          │
│  2. Load .env (gitignored, LEARNER_PREFIX only)             │
│  3. AAD login (browser, learner's work account)             │
│  4. Fetch SP creds from Key Vault:                          │
│     az keyvault secret show \                               │
│       --vault-name $KEY_VAULT_NAME \                        │
│       --name ArmClientId / ArmClientSecret / ...            │
│  5. SP login (for Terraform provider)                       │
│  6. Fetch SnowflakePAT from Key Vault                       │
│  7. Set TF_VAR_snowflake_token + ARM_* env vars             │
│                                                             │
│  Snowflake-only (-SnowflakeOnly) — Days 1-3:                │
│  1. Read secrets/snowflake_pat.txt (local)                  │
│  2. Set TF_VAR_snowflake_token + LEARNER_PREFIX             │
│  3. Done — no Azure interaction at all                      │
│                                                             │
│  Fallback (-ForceFallback):                                 │
│  1. Read secrets/shared-sp.txt (local)                      │
│  2. SP login                                                │
│  3. Read secrets/snowflake_pat.txt (local)                  │
│  4. Set env vars                                            │
└─────────────────────────────────────────────────────────────┘
```

## Relationship with .env and config/shared.env

| File | Committed | Contains | Purpose |
|---|---|---|---|
| `config/shared.env` | Yes | Account IDs, Azure config, Key Vault name | Shared config (no secrets) |
| `.env` | No | `LEARNER_PREFIX`, `ENVIRONMENT` | Per-learner personal values |
| `secrets/shared-sp.txt` | No | `ARM_CLIENT_ID`, `ARM_CLIENT_SECRET`, ... | Azure SP credentials (fallback only) |
| `secrets/snowflake_pat.txt` | No | PAT token | Fallback if Key Vault is unavailable |
| `secrets/snowflake_key.p8` | No | RSA private key | JWT key-pair auth (M10) |
| `secrets/snowflake_key.pub` | No | RSA public key | JWT key-pair auth (M10) |

## Expected files (fallback mode only)

| File | Created when | Purpose | Source |
|---|---|---|---|
| `shared-sp.txt` | Day 0 (recovery only) | Azure SP credentials for `az login` | Instructor (fallback) |
| `snowflake_pat.txt` | Day 0 (recovery only) | Snowflake PAT | Key Vault (preferred) or `New-SnowflakeConnection.ps1` |
| `learner-azure-passwords.txt` | Day 0 (instructor only) | AAD learner UPNs + passwords for KV-first browser login | `project/02-azuread-learners` (Terraform) |
| `learner-snowflake-passwords.txt` | Day 0 (instructor only) | Snowflake web login passwords (Snowsight) | Instructor / Key Vault `SnowflakePassword-APPxx` |
| `learner-vm-rdp.txt` | Day 0 (instructor only) | RDP IPs + unified credentials for learner VMs | `project/08-learner-vms` (Terraform output `learner_rdp_info`) |
| `learner-sp-secrets.txt` | Day 0 (instructor only) | Per-learner SP credentials (appId, secret, tenantId) | Instructor |
| `snowflake_key.p8` | Day 4 (M10) | RSA private key for JWT auth | `openssl genrsa` |
| `snowflake_key.pub` | Day 4 (M10) | RSA public key | `openssl rsa -pubout` |
| `backend.hcl` | Day 2 (M2) | Azure Blob backend config | Learner creates |

## Rules

1. **Never** commit a file in this directory other than `README.md`.
2. **Never** display the content of a secret file in a screenshot, log or report.
3. **Never** pass a secret as a command-line argument — use environment variables or masked prompts.
4. **Rotate** the PAT when the training module is complete.
5. **Delete** the contents of this directory at the end of the training.
6. **Prefer KV-first mode** — no local secrets needed.
7. **Rotate immediately** any credential that was ever committed to Git, even if the push was blocked — GitHub Push Protection caught a historical commit containing a PAT and SP secrets; the history was rewritten (2026-09), but rotation is still required for the Snowflake PAT, `learner-sp`/`shared-sp` secrets, and the `TERRAFORM_USER` password.

## Verify Git ignores secrets

```bash
git check-ignore secrets/snowflake_pat.txt
git check-ignore secrets/shared-sp.txt
```

**Expected:** the command returns the path, confirming Git ignores it.

If the command returns nothing, stop and fix your `.gitignore` before proceeding.
