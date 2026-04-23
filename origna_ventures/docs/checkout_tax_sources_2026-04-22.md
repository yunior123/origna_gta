# OrignaVentures Checkout Tax Sources

Date: 2026-04-22

Purpose: document the primary sources used to evaluate the OrignaVentures Stripe Checkout tax-ID flow and the TODO claiming that a Canadian business number should automatically result in 0 tax.

## Stripe

1. Stripe Docs: Collect customer tax IDs with Checkout
   URL: https://docs.stripe.com/tax/checkout/tax-ids
   Used for:
   - confirming Checkout supports `tax_id_collection[enabled]`
   - confirming Checkout can collect a Canadian GST/HST number (`ca_gst_hst`)
   - confirming Checkout only validates tax-ID format during Checkout
   - confirming collected tax IDs are available on the completed Checkout Session under `customer_details.tax_ids`

2. Stripe Docs: Automatically collect tax on Checkout sessions
   URL: https://docs.stripe.com/payments/checkout/automatic_taxes
   Used for:
   - confirming `automatic_tax[enabled]` is the supported Stripe Checkout path
   - confirming tax is calculated from the customer address collected in Checkout
   - confirming customer creation / address handling behavior for Checkout tax calculation

3. Stripe Docs: Create a Checkout Session
   URL: https://docs.stripe.com/api/checkout/sessions/create
   Used for:
   - confirming Checkout creates a Customer automatically in `subscription` mode
   - confirming `customer_creation=always` is only set in `payment` mode
   - confirming the server-side payload shape for Checkout Sessions

4. Stripe Docs: Tax in Canada
   URL: https://docs.stripe.com/tax/supported-countries/canada
   Used for:
   - confirming Stripe Tax supports Canadian tax calculation and reporting
   - confirming Canadian federal/provincial tax handling is address- and rules-based, not a blanket business-number exemption

5. Stripe Docs: Collect taxes / advanced tax
   URL: https://docs.stripe.com/payments/advanced/tax
   Used for:
   - confirming Stripe’s supported tax ID table marks `ca_gst_hst` as affecting tax calculation
   - confirming tax-ID format validation alone is not the same as legal eligibility for a tax-free transaction

## Canada Revenue Agency / Canada.ca

1. Canada.ca: Charge and collect the GST/HST - type of supply
   URL: https://www.canada.ca/en/revenue-agency/services/tax/businesses/topics/gst-hst-businesses/charge-collect-type-supply.html
   Used for:
   - confirming supplies are taxable, zero-rated, or exempt
   - confirming 0% treatment depends on supply classification, not merely on the purchaser being a business

2. Canada.ca: GST/HST and place-of-supply rules
   URL: https://www.canada.ca/en/revenue-agency/services/tax/businesses/topics/gst-hst-businesses/charge-collect-place-supply.html
   Used for:
   - confirming Canadian GST/HST rates depend on where the supply is made
   - confirming Ontario HST example logic is location-based

3. Canada.ca: Input tax credits
   URL: https://www.canada.ca/en/revenue-agency/services/tax/businesses/topics/gst-hst-businesses/complete-file-input-tax-credit.html
   Used for:
   - confirming GST/HST registrants generally recover GST/HST paid on business purchases through input tax credits
   - supporting the conclusion that a registered business is not automatically tax-free at checkout

4. Canada.ca: General Information for GST/HST Registrants
   URL: https://www.canada.ca/en/revenue-agency/services/forms-publications/publications/rc4022/general-information-gst-hst-registrants.html
   Used for:
   - confirming sellers still have to account for GST/HST if they fail to collect it from someone falsely claiming exemption
   - supporting the decision not to implement a blanket “enter business number = 0 tax” rule

5. Canada.ca: Confirming a GST/HST account number
   URL: https://www.canada.ca/en/revenue-agency/services/e-services/digital-services-businesses/confirming-a-gst-hst-account-number.html
   Used for:
   - confirming GST/HST registration status can matter in limited contexts
   - confirming there are registry-driven cases where evidence of registration can affect whether tax is charged, but this is narrower than a blanket "business number = no tax" rule
   - distinguishing “registered business” verification from a broad exemption rule

## Decision Supported By These Sources

- Keep Stripe Checkout `automatic_tax[enabled]` and `tax_id_collection[enabled]`.
- Do not implement a blanket rule that entering a Canadian business number or GST/HST number automatically forces tax to `0`.
- Persist the Stripe-collected business/tax details from completed Checkout Sessions for auditability and future policy work.

## Practical Conclusion

- A Canadian business number or GST/HST number is not, by itself, enough to justify forcing checkout tax to `0` for all OrignaVentures purchases.
- The safer implementation is the one now live:
  - let Stripe collect address + tax ID
  - let Stripe Tax calculate the amount
  - keep any special tax treatment tied to an explicit, documented policy case instead of a blanket frontend/backend shortcut
- For Canadian GST/HST registrants buying taxable supplies, CRA guidance points to input tax credits as the normal recovery path rather than a universal point-of-sale exemption.
