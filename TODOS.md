
## TODO (Active)

- Ensure schema constants are widely used
- Update json schema constants when database schema changes
- ChromeDriver compatibility for Flutter web integration tests
- check complience with https://fintrac-canafe.canada.ca/introduction/cpf/cpf-eng
- Potential Minor Issues:
Airwallex webhook secret is optional – if used, must enforce signature verification strictly (currently mirrors Stripe pattern but ensure it's not skipped when Airwallex enabled).
Geoapify API key sent client-side? No – only backend. Safe.
- audit tax codes,             tax_code_map = {
                17: "txcd_20030002",  # Children's Clothing
                19: "txcd_30060005",  # Basic Groceries
            }
Incomplete tax codes?
- make sure to convert to bool     update_data = {
        Fields.CHARGES_ENABLED: account.get('charges_enabled', False),
        Fields.PAYOUTS_ENABLED: account.get('payouts_enabled', False),
        Fields.ONBOARDING_COMPLETED: account.get('details_submitted', False),
        Fields.PENDING_REQUIREMENTS: pending_requirements,
        Fields.UPDATED_AT: get_server_timestamp(),
    }
-TODO add sentry to backend
-TODO create cli for admin

-TODO Short answer first (no fluff):
<!-- Best option:
One Firebase project per environment
(myapp-dev, myapp-staging, myapp-prod)
shared code
env-specific config
Anything else becomes painful or unsafe at scale.
✅ The gold-standard setup (recommended)
1️⃣ One Firebase project per env
Firebase / GCP
├── myapp-dev
├── myapp-staging
└── myapp-prod
Why this wins:
🔒 No risk of dev breaking prod
🔁 Truly reproducible
🧪 You can test auth, rules, billing, quotas
🚀 Matches real-world teams
This is how serious Firebase apps are run.
2️⃣ Firebase CLI environments
Use Firebase project aliases.
firebase use --add
Example .firebaserc:
{
  "projects": {
    "dev": "myapp-dev",
    "staging": "myapp-staging",
    "prod": "myapp-prod"
  }
}
Deploy safely:
firebase use dev
firebase deploy
No guessing. No accidents.
3️⃣ App-side env config (Flutter / Web / iOS / Android)
Each env gets its own config file.
Flutter example
class Env {
  static const String env = String.fromEnvironment('ENV');
}
Run:
flutter run --dart-define=ENV=dev
Firebase initialization:
Firebase.initializeApp(
  options: Env.env == 'prod'
      ? prodOptions
      : devOptions,
);
🔧 Where Terraform fits (clean separation)
Terraform manages:
Firebase project
Firestore DB
Auth providers
Hosting sites
IAM
Firebase CLI manages:
Firestore rules
Indexes
Hosting deploy
Emulator configs
This split is intentional and sane.
⚠️ Options you should avoid (unless tiny app)
❌ Single Firebase project + env prefixes
Example:
users_dev
users_prod
Problems:
Easy to leak prod data
Rules become unreadable
Billing + quotas shared
Hard to delete safely
Only acceptable for prototypes.
❌ Firestore “env” field
{ "env": "dev" }
This does not isolate anything:
Security rules are harder
Queries get slower
Humans make mistakes
🧠 Advanced (optional but powerful)
Shared backend + isolated frontends
Separate Firebase projects
Shared CI pipeline
Shared Terraform modules
Structure:
infra/
  modules/firebase/
  envs/dev/
  envs/staging/
  envs/prod/
This is how teams scale without chaos.
🔥 Final recommendation (no hedging)
If you want reproducible, safe, professional environments:
✅ One Firebase project per env
✅ Terraform for infra
✅ Firebase CLI for rules/content
✅ Env-specific app config
That’s the best option. Period. -->




TODO setup policy for refund and return similar to new amazon policy, no return or rfund after 7 days post delivery


TODO this looks good in mail box for yahoo, mail apple but not gmail google, the letters look white, and the background is white so u cannot see the numbers clearly, small ux ui bug, Subtotal	$1.99
Shipping	Free
Taxes	$0.26

TODO audit that the emails are sent correctly to buyers after checkout, the buyer should receive the emails with status updates. audit that during testing with yahoo real user yuniorrodriguezo4601 this happens, so far user only receives order confirmed email during playwright testing

TODO fix ruff warnings in functions and investigate them. make sure no issues in code

TODO Add referrals links with 10 cad discount for friend and also the person that referred

TODO audit unsubscribre fro amrketing email, remove privacy gmail

TODO new feature, users should be able to chat with the sellers of each product

TODO The mascots, users should be able to chat with them


TODO this is an example email with receipt from instacart, make sure that we are also sending receipts to buyer. analyze the sample and see if we can take some idea from it to improve info in emails. 
 Portrait du conducteur
Shiori a livré votre commande
Votre commande de No Frills a été passée le 9 février 2026 et livrée le 10 février 2026 à 12 h 41
12Articles trouvés   
1 Ajustement
 Les membres économisent en moyenne $7 par commande.
Inscrivez-vous à Instacart+
RAJUSTEMENTS (NO FRILLS)
1
ARTICLES DE REMPLACEMENT
Certains de vos articles n’étaient pas disponibles, votre acheteur a donc choisi des articles en fonction des articles de remplacement que vous aviez approuvés et qui étaient disponibles.

	Astro Original Balkan Style Plain Yogurt 2% (750 g)
1 x 3,00 $	Prix d’origine :
3,00 $
Icône de l’article de remplacement
	President’s Choice Club Size Plain Greek Yogurt (1 kg)
1 x 7,00 $	Prix de l’article remplacé :
7,00 $
 
ARTICLES TROUVÉS (NO FRILLS)
12
BAKERY
	No Name White Bread (675 g)
4 x 2,48 $	Prix définitif de l’article :
9,92 $
 
CANNED GOODS
	Mario's Luncheon Meat (340 g)
2 x 2,49 $	Prix définitif de l’article :
4,98 $
 
DAIRY & EGGS
	Neilson Chocolate Milk 1% (750 ml)
4 x 1,33 $	Prix définitif de l’article :
5,32 $
 
DELI
	Swanson's Frozen Fried Chicken (280 g)
1 x 4,25 $	Prix définitif de l’article :
4,25 $
 
MEAT & SEAFOOD
	No Name Wieners Chicken Hot Dogs (450 g)
1 x 2,50 $	Prix définitif de l’article :
2,50 $
 
	No Name Wieners Regular Original Hot Dogs (450 g)
1 x 4,29 $	Prix définitif de l’article :
4,29 $
 
PANTRY
	No Name Hazelnut Spread (725 g)
1 x 5,50 $	Prix définitif de l’article :
5,50 $
 
	Bertolli Extra Virgin Olive Oil (1000 ml)
1 x 16,00 $	Prix définitif de l’article :
16,00 $
 
Voir plus d’articles
   TOTAL DE LA COMMANDE

Sous-total des articles	84,10 $
Frais d’achat de sac à la caisse	1,75 $
Taxe sur les frais d’achat de sac à la caisse	0,23 $
Pourboire	1,68 $
Frais de service	9,25 $
Article HST	0,85 $
Service HST	1,20 $
Total en CAD	99,06 $
Livraison gratuite!	
   FRAIS MasterCard se terminant par 5018

Montant initial	95,30 $
Votre carte ApplePay a été temporairement autorisée pour un montant de 95,30 $. Le montant retenu devrait être annulé et le montant total facturé devrait figurer sur votre relevé dans les 7 jours ouvrables après l’exécution de la commande, selon la politique de votre banque.
En savoir plus
Montant d’ajustement	3,76 $
En savoir plus
Total facturé (CAD)	99,06 $
Livré(e) à yuniorrodriguezo460 , 136 Shaver Avenue North, Toronto ON M9B4N8


Évaluer votre commande

Obtenir de l’aide






Renseignements supplémentaires
Numéro d’inscription à la TPS/TVH d’Instacart : 81555 3920 RT0001
 
Invitez des amis, gagnez de l’argent
Obtenez 10 $ lorsque votre ami passe sa première commande Instacart – votre ami obtient aussi jusqu’à 10 $.
Des conditions s’appliquent.
Partager votre lien :
https://inst.cr/t/4df5902da
Ou :
Copier le code : Y5D0916
 Partager sur Facebook
 Partager sur WhatsApp

 iOS	 Android
 	 	 

Toutes les offres promotionnelles et les réductions sont soumises aux conditions d’utilisation d’Instacart. Des frais ou des pourboires pourraient s’appliquer.
Services de livraison fournis par Maplebear Delivery Canada Inc.
Instacart
50 Beale St. Suite 600. San Francisco, CA 94105
Web : https://www.instacart.ca
