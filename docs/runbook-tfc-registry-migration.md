# Runbook: Event Hub Module — Private Registry vs Public AVM

**Date:** 2026-11-02

This runbook covers two approaches for consuming Event Hub infrastructure as a Terraform module:

- **Option A** — Push your custom module to the TFC private registry (full control)
- **Option B** — Use the public Azure Verified Module directly (zero maintenance)

---

## Prerequisites (both options)

- **Terraform CLI** ≥ 1.9 installed locally
- **Azure subscription** with contributor access
- **TFC API token** (for Option A) — run `terraform login`
- **GitHub CLI** (`gh`) installed (for Option A)

---

## Option A — Custom Module in TFC Private Registry

Use this when you need full control over the module interface, enforce org standards, or bundle resources in a specific way.

### A.1 — Create the GitHub repo and push

The repo must be named `terraform-<PROVIDER>-<NAME>` with Terraform files at the root.

```bash
cd terraform-azurerm-eventhub

# Create remote repo and push
gh repo create terraform-azurerm-eventhub --public --source=. --push
```

Use `--private` if preferred.

### A.2 — Tag the initial release

TFC reads **semantic version tags** to publish versions.

```bash
git tag v1.0.0
git push origin v1.0.0
```

### A.3 — Connect module to TFC registry

1. Log in to [app.terraform.io](https://app.terraform.io) → select the **vantagedc** organization
2. **Registry** → **Modules** → **Publish** → **Module**
3. Select **GitHub** as the VCS provider
   - If not connected: **Organization Settings** → **VCS Providers** → **Add** → **GitHub** → OAuth flow
4. Select the `terraform-azurerm-eventhub` repo
5. Click **Publish Module**

TFC will auto-detect provider = `azurerm`, module = `eventhub`, and publish version 1.0.0.

Verify at: `https://app.terraform.io/app/vantagedc/registry/modules/private/vantagedc/eventhub/azurerm`

### A.4 — Use the private module

```hcl
module "eventhub" {
  source  = "app.terraform.io/vantagedc/eventhub/azurerm"
  version = "~> 1.0"

  namespace_name             = "myapp-dev-evhns"
  resource_group_name        = module.rg.name
  location                   = module.rg.location
  namespace_sku              = "Standard"
  capacity                   = 2
  log_analytics_workspace_id = module.law.id

  hubs = {
    events = {
      partition_count   = 4
      message_retention = 7
      consumer_groups = {
        processor = { user_metadata = "Event processor" }
      }
      authorization_rules = {
        sender = { send = true }
      }
    }
  }

  tags = local.common_tags
}
```

Then:

```bash
terraform login   # if not already authenticated
terraform init    # downloads from TFC registry
terraform plan    # verify
```

### A.5 — Versioning strategy

| Change type | Version bump | Example |
|-------------|-------------|---------|
| Bug fix, no interface change | Patch | `v1.0.0` → `v1.0.1` |
| New optional variable/output | Minor | `v1.0.0` → `v1.1.0` |
| Breaking change (rename, remove) | Major | `v1.0.0` → `v2.0.0` |

To publish a new version:

```bash
git tag v1.1.0
git push origin v1.1.0
# TFC auto-publishes within ~1 minute
```

---

## Option B — Public Azure Verified Module (AVM)

Use this when you don't need custom control and want zero module maintenance overhead.

### B.1 — No setup required

The AVM module is publicly available on the Terraform registry. No private registry, no repo to maintain, no versioning to manage.

Registry page: `https://registry.terraform.io/modules/Azure/avm-res-eventhub-namespace/azurerm`

### B.2 — Use the public module

```hcl
module "eventhub_namespace" {
  source  = "Azure/avm-res-eventhub-namespace/azurerm"
  version = "~> 0.5"

  name                = "myapp-dev-evhns"
  resource_group_name = module.rg.name
  location            = module.rg.location
  sku                 = "Standard"
  capacity            = 1

  eventhubs = {
    events = {
      partition_count   = 4
      message_retention = 7

      consumer_groups = {
        processor = {
          name          = "processor"
          user_metadata = "Event processor"
        }
      }

      authorization_rules = {
        sender = {
          name   = "sender"
          send   = true
          listen = false
          manage = false
        }
      }
    }
  }

  diagnostic_settings = {
    to_law = {
      name                  = "diag-to-law"
      workspace_resource_id = module.law.id
    }
  }

  tags = local.common_tags
}
```

Then:

```bash
terraform init    # downloads from public registry
terraform plan    # verify
```

### B.3 — Key differences from the custom module

| Feature | Custom (Option A) | Public AVM (Option B) |
|---------|-------------------|----------------------|
| Source | `app.terraform.io/vantagedc/eventhub/azurerm` | `Azure/avm-res-eventhub-namespace/azurerm` |
| Maintenance | You manage versioning, updates, bug fixes | Microsoft + community |
| Interface | Simplified, tailored to your needs | Comprehensive, covers all use cases |
| Private endpoint | Built-in via `private_endpoint_subnet_id` | Separate `private_endpoints` map |
| Diagnostics | Single `log_analytics_workspace_id` | Flexible `diagnostic_settings` map |
| Auth required | TFC token (`terraform login`) | None (public registry) |
| Network rules | Inline `network_rulesets` object | Separate `network_rule_config` |

---

## Validation (both options)

After `terraform init`:

```bash
# Confirm module was downloaded
terraform init
# Look for: Downloading <source> <version>...

# Plan to verify no unexpected changes
terraform plan

# Expected: "No changes" if migrating from identical local module code
```

If plan shows unexpected changes:
- Check module version tag matches the deployed code
- Verify variable names and types match
- Refresh TFC token if using Option A

---

## Recommendation

| Scenario | Use |
|----------|-----|
| No restrictions, minimal overhead wanted | **Option B** (public AVM) |
| Org compliance/security policies in place | **Option A** (private registry) |
| Need org-wide defaults without wrappers | **Option A** (private registry) |
| Public module missing needed feature | **Option A** or wrapper around Option B |

---

## Remaining modules (if using Option A)

Repeat the Option A steps for each:

- [ ] `terraform-azurerm-resource-group` → `app.terraform.io/vantagedc/resource-group/azurerm`
- [ ] `terraform-azurerm-log-analytics` → `app.terraform.io/vantagedc/log-analytics/azurerm`
- [ ] `terraform-azurerm-key-vault` → `app.terraform.io/vantagedc/key-vault/azurerm`
- [ ] `terraform-azurerm-network` → `app.terraform.io/vantagedc/network/azurerm`
- [ ] `terraform-azurerm-rbac` → `app.terraform.io/vantagedc/rbac/azurerm`

If switching to **Option B**, check for equivalent AVM modules at:
`https://registry.terraform.io/namespaces/Azure` (search for `avm-res-*`)
