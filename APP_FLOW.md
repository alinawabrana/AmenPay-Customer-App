# Palm Vein, NFC & QR Based Payment System
## Application Flow Documentation

---

## Table of Contents

1. [Overview](#overview)
2. [Customer Application Flow](#customer-application-flow)
3. [Cashier/POS Application Flow](#cashierpos-application-flow)
4. [Payment Method Flows](#payment-method-flows)
5. [Dual Screen Flow](#dual-screen-flow)
6. [Error Handling Flows](#error-handling-flows)
7. [Integration Points](#integration-points)

---

## Overview

This document provides detailed application flow diagrams and step-by-step user journeys for the Palm Vein, NFC & QR Based Payment System. The system consists of two main applications:

1. **Customer Application**: For end-users to register, enroll biometrics, and manage transactions
2. **Cashier/POS Application**: For merchants to process payments through multiple methods

---

## Customer Application Flow

### 1. Application Launch & Initialization

```
┌─────────────────┐
│   App Launch     │
└────────┬─────────┘
         │
         ▼
┌─────────────────┐
│  Splash Screen  │
│  (2.5 seconds)  │
└────────┬─────────┘
         │
         ▼
┌─────────────────┐
│  Device Check   │
│  - Hardware     │
│  - Connectivity │
└────────┬─────────┘
         │
         ▼
    ┌────────┐
    │ Valid? │
    └───┬────┘
        │
    Yes │  No
        │    │
        │    ▼
        │ ┌──────────────┐
        │ │ Error Screen │
        │ │ (Retry/Exit) │
        │ └──────────────┘
        │
        ▼
┌─────────────────┐
│  Check Session  │
│  (Token Valid?)  │
└────────┬─────────┘
         │
    ┌────┴────┐
    │         │
  Yes│       │No
    │         │
    ▼         ▼
┌─────────┐ ┌──────────────┐
│ Main    │ │ Welcome/Login │
│ Screen  │ │   Screen      │
└─────────┘ └──────────────┘
```

### 2. First-Time User Registration Flow

```
┌──────────────────┐
│  Welcome Screen  │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Create Account  │
│  Button Clicked  │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ Registration Form│
│ - Name           │
│ - Email          │
│ - Phone          │
│ - Password       │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Form Validation │
└────────┬─────────┘
         │
    ┌────┴────┐
    │         │
 Valid│     │Invalid
    │         │
    ▼         ▼
┌─────────┐ ┌──────────────┐
│ Submit  │ │ Show Errors  │
│ to API  │ │ (Stay on     │
└────┬────┘ │  Form)       │
     │      └──────────────┘
     │
     ▼
┌──────────────────┐
│  Backend Response│
└────────┬─────────┘
         │
    ┌────┴────┐
    │         │
Success│     │Failure
    │         │
    ▼         ▼
┌─────────┐ ┌──────────────┐
│ Save    │ │ Error Message│
│ Token   │ │ (Retry)      │
└────┬────┘ └──────────────┘
     │
     ▼
┌──────────────────┐
│  Backend         │
│  Auto-Generates  │
│  QR Code         │
│  - Unique ID     │
│  - User Account  │
│  - Encrypted Data│
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  QR Code Stored  │
│  in Database     │
│  (Linked to User) │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ Palm Vein        │
│ Enrollment Screen │
│ (QR Code is      │
│  already created) │
└──────────────────┘
```

### 3. Palm Vein Enrollment Flow (Advanced System)

#### 3.1 Card Registration & Tokenization

```
┌──────────────────┐
│  Customer Adds   │
│  Bank Card to App│
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  App Converts    │
│  Card to Token   │
│  (Tokenization)  │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Token Stored    │
│  Securely        │
│  (No Card Number)│
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Ready for       │
│  Enrollment      │
└──────────────────┘
```

#### 3.2 Secure Session Initiation (QR Code)

```
┌──────────────────┐
│  Enrollment      │
│  Screen          │
│  "Enroll Palm"   │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  App Generates   │
│  QR Code         │
│  (Session Key)   │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Customer Scans  │
│  QR Code on      │
│  Palm Device     │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Secure Session  │
│  Established     │
│  (Encrypted      │
│   Channel)       │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Ready for       │
│  Palm Scanning   │
└──────────────────┘
```

#### 3.3 Palm Scanning & Feature Extraction

```
┌──────────────────┐
│  Customer Places │
│  Palm on Scanner │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Hardware Layer  │
│  - NIR Light     │
│    Emitted        │
│  - Veins Absorb  │
│    Light          │
│  - Camera         │
│    Captures       │
│    Pattern        │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Local Processor │
│  - Converts Image │
│    to Numerical   │
│    Vector         │
│  - Encrypts Data  │
│  - Deletes Image  │
│    Immediately    │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Encrypted       │
│  Digital         │
│  Signature       │
│  Created         │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Signature Sent  │
│  to Cloud        │
│  (Encrypted)     │
└────────┬─────────┘
```

#### 3.4 Cloud Registration & Linking

```
┌──────────────────┐
│  Cloud Layer     │
│  Receives        │
│  Encrypted       │
│  Signature       │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Algorithm       │
│  Service         │
│  - Processes     │
│    Signature      │
│  - Stores in      │
│    Database       │
│  - Generates      │
│    User ID        │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Client Server   │
│  - Links Palm     │
│    Signature to   │
│    Card Token     │
│  - Stores         │
│    Mapping        │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Enrollment      │
│  Complete        │
│  - Confirmation   │
│  - Ready for      │
│    Payments       │
└──────────────────┘
```

### 4. Payment Confirmation Flow (Customer Side)

```
┌──────────────────┐
│  Payment Request │
│  Received        │
│  (From Cashier)  │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Payment         │
│  Confirmation    │
│  Screen          │
│  - Amount        │
│  - Merchant Info │
│  - Payment Method│
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Select Payment  │
│  Method          │
│  - Palm Vein     │
│  - NFC Card      │
│  - QR Code       │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Process Payment │
│  (See Payment    │
│   Method Flows)  │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Payment Status  │
│  - Success       │
│  - Failed        │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Transaction      │
│  Receipt          │
│  (Optional Print)│
└──────────────────┘
```

### 5. Transaction History Flow

```
┌──────────────────┐
│  Main Screen     │
│  (Customer App)  │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Transaction     │
│  History Button  │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Fetch           │
│  Transactions    │
│  (API Call)      │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Display List    │
│  - Date/Time     │
│  - Amount        │
│  - Merchant      │
│  - Status        │
│  - Payment Method│
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Transaction     │
│  Detail (Tap)     │
│  - Full Details  │
│  - Receipt View  │
│  - Re-print      │
└──────────────────┘
```

---

## Cashier/POS Application Flow

### 1. Cashier Login Flow

```
┌──────────────────┐
│  App Launch      │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Splash Screen   │
│  (Device Check)  │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Cashier Login   │
│  Screen          │
│  - Cashier ID    │
│  - Password      │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Validate        │
│  Credentials     │
│  (Backend API)   │
└────────┬─────────┘
         │
    ┌────┴────┐
    │         │
 Valid│     │Invalid
    │         │
    ▼         ▼
┌─────────┐ ┌──────────────┐
│ Save    │ │ Error Message│
│ Session │ │ (Retry)      │
└────┬────┘ └──────────────┘
     │
     ▼
┌──────────────────┐
│  POS Main Screen │
│  (Ready for      │
│   Transactions)  │
└──────────────────┘
```

### 2. Payment Processing Flow

```
┌──────────────────┐
│  POS Main Screen │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  "New Payment"   │
│  Button Clicked  │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Enter Amount    │
│  Screen          │
│  - Numeric Input │
│  - Quick Amount  │
│    Buttons       │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Amount          │
│  Confirmed       │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Select Payment  │
│  Method Screen   │
│  - Palm Vein     │
│  - NFC Card      │
│  - QR Code       │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Process Payment │
│  (See Payment    │
│   Method Flows)  │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Payment Status  │
│  Screen          │
│  - Processing    │
│  - Success       │
│  - Failed        │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Receipt Preview │
│  - View Receipt  │
│  - Print Receipt │
│  - Email/SMS     │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Return to Main  │
│  (New Payment)   │
└──────────────────┘
```

### 3. Receipt Generation Flow

```
┌──────────────────┐
│  Payment Success │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Generate Receipt│
│  Data            │
│  - Transaction ID│
│  - Amount        │
│  - Date/Time     │
│  - Payment Method│
│  - Merchant Info │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Format Receipt  │
│  (Text Format)   │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Receipt Preview │
│  Screen          │
│  - Display       │
│  - Edit (if needed)│
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Print Options   │
│  - Print Now     │
│  - Skip          │
│  - Email/SMS     │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Send to Printer │
│  (Native Channel)│
│  - EM5822 Printer│
│  - Format & Print│
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Print Status    │
│  - Success       │
│  - Failed        │
└──────────────────┘
```

---

## Payment Method Flows

### 1. Palm Vein Payment Flow (Advanced System)

#### 1.1 Payment Initiation & Palm Capture

```
┌──────────────────┐
│  Payment Method  │
│  Selected:       │
│  Palm Vein       │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Display         │
│  Instructions    │
│  "Place Palm"    │
│  (Touchless)     │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Request Native  │
│  Recognition     │
│  (Platform       │
│   Channel)       │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Hardware Layer  │
│  - NIR Light     │
│    Emitted        │
│  - Palm Captured │
│  - Vein Pattern  │
│    Detected       │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Local Processor │
│  - Converts to   │
│    Numerical     │
│    Vector         │
│  - Encrypts      │
│    Immediately    │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Encrypted Data  │
│  Prepared        │
└────────┬─────────┘
```

#### 1.2 Cloud Matching & Verification

```
┌──────────────────┐
│  Encrypted Data  │
│  Sent to Cloud   │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Algorithm       │
│  Service         │
│  - Receives      │
│    Encrypted Data│
│  - AI Algorithms │
│    Compare with  │
│    Millions of   │
│    Signatures     │
│  - Pattern       │
│    Matching       │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Liveness        │
│  Detection       │
│  - Blood Flow    │
│    Verification  │
│  - Real Hand     │
│    Check          │
│  - Anti-Fraud    │
│    Detection      │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Match Result    │
└────────┬─────────┘
         │
    ┌────┴────┐
    │         │
 Match│     │No Match
    │         │
    ▼         ▼
┌─────────┐ ┌──────────────┐
│ User ID │ │ Error:       │
│ Found   │ │ "Palm not    │
│         │ │  recognized" │
└────┬────┘ └──────────────┘
     │
     ▼
┌──────────────────┐
│  Client Server   │
│  - Receives      │
│    User ID       │
│  - Verifies      │
│    Permissions   │
│  - Checks        │
│    Account       │
│    Status         │
└────────┬─────────┘
```

#### 1.3 Payment Processing with Tokenization

```
┌──────────────────┐
│  Client Server   │
│  - Retrieves     │
│    Card Token     │
│    (Not Actual    │
│     Card Number)  │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Payment Request │
│  Sent to Gateway │
│  - Card Token     │
│  - Amount         │
│  - Transaction    │
│    Details        │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Payment Gateway │
│  - Receives Token │
│  - Contacts Bank  │
│  - Requests       │
│    Authorization  │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Bank            │
│  Authorization   │
│  - Validates      │
│    Token          │
│  - Checks Balance │
│  - Approves/      │
│    Declines        │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Payment Result  │
│  - Success        │
│  - Insufficient   │
│    Funds          │
│  - Declined        │
│  - Error           │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Confirmation     │
│  - Transaction ID │
│  - Receipt        │
│  - Notification   │
└──────────────────┘
```

### 2. NFC Card Payment Flow

```
┌──────────────────┐
│  Payment Method  │
│  Selected:       │
│  NFC Card        │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Display         │
│  Instructions    │
│  "Tap Card"      │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Request Native  │
│  NFC Read        │
│  (Platform       │
│   Channel)       │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Native SDK      │
│  - Enable NFC    │
│  - Wait for Card │
│  - Read Card UID │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Card UID        │
│  Retrieved       │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Send Payment    │
│  Request to      │
│  Backend        │
│  - Card UID      │
│  - Amount        │
│  - Transaction   │
│    Details       │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Backend         │
│  Authorization   │
│  - Validate Card │
│  - Check Balance │
│  - Process       │
│    Payment       │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Payment Result  │
│  - Success       │
│  - Card Invalid  │
│  - Insufficient  │
│    Funds         │
│  - Declined      │
└──────────────────┘
```

### 3. QR Code Payment Flow

#### 3.1 QR Code Generation & Assignment (Customer Registration)

```
┌──────────────────┐
│  Customer        │
│  Registration    │
│  Completed       │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Backend         │
│  Generates       │
│  Unique QR Code  │
│  - User ID        │
│  - Account Number│
│  - Encrypted Data │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  QR Code         │
│  Stored in       │
│  Backend Database│
│  (Linked to User)│
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  QR Code Data    │
│  Returned to     │
│  Customer App    │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Customer Can    │
│  View QR Code    │
│  - In App Screen │
│  - Save to Phone │
│  - Print Option  │
└──────────────────┘
```

**Key Points:**
- **Auto-Generated**: QR code is automatically created by the backend when a customer registers
- **Unique per Customer**: Each customer gets one unique QR code linked to their account
- **Persistent**: The QR code remains the same for the customer (not transaction-specific)
- **Contains**: User identification data (User ID, Account Number, etc.) in encrypted/encoded format
- **Display Options**: Customer can view QR code in the app, save as image, or print

#### 3.2 QR Code Payment Process Flow

```
┌──────────────────┐
│  Payment Method  │
│  Selected:       │
│  QR Code         │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Customer        │
│  Displays QR     │
│  Code            │
│  - On Phone      │
│  - Printed Card  │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Cashier         │
│  Instructions    │
│  "Show QR Code"  │
│  (Displayed on   │
│   Customer Screen)│
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Request Native  │
│  QR Scan         │
│  (Platform       │
│   Channel)       │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Native SDK      │
│  - Open Serial   │
│    Port          │
│    (/dev/ttyHSL3)│
│  - Activate      │
│    Scanner       │
│  - Read QR Data  │
│    from Scanner  │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  QR Data         │
│  Retrieved       │
│  (Raw String)    │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Validate QR     │
│  Format          │
│  - Check Structure│
│  - Decode/Extract│
│    User Info     │
└────────┬─────────┘
         │
    ┌────┴────┐
    │         │
 Valid│     │Invalid
    │         │
    ▼         ▼
┌─────────┐ ┌──────────────┐
│ Extract │ │ Error:       │
│ User ID │ │ "Invalid QR" │
│ from QR │ │ - Retry Scan  │
└────┬────┘ └──────────────┘
     │
     ▼
┌──────────────────┐
│  Send Payment    │
│  Request to      │
│  Backend        │
│  - User ID       │
│    (from QR)     │
│  - Amount        │
│  - Transaction   │
│    Details       │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Backend         │
│  Authorization   │
│  - Validate User │
│  - Verify QR     │
│    is Active     │
│  - Check Balance │
│  - Process       │
│    Payment       │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Payment Result  │
│  - Success       │
│  - QR Invalid    │
│  - User Not Found│
│  - Insufficient  │
│    Funds         │
│  - Declined      │
└──────────────────┘
```

#### 3.3 Customer QR Code Management Flow

```
┌──────────────────┐
│  Customer App    │
│  Main Screen     │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  "My QR Code"    │
│  Menu Option     │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Fetch QR Code   │
│  from Backend    │
│  (API Call)      │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Display QR Code │
│  Screen          │
│  - QR Image      │
│  - Account Info  │
│  - Actions:      │
│    • Save Image  │
│    • Share       │
│    • Print       │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Customer Can    │
│  Use QR Code     │
│  for Payments    │
└──────────────────┘
```

---

## Dual Screen Flow

### Primary Screen (Cashier) & Secondary Screen (Customer) Synchronization

```
┌─────────────────────────┐     ┌─────────────────────────┐
│  Primary Screen         │     │  Secondary Screen       │
│  (Cashier Interface)    │     │  (Customer Display)     │
└───────────┬─────────────┘     └───────────┬─────────────┘
            │                               │
            │  Payment Initiated            │
            ├──────────────────────────────►│
            │                               │
            │                               ▼
            │                    ┌──────────────────────┐
            │                    │  "Payment Processing"│
            │                    │  - Amount Display    │
            │                    │  - Waiting Indicator │
            │                    └──────────────────────┘
            │                               │
            │  Payment Method Selected      │
            ├──────────────────────────────►│
            │                               │
            │                               ▼
            │                    ┌──────────────────────┐
            │                    │  "Select Payment    │
            │                    │   Method"            │
            │                    │  - Palm Vein        │
            │                    │  - NFC Card         │
            │                    │  - QR Code          │
            │                    └──────────────────────┘
            │                               │
            │  Processing Payment           │
            ├──────────────────────────────►│
            │                               │
            │                               ▼
            │                    ┌──────────────────────┐
            │                    │  "Processing..."   │
            │                    │  - Loading Animation│
            │                    └──────────────────────┘
            │                               │
            │  Payment Result               │
            ├──────────────────────────────►│
            │                               │
            │                               ▼
            │                    ┌──────────────────────┐
            │                    │  Payment Status      │
            │                    │  - Success ✓        │
            │                    │  - Failed ✗          │
            │                    │  - Transaction ID    │
            │                    └──────────────────────┘
            │                               │
            │  Receipt Generated            │
            ├──────────────────────────────►│
            │                               │
            │                               ▼
            │                    ┌──────────────────────┐
            │                    │  "Thank You"        │
            │                    │  - Receipt Preview  │
            │                    └──────────────────────┘
```

**Implementation Notes:**
- Primary screen controls all payment logic
- Secondary screen receives updates via Platform Channel calls
- Android Presentation API manages secondary display
- Real-time synchronization between both screens
- Customer screen shows simplified, user-friendly interface

---

## Error Handling Flows

### 1. Palm Recognition Timeout

```
┌──────────────────┐
│  Palm Recognition│
│  Started         │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Timer Started   │
│  (30 seconds)    │
└────────┬─────────┘
         │
    ┌────┴────┐
    │         │
 Match│     │Timeout
    │         │
    ▼         ▼
┌─────────┐ ┌──────────────┐
│ Success │ │ Timeout Error│
│         │ │ - Show Message│
└─────────┘ │ - Retry Option│
            │ - Cancel      │
            └──────┬─────────┘
                   │
              ┌────┴────┐
              │         │
            Retry│     │Cancel
              │         │
              ▼         ▼
    ┌─────────────┐ ┌──────────┐
    │ Restart     │ │ Return to│
    │ Recognition │ │ Main     │
    └─────────────┘ └──────────┘
```

### 2. NFC Read Failure

```
┌──────────────────┐
│  NFC Read        │
│  Initiated       │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Check NFC       │
│  Availability    │
└────────┬─────────┘
         │
    ┌────┴────┐
    │         │
Available│   │Not Available
    │         │
    ▼         ▼
┌─────────┐ ┌──────────────┐
│ Wait for│ │ Error:       │
│ Card    │ │ "NFC Not     │
│         │ │  Available"  │
└────┬────┘ └──────────────┘
     │
     │ Read Attempt
     │
     ▼
┌──────────────────┐
│  Read Result     │
└────────┬─────────┘
         │
    ┌────┴────┐
    │         │
 Success│   │Failure
    │         │
    ▼         ▼
┌─────────┐ ┌──────────────┐
│ Process │ │ Error:       │
│ Payment │ │ "Card Read   │
│         │ │  Failed"     │
│         │ │ - Retry      │
│         │ │ - Cancel     │
└─────────┘ └──────────────┘
```

### 3. Payment Declined Flow

```
┌──────────────────┐
│  Payment Request │
│  Sent to Backend │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Backend         │
│  Processing      │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Backend Response│
└────────┬─────────┘
         │
    ┌────┴────┐
    │         │
Success│     │Declined
    │         │
    ▼         ▼
┌─────────┐ ┌──────────────────┐
│ Show    │ │ Error Handling   │
│ Success │ │ - Insufficient   │
│         │ │   Funds          │
│         │ │ - Card Invalid   │
│         │ │ - Account Locked │
│         │ │ - System Error   │
└─────────┘ └────────┬─────────┘
                     │
                     ▼
            ┌──────────────────┐
            │  Display Error   │
            │  - User-friendly │
            │    Message       │
            │  - Error Code    │
            │  - Retry Option  │
            │  - Cancel        │
            └──────────────────┘
```

### 4. Hardware Unavailable Flow

```
┌──────────────────┐
│  Device Check    │
│  (App Launch)    │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Check Hardware  │
│  - Palm Scanner  │
│  - NFC Reader    │
│  - QR Scanner    │
│  - Printer       │
└────────┬─────────┘
         │
    ┌────┴────┐
    │         │
  All│     │Some Missing
Available│   │
    │         │
    ▼         ▼
┌─────────┐ ┌──────────────────┐
│ Proceed │ │ Error Screen     │
│ to Main │ │ - List Missing   │
│         │ │   Hardware       │
│         │ │ - Instructions   │
│         │ │ - Retry Check    │
│         │ │ - Exit App       │
└─────────┘ └──────────────────┘
```

---

## Integration Points

### 1. Flutter ↔ Native Communication

```
┌──────────────────┐
│  Flutter Layer   │
│  (Dart)          │
└────────┬─────────┘
         │
         │ Method Channel
         │ "leshun_hardware_channel"
         │
         ▼
┌──────────────────┐
│  Platform        │
│  Channel Bridge  │
└────────┬─────────┘
         │
         │ Native Method Calls
         │
         ▼
┌──────────────────┐
│  Native Layer    │
│  (Kotlin)        │
│  - Palm Vein SDK │
│  - NFC Adapter   │
│  - QR Scanner    │
│  - Printer SDK   │
└────────┬─────────┘
         │
         │ Hardware Access
         │
         ▼
┌──────────────────┐
│  Hardware Device │
│  (Leshun LSP980) │
└──────────────────┘
```

### 2. Backend API Integration

```
┌──────────────────┐
│  Flutter App     │
└────────┬─────────┘
         │
         │ HTTPS REST API
         │
         ▼
┌──────────────────┐
│  Backend Server  │
│  - Authentication│
│  - User Management│
│  - Payment       │
│    Processing    │
│  - Transaction   │
│    Records       │
│  - Reporting     │
└────────┬─────────┘
         │
         │ Database
         │
         ▼
┌──────────────────┐
│  Database        │
│  - User Data     │
│  - Palm ID Maps  │
│  - Transactions  │
│  - Card Info     │
└──────────────────┘
```

### 3. Data Flow Example: Palm Vein Payment

```
┌──────────────┐
│  User Places │
│  Palm        │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│  Native SDK  │
│  Captures    │
│  & Matches   │
└──────┬───────┘
       │
       │ Palm ID
       ▼
┌──────────────┐
│  Flutter     │
│  Receives    │
│  Palm ID     │
└──────┬───────┘
       │
       │ API Call
       │ {userId, amount, ...}
       ▼
┌──────────────┐
│  Backend     │
│  Validates   │
│  & Processes │
└──────┬───────┘
       │
       │ Response
       │ {status, transactionId, ...}
       ▼
┌──────────────┐
│  Flutter     │
│  Updates UI  │
│  & Shows     │
│  Result      │
└──────────────┘
```

---

## Key User Experience Features

### 1. Real-Time Feedback
- Loading indicators during processing
- Progress updates for palm vein scanning
- Visual feedback for NFC card detection
- Status updates on both screens

### 2. Error Recovery
- Clear error messages
- Retry options for failed operations
- Graceful degradation when hardware unavailable
- Offline mode indicators

### 3. Security Indicators
- Secure connection indicators
- Biometric authentication status
- Transaction confirmation requirements
- Receipt generation for audit trail

### 4. Accessibility
- Large, clear text for customer display
- Audio feedback (optional)
- Multi-language support (if required)
- Simple, intuitive navigation

---

## Flow Summary

### Customer Application
1. **Launch** → Device Check → Welcome/Login
2. **Registration** → Form → Validation → Palm Enrollment
3. **Palm Enrollment** → Capture → Feature Extraction → Backend Mapping
4. **Payment** → Confirmation → Method Selection → Processing → Receipt
5. **History** → List View → Detail View → Receipt

### Cashier Application
1. **Launch** → Device Check → Login
2. **Payment** → Amount Entry → Method Selection → Processing → Receipt
3. **Receipt** → Generation → Preview → Print
4. **Transactions** → List → Details → Reports

### Payment Methods
- **Palm Vein**: Capture → Match → Authorize → Process
- **NFC**: Read Card → Validate → Authorize → Process
- **QR Code**: Scan → Validate → Authorize → Process

---

**Document Version:** 1.0  
**Last Updated:** [Current Date]  
**Related Documents:** CLIENT_PROJECT_PROPOSAL.md, project-implementation.md

