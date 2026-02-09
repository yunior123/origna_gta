
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



      # Add tax as line item (already in cents)
        # NOTE: We calculate tax manually server-side
        # Stripe automatic_tax is DISABLED to avoid double taxation
        # TODO consider this automatic_tax


       