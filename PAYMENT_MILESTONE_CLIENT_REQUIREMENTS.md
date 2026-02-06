# Payment Milestone (QR Code + NFC Card + Palm Vein) — Client Requirements (Payment Only)

This document lists what we need from you (the client) to complete payment integration for these three in-store identification methods:

- QR Code
- NFC Card
- Palm Vein

Assumptions (based on your latest clarification):

- **All payments are charged via Bank Card** (no wallet payments).
- Card details are **tokenized by the backend** and stored as a **token** (no raw PAN/CVV storage).
- Hardware details are already known and provided separately, so this document excludes hardware-specific requirements.

---

## 1) Decisions we need you to confirm (business rules)

1. **Confirmation mode**
   - **Phone confirmation required** (customer approves payment on phone), or
   - **Phone-free** (POS completes payment after QR/NFC/palm), or
   - **Hybrid** (confirmation required above a threshold amount).

2. **Supported markets**
   - Countries, currencies, timezone, language(s).

3. **Refund policy**
   - Are refunds supported at all?
   - Full refunds only, or partial refunds also?
   - Who can refund (cashier, manager, admin)?
   - Refund time limit (same day, 7 days, etc.).

4. **Receipts & notifications**
   - Single store vs multi-store,
   - Receipt requirements (print/email/SMS/push notification),
   - What should appear on the receipt (merchant name, location, VAT/tax number, etc.).

---

## 2) Payment provider requirements (card charging)

Provide the following (Sandbox/UAT and Production), shared securely:

- Payment provider name
- Provider integration mode for charging: backend-to-provider (recommended)
- Test credentials and production credentials (keys/tokens as applicable)
- 3D Secure requirement and target regions
- Statement descriptor / business name shown on card statement
- Supported card schemes and currencies
- Settlement expectations (payout schedule, settlement currency, fee model)

If card details are already stored:

- Confirm token type and lifecycle (expiry/rotation, re-tokenization rules)
- Confirm how a token becomes “expired/invalid” and what the user experience should be (re-add card, retry, etc.)

### What “Sandbox/UAT access” means (simple explanation)

Sandbox/UAT is a **testing environment** provided by the payment provider where we can:

- Use **test API keys** and **test merchant accounts**
- Use **test cards** that simulate approvals/declines/3DS flows
- Verify the full payment journey end-to-end **without moving real money**
- Run UAT scenarios before going live, then switch to **live keys** for production

Some providers call this “Sandbox”, “Test mode”, or “UAT”. Functionally, it’s the safe place to test payments before production.

### Possible payment providers (examples)

The best provider depends on your country, acquiring bank, and whether you need **in-store contactless (NFC/EMV)** support on your POS device. Common options include:

- **Payment gateways (online charging/tokenization):** Stripe, Adyen, Checkout.com, Worldpay, Braintree (PayPal), Paystack, Flutterwave
- **Enterprise acquiring/processing platforms:** Fiserv, Global Payments/TSYS, Network International, local acquiring banks/processors
- **In-store contactless (NFC/EMV) stacks:** usually provided by the POS vendor/acquirer as a certified EMV solution (not generic “read NFC”)

If you already have an acquiring bank/processor for in-store contactless, we will align with that choice.

---

## 3) Method-specific requirements (what we need you to define)

### 3.1 QR Code payments

- QR code is accessed after login. If a user loses a phone, they can sign in on another phone and access the same QR code.
- Confirm whether QR can also be printed as a physical card (optional).
- Whether QR payments are phone-free (POS-only) or require phone confirmation.

### 3.2 NFC Card payments

- NFC payments will use **bank card contactless (EMV tap-to-pay)**.
- Confirm supported flows on the POS device:
  - Contactless magnetic-stripe mode (if applicable)
  - EMV contactless
  - 3DS is typically not used for in-store EMV; risk controls are handled by EMV/acquirer rules
- Confirm supported card schemes (Visa/Mastercard/etc.) and any regional constraints.

### 3.3 Palm Vein payments

- Customer **must enroll palm before any palm payment**
- Palm payment **must be blocked** if card token is missing/expired
- Risk controls to confirm:
  - Max amount allowed without phone confirmation (if you want hybrid)
  - Retry limits and lockout policy after failed attempts

---

## 4) Security and compliance requirements (client-owned)

- Raw card numbers must not be stored in the mobile app or logs
- Card handling uses provider tokenization, so the app/backend never stores PAN/CVV
- Logs must redact sensitive identifiers (tokens, full QR payloads, etc.) in production
- Fraud/risk expectations:
  - 3DS requirement
  - Velocity limits (max transactions per minute/hour/day)
  - Amount caps per user/store

---

## 5) What we need from you for testing and go-live

- Sandbox/UAT access for payment provider (or test credentials via your team)
- Test cards / test customer profiles (provider-supplied test instruments)
- A clear set of acceptance scenarios:
  - Approved payment
  - Declined payment
  - Insufficient funds (if applicable)
  - Timeout / customer cancel
  - Duplicate prevention (double tap / double scan)
- Refund testing scenarios (if refunds are in scope)
- Named contacts:
  - Business decision maker (confirmation mode, thresholds, refunds)
  - Operations/support contact for payment incidents

---

## 6) What we will deliver in this milestone (high level)

- QR-based payment flow working end-to-end (scan QR → charge stored bank card → show result)
- NFC Card payment flow working end-to-end (tap NFC → charge stored bank card → show result)
- Palm vein payment flow working end-to-end (scan palm → charge stored bank card → show result)
- Clear UI states and failure messages for each method
- Receipt payload handling (and printing if a printer is available and required)
