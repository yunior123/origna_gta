
## TODO (Active)

- Ensure schema constants are widely used
- Update json schema constants when database schema changes
- ChromeDriver compatibility for Flutter web integration tests
- check complience with https://fintrac-canafe.canada.ca/introduction/cpf/cpf-eng
- Potential Minor Issues:
Airwallex webhook secret is optional – if used, must enforce signature verification strictly (currently mirrors Stripe pattern but ensure it's not skipped when Airwallex enabled).
-TODO increase security Geoapify API key sent client-side? No – only backend. Safe.

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







TODO Add referrals links with 10 cad discount for friend and also the person that referred

TODO audit unsubscribre fro amrketing email, remove privacy@orignaventures.ca since it does not exist yet, only support gmail

TODO new feature, users should be able to chat with the sellers of each product

TODO The mascots, users should be able to chat with them

TODO Par contre, il n'y a pas de PDF invoice attaché — c'est un email HTML avec les détails du reçu. Si tu veux un PDF formel en pièce jointe, ça serait une feature à ajouter.

TODO 3. Est-ce qu'on envoie des emails avec les mises à jour de statut ?
Oui, mais pas pour TOUS les statuts. Voici la couverture actuelle :

Transition	Email envoyé ?	Template
pending → confirmed	✅	get_order_confirmation_email() (à la fin du checkout)
confirmed → processing	❌	Aucun email
processing → shipped	✅	get_order_shipped_email() + tracking
shipped → in_transit	❌	Aucun email
in_transit → delivered	✅	get_order_delivered_email() + reçu
→ cancelled	✅	get_order_cancelled_email() + raison
→ refunded	❌	Aucun email
→ partially_refunded	❌	Aucun email
→ expired	✅	send_authorization_expired_email() (cron job)
capture failed	✅	send_payment_capture_failed_email()
3DS required	✅	send_3ds_authentication_email()
Statuts manquants : processing, in_transit, refunded, partially_refunded. Tu veux que j'ajoute des templates pour ceux-ci ?

TODO try a single playwright test with buyer yunirrodriguezo4601 for yahoo, if the process actaully work, i should be able to see all of the email notifications of the process from begining till end. tip, use semantics if u have issues with canvas in flutter, search the web for it. 2. take a look at the skipped playwright tests