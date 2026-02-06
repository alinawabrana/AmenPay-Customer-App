# Cashier / POS App — Simple Feature Guide
This document explains, in simple English, what the Cashier / POS App does. The Cashier App is used by a shop cashier (or the store’s POS device) to accept payments and to help customers enroll their palm vein.

## 1) Who uses this app?
- Cashiers and store staff
- It runs on a POS terminal (a store device), not on the customer’s phone

## 2) What problems does it solve?
- Helps a cashier quickly identify a customer (by scanning QR or palm/NFC).
- Supports a fast checkout experience.
- Helps customers complete palm vein enrollment at the store device.

## 3) Main features in the Cashier / POS App
### 3.1 Scan customer QR code (for payments)
- The customer shows their QR code on their phone (or a printed QR).
- The cashier scans it using the POS scanner (or camera if needed).
- The POS app reads the QR and uses it to identify the customer in the system.

### 3.2 Palm vein enrollment (in-store setup)
This is the in-store process to register a customer’s palm vein so they can later pay using palm scan.

Typical steps:
- Customer opens the enrollment QR on the customer app.
- Cashier scans the enrollment QR on the POS device.
- POS device starts the palm enrollment process on the palm scanner hardware.
- Customer places their palm on the scanner.
- POS device receives an enrollment result and securely submits it to the backend.
- Customer app shows “Enrollment complete”.

### 3.3 Palm vein payment (future / depends on backend scope)
- Customer places palm on the scanner to confirm identity.
- POS app would request payment approval from the backend and show success/failure.

### 3.4 NFC card payment (optional)
- Customer taps an NFC card on the POS reader.
- POS app reads the card and requests approval from the backend.

### 3.5 Payment confirmation (for cashier)
- Shows clear status messages:
  - “Scan successful”
  - “Processing”
  - “Payment approved / declined”
  - “Enrollment completed / failed”
- Provides simple error messages when something goes wrong (example: invalid QR, expired session, low scan quality).

## 4) Hardware used by the Cashier / POS App
The POS app is the hardware-facing app. Depending on the POS terminal model, it can connect to:
- QR scanner (often a built-in serial scanner)
- Palm vein scanner device
- NFC reader (if available on the terminal)
- Printer (optional, if receipts are needed)

## 5) Security and privacy (important for client understanding)
- The system is designed so palm images are not stored.
- The POS device receives a secure enrollment result (a template reference), not a photo of the palm.
- The POS device should not display or store sensitive identifiers unnecessarily.

## 6) Current status (what is ready vs what is next)
### Ready according to the system documentation
- POS can scan the enrollment QR, run palm enrollment on the device, and submit the result to the backend.

### Typically required to complete the cashier payment experience
- Final payment processing screens (amount entry, confirmation, receipts).
- Backend endpoints for full payment authorization and transaction history (if not already available).

