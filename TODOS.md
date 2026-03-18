
 E. MFA for all users 

 - Requires: MFA challenge screen in Flutter, TOTP setup onboarding flow, backup code management
 - ~2-3 day effort across frontend + backend
 - Currently admin-only is acceptable for pre-launch

 F. Suspicious login detection 

 - Requires: IP geolocation service, device fingerprinting, notification system
 - Nice-to-have, not blocking launch

 G. File signature validation on uploads 

 - Low risk: uploads go through OrignaBase → R2, not executed server-side
 - Can add magic-byte check in OrignaBase upload handler later
