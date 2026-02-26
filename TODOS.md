


## External Manual Backlog (Future)

Console Firebase — Supprimer l'ancien app iOS com.example.orignaGta, ajouter la nouvelle avec ca.orignagta.app, re-télécharger GoogleService-Info.plist (il manquera le REVERSED_CLIENT_ID pour Google Sign-In)
Apple Developer Portal — Créer l'App ID ca.orignagta.app, activer les capabilities Push Notifications et Associated Domains
APNs — Créer une clé APNs (ou certificat) et l'uploader dans Firebase Console → Project Settings → Cloud Messaging → Apple app
Déployer le AASA — Le fichier apple-app-site-association est dans web/.well-known/ — il sera servi automatiquement si le site est hosté avec Firebase Hosting (ajouter un rewrite dans firebase.json si nécessaire avec Content-Type: application/json)
Google Sign-In — Après régénération du GoogleService-Info.plist, ajouter le REVERSED_CLIENT_ID comme URL scheme supplémentaire dans Info.plist


Voici les 3 entitlements à activer dans le Apple Developer Portal (Identifiers → ca.orignagta.app → Capabilities) :

Capability	Entitlement	Pourquoi
Push Notifications	aps-environment	Firebase Cloud Messaging / notifications de commandes
Associated Domains	com.apple.developer.associated-domains	Universal Links pour les retours Stripe (/payment-success, /seller-return, etc.)
Sign in with Apple	com.apple.developer.applesignin	Obligatoire — Apple rejette les apps qui offrent Google Sign-In sans aussi offrir Sign in with Apple (App Store Review Guideline 4.8)
Étapes dans le portail Apple :
Identifiers → Create/Edit App ID ca.orignagta.app
Cocher : ✅ Push Notifications, ✅ Associated Domains, ✅ Sign in with Apple
Keys → Créer une clé APNs → l'uploader dans Firebase Console (Project Settings → Cloud Messaging)
Profiles → Générer un Provisioning Profile de développement et de distribution avec ces capabilities
Changer aps-environment de development à production avant la soumission App Store
Note importante : Puisque vous offrez Google Sign-In, vous devrez aussi implémenter Sign in with Apple dans l'app Flutter (package sign_in_with_apple) avant de soumettre sur l'App Store — c'est une exigence Apple.

Ce qui nécessite l'Apple Developer Program ($99/an) :
Feature	Pourquoi
Push Notifications	Capability aps-environment
Universal Links (retour auto depuis Stripe)	Capability Associated Domains
Sign in with Apple	Capability + obligatoire pour l'App Store si tu offres Google Sign-In
App Store submission	Distribution via TestFlight ou App Store


cd /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/origna_gta && sed -i '' '/CODE_SIGN_ENTITLEMENTS = Runner\/Runner.entitlements;/d' ios/Runner.xcodeproj/project.pbxproj
Les 3 références CODE_SIGN_ENTITLEMENTS sont supprimées. Tu peux maintenant relancer flutter run. Le fichier Runner.entitlements reste dans le repo pour plus tard quand tu auras le Apple Developer Program — il suffira de réajouter les lignes dans le pbxproj.
For future manual setup:
0. google mcp integration
1. mcp for api
2. web mcp
3. docs for 1 and 2




10.**Cloud Scheduler frequency** — Cron jobs should run at the minimum effective frequency (e.g. every 5 minutes, not every minute) to reduce invocations while still meeting timing requirements.


11. mcp for store


# Add Product — Full Code Audit
**Files audited:** `Product.json`, `add_product_state.dart`, `add_product_viewmodel.dart`, `addproduct_screen.dart`, `product_repository.dart`, `supplier_config.dart`, `schema_constants.dart`

---


22. playwright ai agents integration
