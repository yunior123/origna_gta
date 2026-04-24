# TODOS.md

Moved to `CORE.md`.

Use:
- `CORE.md` for the active workboard
- `STATE.md` for verified historical evidence and completed one-off items

Why:
- `TODOS.md` had become a mixed runbook + repo map + backlog + history file
- the active queue is now separated from historical proof



DONE:
- improve the way multiple ais work together and track progress to avoid them working on same issues on same time.
- audit sentry is working, use api key to diagnose, if full or something then restart sentry.
- update all md files in repo with latest info on project and internet. ex: stripe latest info and docs, meiljet,postgresql, sentry,... etc. make sure all ais working on the project via opencode, kilocode, codex, etc can read full repo map, agents.md and all project info and rules
- there is an issues when searching products in dev.orignagta.ca , it shows internal server error. 
- bugs found: 1. in product details it looks just fine except for one error: it says un error occurred, try later, its on the widget down the comments
- the estimated delivery says in prod orignagta that its for april 27, it should say delivery within 4-8 weeks or longer. also, it only says delivery to canada, delivery to cuba should be included.
- login and sign up by email are broken. google sign in/up too. search best practices for flutter and goolge and auth. debug whole thing. 
- 2. i dont see google sign in any longer, that is crazy.
- 3. in product details when recommending products the product cards for similar user bought products when showing the title and description the content looks like cutted, make it fit or just use ...
- 6. in web version the app is showing cart, notification, settings icons in the middle of appbar instead of right end.
- 9.new update: the google oauth is working in prod but: once we click continue to authorize we go back to login view where we were and nothing happens   
- 4. email sending keeps failing 
- the estimated delivery says in dev orignagta that delivery is 3-3 days . that is so crazy. make sure our system makes sense, search the web and github ecommerce for best practices, we are a mixture of amazon + instacart
- - in origna ventures email form is broken, right now not a single email is sent, not to origna ventures, not to client
- audit full flow of buying a product from beginning to payment successfully, email delivery, order status, tracking if possible, delivery.

- do basic live testing in prod with e2e to test payment flow in orignagta with the only product in prod db right now. u can use safari oscript with my yr62813@gmail.com account, im already logged in with that account so u just need to use my oauth profile to login via google then test all related to payment end to end till product delivery, u can create new .ts script e2e to target that if needed, if not use the current e2e test suite.

- test contact form emails being sent e2e. u can use real yr62813@gmail.com for testing

- verify that contact form emails are sent live as well as emails when payment succesful to clients and support@orignaventures.ca . audit stripe payments. do we have it covered if stripe sends the same event twice? how to handle or other common scenarios. make sure to  implement best practices. if u use yr62813@gmail.com for testing then make sure the confirmation email is sent too. update: there is at least one or two email in support inbox from contact which is greate, but not in yr62813... . also, make sure contract was removed properly, only privacy policy and terms pages to reflect our business.

- 5. when clicking categories it gives error, its crazy, solve the bugs and make sure the seeded data has all categories covered for testing. 
- it shows internal server error or something similar like something wrong try again. when tapping categories it says the same error. run e2e tests in there, add new tests if needed. fix all accordingly. i mean searching using search bar. make sure seeded products have all categories
- also, in dev.orignagta make sure there are seeded products for all categories.

- audit e2e that the card icon in home update when a new item is added. also audit all real time updates in app, not just the cart.
- remove dev, staging, beta banners in flutter



- make sure seeded products samples also contain build in canada feature, etc. we need to test the canada filter button and distinguish what was build in canada from the rest. make sure the real product for solar panels in prod right now is not appearing when tapping buildt in canada since its a product from china

- fetch rust docs, packages used in app best practices and create new skills based on that to debug failures in rust server based on dependencies, panic patterns, etc, also search github for common failures in rust servers isssues. Use the skill to audit the code. fix as needed

- bug: when clicking prix decroissont in filter the whole web reloads



NOT DONE:
Do all please, gonna out now, so do all work, use swarm if needed, when i get back all should be done. u can use bash sleep mechanism to wake yourself up, like a whip to keep yourself working. continue. do all . search web and github for latest and best practices of whatever u are working on, u can create new skills for it too. Use swarm with high and medium effort if needed. xchat is not working but u can use exa or other search tool. u can search state.md for history on regressions to avoid them, check memory too as needed. Solve bugs ans issues first

- build ios app to my connected phone 
- run all e2e tests, rust tests, flutter tests, priority goes to live tests
- make sure that all seeded products contain images 
- urgent: investor deck is broken with no images. investors are mad. make sure to regenerate with the 300+ screenshots from e2e live real,regenerate again after solving bugs and the other issues   

- 1. this one has happened like 100 plus times, when scrolling in home view dev.orignagta it says: un problem recurrent a survenu, it happens when scrolling products, update: still happening, this is fucking crazy, now it load full web including splash. update: it no longers says previews error but instead after scrolling too fast to the bottom it loads the whole web including splash
- priority, its urgent: images on all products 2. fucking scroll bug, why the fuck we have so many regression issues, make sure no deploy is done with out checking test for scroll regression passing, and that product seeded have images. 
- 8. add testing to prevent errors from happening again after solving. 
- weird bug in orignaventures website: when scrolling up it loads the whole web including splash, super weird.

Note: make sure to deploy latest version before e2e testing. commit and push after each issue verification


LATER:


- make sure that our error system is strong, we are supposed to have big table that contains error code vs stacktrace and bug or error info: ex. SE014587-Server Error -> The server failed on user login, this was the stacktrace...., this was the email... time... (internal only used with sentry and also logged in db). does it make sense? i have seen big companies do it like that, it allows users to give better feedback with error code, description, user contact info, ... . many big companies do it like that when the app crashes. to make sure we track all errors. sentry is also good.

- You are a senior DevOps/SRE engineer. Your task is to fully set up the
Postal open-source mail delivery server (https://postalserver.io) on our hetzner, Caddy
as reverse proxy, and Cloudflare as DNS provider. The goal is a
production-grade, inbox-landing transactional mail server for
password resets, order notifications, contact form emails, etc.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CONTEXT / ASSUMPTIONS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
- Domain managed on Cloudflare (DNS only, proxy OFF for mail subdomain)
- Caddy is already running as reverse proxy on the server (or will be)
- Caddy handles TLS automatically via Let's Encrypt
- Docker and Docker Compose plugin are installed (or will be installed)
- Server has a dedicated public IPv4 (clean, not blacklisted)
- Port 25 outbound is OPEN (confirm with: nc -zv smtp.gmail.com 25)
- We will use: mail.YOURDOMAIN.com as the Postal web UI + SMTP hostname
- Replace YOURDOMAIN.com with the real domain throughout all configs

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
STEP 1 — SERVER PREP
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. Update the system:
   apt update && apt upgrade -y

2. Install required packages:
   apt install -y git curl wget ufw net-tools dnsutils

3. Configure UFW firewall:
   ufw allow 22/tcp      # SSH
   ufw allow 80/tcp      # HTTP (Caddy ACME challenge)
   ufw allow 443/tcp     # HTTPS (Postal web UI via Caddy)
   ufw allow 25/tcp      # SMTP (inbound/outbound mail)
   ufw allow 465/tcp     # SMTPS
   ufw allow 587/tcp     # SMTP submission
   ufw allow 5000/tcp    # Postal internal web (only if not behind Caddy)
   ufw enable

4. Set the server hostname to match the mail subdomain:
   hostnamectl set-hostname mail.YOURDOMAIN.com
   # Also update /etc/hosts:
   echo "127.0.0.1 mail.YOURDOMAIN.com" >> /etc/hosts

5. Verify port 25 is not blocked by provider:
   nc -zv smtp.gmail.com 25
   # If blocked, contact your VPS provider (Hetzner/Vultr/DigitalOcean
   # all allow it after a support request)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
STEP 2 — INSTALL DOCKER (if not present)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
curl -fsSL https://get.docker.com | sh
# Verify:
docker --version
docker compose version

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
STEP 3 — INSTALL POSTAL
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Use the official Postal installer:

git clone https://github.com/postalserver/install /opt/postal/install
ln -s /opt/postal/install/bin/postal /usr/bin/postal

Create required directories:
mkdir -p /opt/postal/config

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
STEP 4 — MARIADB CONTAINER (Postal's database)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Run MariaDB as a standalone container first (Postal's recommended approach):

docker run -d \
  --name postal-mariadb \
  -p 127.0.0.1:3306:3306 \
  --restart always \
  -e MARIADB_DATABASE=postal \
  -e MARIADB_ROOT_PASSWORD=REPLACE_WITH_STRONG_PASSWORD \
  mariadb:10.11

Wait ~10 seconds for it to initialize, then verify:
  docker ps | grep postal-mariadb

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
STEP 5 — POSTAL CONFIG FILE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Generate the initial config:
  postal bootstrap mail.YOURDOMAIN.com

This creates /opt/postal/config/postal.yml. Now edit it:

Open /opt/postal/config/postal.yml and set the following values
(leave everything else at defaults unless noted):

---
# /opt/postal/config/postal.yml

web:
  host: mail.YOURDOMAIN.com
  protocol: https       # Caddy handles TLS

main_db:
  host: 127.0.0.1
  username: root
  password: REPLACE_WITH_STRONG_PASSWORD   # same as MariaDB above
  database: postal

message_db:
  host: 127.0.0.1
  username: root
  password: REPLACE_WITH_STRONG_PASSWORD
  prefix: postal

rabbitmq:
  host: 127.0.0.1
  username: postal
  password: REPLACE_WITH_RABBITMQ_PASSWORD
  vhost: /postal

smtp_server:
  port: 25
  tls_enabled: true
  tls_certificate_path: /etc/caddy/certificates/acme-v02.api.letsencrypt.org-directory/mail.YOURDOMAIN.com/mail.YOURDOMAIN.com.crt
  tls_private_key_path: /etc/caddy/certificates/acme-v02.api.letsencrypt.org-directory/mail.YOURDOMAIN.com/mail.YOURDOMAIN.com.key

dns:
  mx_records:
    - mail.YOURDOMAIN.com
  smtp_server_hostname: mail.YOURDOMAIN.com
  spf_include: spf.postal.YOURDOMAIN.com
  return_path: rp.postal.YOURDOMAIN.com
  route_domain: routes.postal.YOURDOMAIN.com
  track_domain: track.postal.YOURDOMAIN.com

logging:
  rails_log_enabled: true
  sentry_dsn:          # leave blank unless you use Sentry

---

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
STEP 6 — RABBITMQ CONTAINER
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
docker run -d \
  --name postal-rabbitmq \
  -p 127.0.0.1:5672:5672 \
  --restart always \
  -e RABBITMQ_DEFAULT_USER=postal \
  -e RABBITMQ_DEFAULT_PASS=REPLACE_WITH_RABBITMQ_PASSWORD \
  -e RABBITMQ_DEFAULT_VHOST=/postal \
  rabbitmq:3.12-management

Verify: docker ps | grep postal-rabbitmq

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
STEP 7 — INITIALIZE AND START POSTAL
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Initialize the database schema:
postal initialize

# Create the first admin user (follow prompts):
postal make-user

# Start all Postal services:
postal start

# Verify all services running:
postal status

# View logs if anything is wrong:
postal logs

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
STEP 8 — CADDY REVERSE PROXY CONFIG
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Add this block to your existing Caddyfile
(usually at /etc/caddy/Caddyfile or /opt/caddy/Caddyfile):

mail.YOURDOMAIN.com {
    reverse_proxy localhost:5000

    # Optional basic auth for extra security on web UI:
    # basicauth /* {
    #   admin JDJhJDE0JHh4eHh4eHh4eHh4eA==
    # }

    log {
        output file /var/log/caddy/postal.log
    }
}

Then reload Caddy:
  caddy reload --config /etc/caddy/Caddyfile
  # or: systemctl reload caddy

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
STEP 9 — CLOUDFLARE DNS RECORDS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Log into Cloudflare → your domain → DNS.
CRITICAL: Set ALL mail-related records to "DNS only" (grey cloud),
NOT proxied (orange cloud). Cloudflare proxy BREAKS SMTP.

Add these records (replace 1.2.3.4 with your server's real IP,
and replace DKIM_PUBLIC_KEY_HERE with the key Postal generates in Step 10):

TYPE    NAME                          VALUE                                   PROXY
----    ----                          -----                                   -----
A       mail                          1.2.3.4                                 DNS only
MX      @                             mail.YOURDOMAIN.com (priority 10)       DNS only
TXT     @                             v=spf1 a mx include:mail.YOURDOMAIN.com ~all   DNS only
TXT     postal._domainkey             v=DKIM1; k=rsa; p=DKIM_PUBLIC_KEY_HERE  DNS only
TXT     _dmarc                        v=DMARC1; p=quarantine; rua=mailto:dmarc@YOURDOMAIN.com; adkim=r; aspf=r   DNS only
TXT     rp.postal                     v=spf1 a: mail.YOURDOMAIN.com ~all      DNS only

# For tracking (opens/clicks) — optional but recommended:
CNAME   track.postal                  mail.YOURDOMAIN.com                     DNS only

NOTES:
- SPF: Start with ~all (softfail) for testing, change to -all (hardfail)
  once everything is confirmed working
- DMARC: Start with p=none to just monitor, then move to p=quarantine,
  then p=reject once you've verified legitimate mail passes

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
STEP 10 — PTR / REVERSE DNS RECORD
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
This is CRITICAL for inbox delivery. Without it, Gmail and others
will reject or spam-folder your email.

Go to your VPS provider's control panel:
- Hetzner: Server → IPs → Reverse DNS
- DigitalOcean: Networking → Droplets → rename droplet to mail.YOURDOMAIN.com
- Vultr: Settings → IPv4 → Reverse DNS

Set PTR for your IP 1.2.3.4 → mail.YOURDOMAIN.com

Verify after ~5 min:
  dig -x 1.2.3.4

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
STEP 11 — CONFIGURE POSTAL WEB UI + DKIM
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. Open https://mail.YOURDOMAIN.com in browser
2. Log in with the admin credentials you created in Step 7
3. Create an Organization (e.g. "My Company")
4. Create a Mail Server (e.g. "Production")
5. Inside the Mail Server → Domains → Add Domain → YOURDOMAIN.com
6. Postal will show you the DNS records to add, INCLUDING:
   - The DKIM public key (postal._domainkey TXT record)
   - Return-path record
   Copy these and add them to Cloudflare DNS (from Step 9)
7. Click "Check DNS" in Postal UI — wait for all green ticks
8. Create an SMTP Credential (API Key) under Credentials tab

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
STEP 12 — FINAL TESTING (ALL MUST PASS)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

TEST 1 — Send a test email via swaks (SMTP test tool):
  apt install -y swaks
  swaks \
    --to test@gmail.com \
    --from noreply@YOURDOMAIN.com \
    --server mail.YOURDOMAIN.com \
    --port 587 \
    --auth LOGIN \
    --auth-user YOUR_POSTAL_SMTP_USER \
    --auth-password YOUR_POSTAL_SMTP_PASSWORD \
    --tls \
    --header "Subject: Postal Test Email" \
    --body "If you receive this, Postal is working correctly."

TEST 2 — mail-tester.com (THE most important test):
  Go to https://www.mail-tester.com
  Copy the unique test email address shown (e.g. test-abc123@srv1.mail-tester.com)
  Send an email TO that address from your Postal server using swaks above
  Go back and click "Check your score"
  TARGET: 10/10 score
  Any score below 8 — fix the issues listed before going to production

TEST 3 — MXToolbox full check:
  https://mxtoolbox.com/SuperTool.aspx
  Run: "mail.YOURDOMAIN.com" → Check MX, DKIM, SPF, DMARC, Blacklist

TEST 4 — Check if IP is blacklisted:
  https://mxtoolbox.com/blacklists.aspx
  Enter your server IP → should show 0 blacklists

TEST 5 — Verify SPF, DKIM, DMARC via email headers:
  Send a test email to a Gmail address you control
  In Gmail: Open email → three dots → "Show original"
  Verify:
    SPF:  PASS
    DKIM: PASS
    DMARC: PASS
  All three must show PASS for reliable inbox delivery

TEST 6 — Port 25 connectivity test:
  telnet mail.YOURDOMAIN.com 25
  # Should see: 220 mail.YOURDOMAIN.com ESMTP Postal

TEST 7 — DNS propagation check:
  dig TXT YOURDOMAIN.com         # Should show SPF record
  dig TXT postal._domainkey.YOURDOMAIN.com  # Should show DKIM
  dig TXT _dmarc.YOURDOMAIN.com  # Should show DMARC policy
  dig MX YOURDOMAIN.com          # Should show mail.YOURDOMAIN.com
  dig -x YOUR_SERVER_IP          # Should resolve to mail.YOURDOMAIN.com

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
STEP 13 — IP WARM-UP STRATEGY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
New IPs have no sending reputation. Do NOT blast 10,000 emails on day 1.
Follow this gradual warm-up schedule:

Day 1-2:    50 emails/day
Day 3-4:    100 emails/day
Day 5-7:    500 emails/day
Week 2:     2,000 emails/day
Week 3:     10,000 emails/day
Week 4+:    Full volume

Monitor bounce rates in the Postal web UI. If bounce rate > 2%, slow down.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
STEP 14 — PRODUCTION HARDENING CHECKLIST
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] PTR record set and verified (dig -x YOUR_IP)
[ ] SPF record exists and includes your mail server IP
[ ] DKIM signing active and DNS record published
[ ] DMARC record published (start p=none, move to p=reject)
[ ] Cloudflare proxy OFF for all mail-related DNS records
[ ] TLS certificate valid on port 25 and 587
[ ] Postal web UI accessible only via HTTPS
[ ] MariaDB and RabbitMQ only listening on 127.0.0.1 (not public)
[ ] Bounce handling configured in Postal UI
[ ] Webhook endpoint configured for your app (if needed)
[ ] mail-tester.com score = 10/10
[ ] Zero blacklist hits on MXToolbox

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
STEP 15 — CONNECTING YOUR APP TO POSTAL
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Use these SMTP settings in your app (Laravel, Node, Django, etc.):

  MAIL_HOST=mail.YOURDOMAIN.com
  MAIL_PORT=587
  MAIL_USERNAME=<credential from Postal UI>
  MAIL_PASSWORD=<credential from Postal UI>
  MAIL_ENCRYPTION=tls
  MAIL_FROM_ADDRESS=noreply@YOURDOMAIN.com
  MAIL_FROM_NAME="Your App Name"

Or use the Postal HTTP API:
  POST https://mail.YOURDOMAIN.com/api/v1/send/message
  Header: X-Server-API-Key: REDACTED_SECRET
  Body (JSON):
  {
    "from": "noreply@YOURDOMAIN.com",
    "to": ["user@example.com"],
    "subject": "Password Reset",
    "html_body": "<p>Click here to reset your password...</p>"
  }

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TROUBLESHOOTING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
- Postal logs:        postal logs
- Check all services: postal status
- Restart Postal:     postal stop && postal start
- MariaDB shell:      docker exec -it postal-mariadb mysql -u root -p postal
- Port 25 blocked:    Contact VPS provider support, request SMTP unblock
- Still going to spam:
    1. Check mail-tester.com score and fix each issue
    2. Verify PTR record (most common cause)
    3. Check IP on Spamhaus: https://check.spamhaus.org
    4. Make sure SPF/DKIM/DMARC all pass in Gmail "Show original"
    5. Check Postal bounce logs for rejection messages

Official docs: https://docs.postalserver.io
GitHub: https://github.com/postalserver/postal
