# Secrets incident response (03 février 2026)

## Constat
Un fichier sensible a été committé dans l’historique git : `functions/stripe.txt` (vu via `git log --all -- functions/stripe.txt`).

Même si ce fichier a été supprimé du working tree et ignoré, **il reste présent dans l’historique** et doit être traité comme une fuite potentielle.

## Actions immédiates (P0)
1. **Révoquer / rotation des secrets** potentiellement exposés
   - Stripe: webhook secret(s), API keys
   - Airwallex: webhook secret, API key/client id
   - Algolia: admin API key (si jamais exposée)
   - R2: access key/secret

2. **Auditer où ces secrets sont utilisés**
   - `functions/.env` (local)
   - Config Firebase (prod): variables d’environnement / Secret Manager

3. **Décider si réécriture d’historique est nécessaire**
   - Si le dépôt est public ou partagé largement, privilégier réécriture + rotation.

## Réécriture d’historique (optionnel mais recommandé)
Utiliser `git filter-repo` (recommandé) ou BFG.

### Option A — git filter-repo
1. Installer: `brew install git-filter-repo`
2. Réécrire:
   - `git filter-repo --path functions/stripe.txt --invert-paths`
3. Forcer push:
   - `git push --force --all`
   - `git push --force --tags`

### Option B — BFG Repo-Cleaner
1. Installer BFG
2. `bfg --delete-files stripe.txt`
3. `git reflog expire --expire=now --all && git gc --prune=now --aggressive`
4. Forcer push branches/tags

## Post-actions
- Activer un scan de secrets en CI (ex: gitleaks) + pre-commit.
- Ajouter un playbook interne “comment créer des logs sans secrets”.
- Vérifier que les webhooks continuent de fonctionner après rotation.
