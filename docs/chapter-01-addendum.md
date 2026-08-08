# Appendix 1 — Additional Departments (Company Growth)

## Business Requirement

Chapter 1 was built and closed around TechNova's original four departments — Engineering, Sales, Finance, and HR. Planning for Chapter 2 (Bash Automation, onboarding 70 new hires) surfaced a realistic gap: a company growing fast enough to hire 70 people in one wave almost never adds all of them to four unchanged departments. New functions typically get created — a company that just shipped its first product needs Marketing to drive growth, Customer Support to handle a growing user base, Product Management to own what gets built next, and (as decided during setup, see below) DevOps to support Engineering's shipping pace.

This is documented as an appendix rather than folded into Chapter 1, since Chapter 1 was already reviewed and closed out in its Task 10 security audit — reopening it would blur that boundary. Standing up new departments mid-project is itself realistic: real companies restructure and expand outside their original org chart planning all the time.

## Departments Added

| Department | Admin | Username |
|---|---|---|
| Marketing | Tobiloba Ajayi | `tajayi` |
| Customer Support | Ngozi Eke | `neke` |
| Product Management | Kingsley Uche | `kuche` |
| DevOps | Amaka Nwosu | `anwosu` |


## Setup Commands

```bash
sudo chmod 2770 /srv/technova/departments/marketing
sudo chmod 2770 /srv/technova/departments/Customer-Support
sudo chmod 2770 /srv/technova/departments/Product-mgt
sudo chmod 2770 /srv/technova/departments/DeVops
```

```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ ls -ld /srv/technova/departments/marketing /srv/technova/departments/Customer-Support /srv/technova/departments/Product-mgt /srv/technova/departments/DeVops
drwxrws--- 2 neke   Customer-Support 4096 Aug  8 08:46 /srv/technova/departments/Customer-Support
drwxrws--- 2 anwosu DeVops           4096 Aug  8 08:47 /srv/technova/departments/DeVops
drwxrws--- 2 kuche  Product-mgt      4096 Aug  8 08:46 /srv/technova/departments/Product-mgt
drwxrws--- 2 tajayi marketing        4096 Aug  8 08:45 /srv/technova/departments/marketing
```
✅ Setgid and department-only access (`2770`) confirmed applied to all four before proceeding to renaming.

## Renaming Groups and Directories (Naming Convention Cleanup)

Initial names (`Customer-Support`, `Product-mgt`, `DeVops`) used mixed case and hyphens, inconsistent with the original four departments (`engineering`, `sales`, `finance`, `hr`). Groups were renamed with `groupmod -n` (preserves GID and membership — no re-creation needed), directories renamed with `mv`.

```bash
sudo groupmod -n support Customer-Support
sudo groupmod -n product Product-mgt
sudo groupmod -n devops DeVops
```

**Further rename attempted for `product` → `productmgt` (to avoid an overly generic single-word name):**
```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ sudo groupmod -n product productmgt
groupmod: group 'productmgt' does not exist
```
Cause: `groupmod -n <new> <old>` syntax was reversed — new name given first, old name second, which `groupmod` interpreted as "rename group `productmgt`" (which didn't exist yet) rather than "rename `product` to `productmgt`." Corrected by reversing the argument order:
```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ sudo groupmod -n productmgt product
```
✅ Succeeded.

**Same argument-order mistake repeated twice while renaming `Customer-Support`:**
```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ sudo groupmod -n Customer-Support CustomerSupport
groupmod: group 'CustomerSupport' does not exist
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ sudo groupmod -n CustomerSupport Customer-Support
groupmod: group 'Customer-Support' does not exist
```
Cause: by this point the group had already been renamed to `support` in the first `groupmod` command above, so `Customer-Support` no longer existed under that name — the correct old name to reference was `support`, not `Customer-Support`. Corrected:
```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ sudo groupmod -n CustomerSupport support
```
✅ Succeeded — final group name: `CustomerSupport`.

**Directory renames:**
```bash
sudo mv /srv/technova/departments/DeVops /srv/technova/departments/devops
```
✅ Succeeded on first attempt.

```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ sudo mv /srv/technova/departments/product /srv/technova/departments/productmgt
mv: cannot stat '/srv/technova/departments/product': No such file or directory
```
Cause: the directory had never been renamed from its original name — only the group had been renamed at this point. Attempted again with a guessed name:
```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ sudo mv /srv/technova/departments/Project-mgt /srv/technova/departments/productmgt
mv: cannot stat '/srv/technova/departments/Project-mgt': No such file or directory
```
Cause: typo — "Project-mgt" instead of the actual original name "Product-mgt". Corrected:
```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ sudo mv /srv/technova/departments/Product-mgt /srv/technova/departments/productmgt
```
✅ Succeeded.

```bash
sudo mv /srv/technova/departments/Customer-Support /srv/technova/departments/CustomerSupport
```
✅ Succeeded.

## Verification

```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ id tajayi
uid=1014(tajayi) gid=1006(marketing) groups=1006(marketing)
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ id neke
uid=1015(neke) gid=1007(CustomerSupport) groups=1007(CustomerSupport)
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ id kuche
uid=1016(kuche) gid=1008(productmgt) groups=1008(productmgt)
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ id answosu
uid=1017(anwosu) gid=1009(devops) groups=1009(devops)
```

```
ruth1@DESKTOP-DD7VGNC:~/Technova-Homelab$ ls -ld /srv/technova/departments/marketing /srv/technova/departments/CustomerSupport /srv/technova/departments/productmgt /srv/technova/departments/devops
drwxrws--- 2 neke   CustomerSupport 4096 Aug  8 08:46 /srv/technova/departments/CustomerSupport
drwxrws--- 2 anwosu devops          4096 Aug  8 08:47 /srv/technova/departments/devops
drwxrws--- 2 tajayi marketing       4096 Aug  8 08:45 /srv/technova/departments/marketing
drwxrws--- 2 kuche  productmgt      4096 Aug  8 08:46 /srv/technova/departments/productmgt
```

✅ Group renames automatically reflected on the directory listing (GID preserved throughout, so no `chown` was needed). Setgid (`s`) and restricted permissions (`rws---`) confirmed intact on all four after renaming.

## Known Inconsistency — Not Yet Fully Resolved

`CustomerSupport` still doesn't match the lowercase, no-internal-capitalization convention used by `marketing`, `productmgt`, `devops`, and the original four (`engineering`, `sales`, `finance`, `hr`). It was renamed from `Customer-Support` (dropping the hyphen) but retained internal capitalization. Left as-is for now since it doesn't affect function — group names are case-sensitive but functionally identical either way — but flagged here for a future cleanup pass if full naming consistency is wanted later.

## Final Department Reference Table

| Department | Directory | Group | Admin |
|---|---|---|---|
| Marketing | `marketing` | `marketing` | `tajayi` |
| Customer Support | `CustomerSupport` | `CustomerSupport` | `neke` |
| Product Management | `productmgt` | `productmgt` | `kuche` |
| DevOps | `devops` | `devops` | `anwosu` |

## Status

**✅ Complete**

Four new departments created, secured (`2770`, setgid confirmed), and renamed toward TechNova's naming convention. One naming inconsistency (`CustomerSupport` casing) remains, noted above but not blocking. TechNova now operates across eight departments total: `engineering`, `sales`, `finance`, `hr`, `marketing`, `CustomerSupport`, `productmgt`, `devops`.
