# Rapport de vulnérabilités — OrignaGTA (03 février 2026)

## Portée
Audit ciblé “vente/achat” + sécurité production sur :
- Règles Firestore
- Cloud Functions (Stripe/Airwallex + admin)
- Client Flutter (checkout)
- Gestion de secrets / artefacts sensibles

Ce rapport est orienté actions (P0/P1/P2) et couvre les vulnérabilités **exploitables** + les risques de production.

## Résumé exécutif
- **Points forts** : les commandes ne peuvent pas être créées côté client (règles strictes), le checkout recalcule serveur-side (anti price-tampering) avec transaction stock, et les webhooks ont une déduplication idempotente.
- **Risques majeurs** : un artefact Stripe a été **committé** dans git (fuite potentielle), et les règles Firestore `products` autorisent l’injection de champs non contrôlés à la création (ex: manipulation de `rating`).

## Findings (priorisés)

### P0 — Critique (à traiter immédiatement)

1) **Artefact sensible committé dans git**
- Symptôme : un fichier de debug Stripe était suivi par git (confirmé via `git ls-files`).
- Impact : fuite de données sensibles / secrets (même partiels) + risque de compromission et non-conformité.
- Correctif immédiat (fait) : suppression du fichier + ajout aux ignores.
- Correctif indispensable (à faire) : rotation des secrets concernés et purge d’historique git si nécessaire.
- Références : [functions/.gitignore](../functions/.gitignore), [/.gitignore](../.gitignore).

2) **Injection de champs non autorisés lors de la création de produit (Firestore rules)**
- Symptôme : la règle `products` utilise `request.resource.data.keys().hasAll([...])` au lieu de `hasOnly`.
- Exploit : un vendeur peut créer un produit avec des champs additionnels non contrôlés (ex: `rating`, `ratingCount`, flags de mise en avant, champs internes), tant que les champs “minimum” existent.
- Impact : fraude / trust manipulation (notes/avis), SEO interne, et corruption de données.
- Lieu : [firestore.rules](../firestore.rules#L203-L236), en particulier [firestore.rules](../firestore.rules#L211-L235).
- Recommandation : passer à `hasOnly([...])` (ou `hasOnly` + liste d’extensions explicitement autorisées), et interdire explicitement `rating`, `ratingCount`, champs d’audit, champs “admin-only”.

### P1 — Important (risque élevé / impact business)

3) **Mise à jour produit trop permissive (surface d’attaque élevée)**
- Symptôme : `allow update` valide quelques champs (name/description/address/keywords/stock), mais ne limite pas strictement les clés modifiables.
- Impact : possibilité de pollution de schéma (champs énormes, données incohérentes) et contournements via champs non couverts par validations.
- Lieu : [firestore.rules](../firestore.rules#L237-L252).
- Recommandation : ajouter `request.resource.data.diff(resource.data).affectedKeys().hasOnly([...])` avec un allowlist explicite.

4) **Admin/modération produit bloquée par règle `isActive` immuable**
- Symptôme : `request.resource.data.isActive == resource.data.isActive` s’applique aussi aux admins.
- Impact : impossibilité de désactiver/modérer un produit via le client (si c’est l’UX prévue). Cela pousse à des contournements (admin SDK) et fragilise l’exploitation.
- Lieu : [firestore.rules](../firestore.rules#L248).
- Recommandation : autoriser `isActive` à changer **uniquement** pour admin (ou via Cloud Function admin-only), et maintenir le blocage pour sellers.

5) **Idempotency checkout trop déterministe (bloque des achats légitimes)**
- Symptôme : la clé d’idempotence est stable “par jour” pour un même panier (produits+quantités), donc acheter 2 fois le même panier le même jour peut renvoyer l’ancien checkout.
- Impact : ventes perdues / confusion utilisateur / support.
- Lieu : [origna_gta/lib/features/checkout/checkout_provider.dart](../origna_gta/lib/features/checkout/checkout_provider.dart#L308-L321).
- Recommandation : générer une clé d’idempotence **par tentative** (UUID côté client), la persister dans l’état (ou Firestore user doc) et la réutiliser uniquement en cas de retry de la même tentative.

### P2 — Moyen / Durcissement (sécurité/fiabilité)

6) **Logs de secrets même en mode emulator**
- Symptôme : logs du préfixe/longueur du secret webhook.
- Impact : fuite par logs (CI, console partagée, captures).
- Lieu : [functions/main.py](../functions/main.py#L867-L873).
- Recommandation : supprimer ces logs (ou les remplacer par un hash non réversible).

7) **Webhook Airwallex rate-limit sans `fail_closed`**
- Symptôme : Stripe webhook utilise `fail_closed=True`, Airwallex non.
- Impact : si le rate limiter tombe, Airwallex webhook peut être une surface de flood.
- Lieu : [functions/main.py](../functions/main.py#L3122-L3131).
- Recommandation : aligner la stratégie avec Stripe (`fail_closed=True`).

8) **Signature Airwallex: vérifier usage “raw bytes” vs “string”**
- Symptôme : le payload est converti en string avant vérification.
- Impact : si la vérification de signature doit se faire sur bytes bruts, risque de faux négatif/positif selon encodage.
- Lieu : [functions/main.py](../functions/main.py#L3113-L3141).
- Recommandation : faire la vérif sur `req.data` bytes (et préciser l’encodage attendu par Airwallex).

9) **Supply-chain Flutter: dépendances non verrouillées par version dans pubspec**
- Symptôme : dépendances en `^` peuvent introduire des changements inattendus.
- Impact : régressions prod, comportement non déterministe en CI si lockfile varie.
- Lieu : [origna_gta/pubspec.yaml](../origna_gta/pubspec.yaml).
- Recommandation : s’appuyer sur `pubspec.lock` en CI, et instaurer une policy d’upgrade contrôlée.

## Actions recommandées (ordre d’exécution)
- **P0** : rotation secrets Stripe/Airwallex/R2/Algolia si exposés dans l’historique; suppression/purge d’historique si nécessaire.
- **P0** : durcir `products` create en `hasOnly` + blocage explicite des champs sensibles.
- **P1** : durcir `products` update avec allowlist de clés modifiables.
- **P1** : revoir idempotency checkout pour éviter “achat bloqué”.
- **P2** : enlever logs de secret; `fail_closed` sur Airwallex; vérifier signature bytes.

## Notes
- Les commandes sont protégées côté règles : création et suppression interdites côté client, ce qui réduit fortement les attaques de manipulation client-side.
- Le checkout serveur-side valide prix/stock en transaction et restaure le stock sur expiration/échec (bon pattern pour scalabilité et intégrité).
