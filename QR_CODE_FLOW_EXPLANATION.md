# QR Code Flow Explanation
## Palm Vein, NFC & QR Based Payment System

---

## Overview

This document explains how QR codes work in the payment system, including generation, assignment, and usage flows.

---

## Key Questions Answered

### 1. Are QR codes auto-created for new customers?

**YES** ✅

QR codes are **automatically generated** by the backend when a customer completes registration. The process is:

1. Customer fills out registration form
2. Registration data is sent to backend
3. Backend creates user account
4. **Backend automatically generates a unique QR code** for the customer
5. QR code is stored in the database, linked to the user's account
6. QR code data is returned to the customer app (if needed)

**Important Points:**
- QR code generation happens **automatically** - no manual action required
- Each customer gets **one unique QR code** that remains constant
- QR code is **not transaction-specific** - it's linked to the customer's account
- QR code can be used for **all future payments**

---

## Complete QR Code Flow

### Phase 1: QR Code Generation (During Registration)

```
Customer Registration
         │
         ▼
Backend Creates User Account
         │
         ▼
Backend Generates Unique QR Code
         │
         ├─── Contains: User ID, Account Number, Encrypted Data
         │
         ▼
QR Code Stored in Database
         │
         └─── Linked to User Account
```

**What the QR Code Contains:**
- User identification (User ID)
- Account information (Account Number)
- Encrypted/encoded data for security
- Format: Structured data that can be decoded by the system

---

### Phase 2: Customer QR Code Access

After registration, customers can:

1. **View QR Code in App**
   - Navigate to "My QR Code" section
   - QR code is fetched from backend
   - Displayed as an image on screen

2. **Save QR Code**
   - Save as image to phone gallery
   - Can be printed
   - Can be shared (if needed)

3. **Use for Payments**
   - Display QR code on phone screen
   - Or show printed QR code card
   - Cashier scans it during payment

---

### Phase 3: Payment Process Using QR Code

```
┌─────────────────────┐
│  Payment Initiated  │
│  (Cashier enters    │
│   amount)           │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Payment Method:   │
│  QR Code Selected  │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Customer Shows     │
│  QR Code            │
│  - On Phone Screen  │
│  - Or Printed Card  │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Cashier Uses       │
│  Hardware Scanner   │
│  (Serial Port)      │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  QR Code Scanned    │
│  - Data Extracted   │
│  - User ID Retrieved│
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Payment Request    │
│  Sent to Backend    │
│  - User ID (from QR) │
│  - Amount           │
│  - Transaction Info │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Backend Validates  │
│  - Verifies QR Code │
│  - Checks User      │
│  - Validates Balance│
│  - Processes Payment│
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Payment Result    │
│  - Success/Failed  │
└─────────────────────┘
```

---

## Technical Details

### QR Code Format

The QR code contains structured data that includes:
- **User Identifier**: Unique ID to identify the customer
- **Account Information**: Account number or reference
- **Security Data**: Encrypted/encoded information for validation
- **Format**: Standard QR code format (can be scanned by hardware scanner)

### Hardware Integration

- **Scanner Type**: Serial Port Scanner (hardware device)
- **Port**: `/dev/ttyHSL3`
- **Baud Rate**: 9600
- **Communication**: Native Android (Kotlin) reads from serial port
- **Data Flow**: Scanner → Native SDK → Platform Channel → Flutter → Backend

### Security Considerations

1. **QR Code Validation**
   - Backend validates QR code format
   - Verifies QR code is active and linked to valid user
   - Checks if QR code has been revoked/deactivated

2. **Data Protection**
   - QR code data is encrypted/encoded
   - No sensitive payment information in QR code
   - User ID is used to fetch account details from secure backend

3. **Transaction Security**
   - Each payment requires backend authorization
   - Balance checks before processing
   - Transaction logging for audit trail

---

## Comparison with Other Payment Methods

| Feature | Palm Vein | NFC Card | QR Code |
|---------|-----------|----------|---------|
| **Setup Required** | Enrollment needed | Card registration | Auto-generated |
| **Customer Action** | Place palm | Tap card | Show QR code |
| **Hardware** | Camera scanner | NFC reader | Serial scanner |
| **Uniqueness** | Biometric | Card UID | User-specific |
| **Persistence** | Permanent | Card-based | Account-linked |

---

## Customer Experience

### First-Time Customer Journey

1. **Registration**
   - Fill out registration form
   - Submit to backend
   - ✅ QR code automatically created

2. **Access QR Code**
   - Login to customer app
   - Navigate to "My QR Code"
   - View/save QR code

3. **First Payment**
   - Go to merchant
   - Show QR code (phone or printed)
   - Cashier scans → Payment processed

### Returning Customer Journey

1. **Payment at Merchant**
   - Cashier enters amount
   - Selects "QR Code" payment method
   - Customer shows QR code
   - Cashier scans → Payment complete

---

## Backend Requirements

For QR code functionality, the backend must:

1. **QR Code Generation**
   - Generate unique QR code during user registration
   - Store QR code data linked to user account
   - Format: Structured data (JSON, encoded string, etc.)

2. **QR Code Validation**
   - API endpoint to validate scanned QR code
   - Verify QR code belongs to active user
   - Return user information for payment processing

3. **QR Code Management**
   - Ability to regenerate QR code (if needed)
   - Ability to deactivate QR code (security)
   - QR code history/audit trail

4. **Payment Processing**
   - Accept payment request with user ID (from QR)
   - Validate user account
   - Process payment transaction
   - Return payment result

---

## Summary

✅ **QR codes are AUTO-GENERATED** when customers register  
✅ **One QR code per customer** - remains constant  
✅ **Customer can view/save** QR code in the app  
✅ **Cashier scans QR code** using hardware scanner  
✅ **Backend validates** QR code and processes payment  
✅ **Secure** - QR code contains user ID, not sensitive payment data  

The QR code serves as a **digital identity token** that links the physical QR code to the customer's account in the backend system.

---

**Document Version:** 1.0  
**Last Updated:** [Current Date]  
**Related Documents:** APP_FLOW.md, CLIENT_PROJECT_PROPOSAL.md

