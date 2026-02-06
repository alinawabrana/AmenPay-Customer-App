# Customer App (Mobile) — Simple Feature Guide
This document explains, in simple English, what the Customer App does. The Customer App is the mobile application used by customers to create an account, manage their details, and use payment methods like QR code, NFC, and palm vein.

## 1) Who uses this app?
- Customers (end users)

## 2) What problems does it solve?
- Lets customers register and sign in.
- Lets customers store a payment method and present it in a safe way at a store.
- Lets customers enroll their palm vein (first-time setup) using a store/POS device.

## 3) Main features in the Customer App
### 3.1 Account creation and sign in
- Create a new account with basic details.
- Sign in with email and password.
- Stay logged in using a saved session (so the user does not need to sign in every time).

### 3.2 Profile management
- View personal profile information.
- Edit profile details.

### 3.3 Add a payment card (customer-side)
- Add a card inside the app (so it can later be used for payments).
- The system is designed so the real card number should not be exposed unnecessarily.

### 3.4 Payment methods screen (Customer view)
The app shows the customer the available payment methods and their status:
- QR Code (available)
- NFC Card (shows active/inactive)
- Palm Vein (shows enrolled/not enrolled)

### 3.5 “My QR Code” screen (customer payment QR)
- Shows the customer’s QR code on screen.
- This QR code is meant to be scanned by the cashier/POS device during payment.
- Customers can also save/share/print the QR (buttons exist in the UI).

## 4) Palm vein enrollment (customer experience)
Palm vein enrollment is a one-time setup that links the customer account to a palm template.

What the customer does:
- Opens the “Palm Vein” section in the app.
- Starts enrollment and shows a special enrollment QR on screen.
- Goes to a store/POS device and lets the cashier/POS scan that enrollment QR.
- Places their palm on the palm scanner device when instructed.
- Waits for the app to confirm enrollment is complete.

Important note (privacy):
- The system is designed so the palm image is not stored.
- Only a secure “template reference” is stored for matching/enrollment.

## 5) What the customer app does NOT do
- It does not control the palm scanner hardware directly.
- It does not read from the POS serial scanner.
- Hardware work happens in the cashier/POS app on the POS device.

## 6) Current status (what is ready vs what is next)
### Ready in the current app UI
- Sign up, sign in, logout
- Profile view/edit
- Payment methods screens
- Customer QR display screen
- Palm vein screens (UI)

### Typically required next for full palm enrollment flow
- Generate an enrollment session from backend and show the enrollment QR.
- Automatically update the screen when the POS completes the enrollment (status polling).

