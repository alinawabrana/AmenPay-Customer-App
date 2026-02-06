# Card Tokenization Security Guide
## Best Practices for Secure Card Data Handling

---

## 1. What is Tokenization?

**Tokenization** is the process of replacing sensitive card data with a non-sensitive equivalent (token) that has no exploitable value.

### Example:
- **Real Card**: `4532-1234-5678-9010`
- **Token**: `tok_abc123xyz789`
- **Stored in Database**: Only the token
- **Real Card Data**: Stored in secure vault (payment gateway)

---

## 2. Tokenization vs Hashing

### ❌ **DO NOT USE HASHING FOR CARD DETAILS**

| Feature | Tokenization | Hashing |
|---------|-------------|---------|
| **Reversible** | ✅ Yes (via vault) | ❌ No (one-way) |
| **Purpose** | Payment processing | Data integrity verification |
| **Uniqueness** | ✅ Unique per card | ⚠️ Same hash for same input |
| **Format** | Can preserve format | Fixed length output |
| **Use Case** | ✅ **Card payments** | ❌ **NOT for payments** |

**Why Hashing Fails:**
- Cannot reverse to get original card number
- Cannot use for payment processing
- Same card = same hash (security risk)
- No way to charge the card later

---

## 3. Where Should Tokenization Happen?

### ✅ **RECOMMENDED: Backend Tokenization**

```
┌─────────────────────────────────────────────────────────┐
│                    RECOMMENDED FLOW                       │
└─────────────────────────────────────────────────────────┘

Frontend (Flutter App)
    │
    │ 1. User enters card details
    │ 2. Encrypt card data (optional, for extra security)
    │
    ▼
HTTPS/TLS Encrypted Channel
    │
    │ 3. Send encrypted card data
    │
    ▼
Backend API
    │
    │ 4. Decrypt card data (if encrypted)
    │ 5. Validate card format
    │
    ▼
Payment Gateway (Stripe/Square/PayPal)
    │
    │ 6. Gateway tokenizes card
    │ 7. Gateway returns token
    │
    ▼
Backend Database
    │
    │ 8. Store ONLY token
    │ 9. Link token to user account
    │
    ▼
Future Payments
    │
    │ 10. Use token for payments
    │ 11. Never expose real card data
```

### ❌ **NOT RECOMMENDED: Frontend Tokenization**

**Why Frontend Tokenization is Risky:**
- Card data exists in frontend memory (security risk)
- Larger PCI DSS compliance scope
- Complex key management
- Higher risk of data exposure
- More attack surface

---

## 4. What Data Should Be Tokenized/Encrypted?

### 🔴 **MUST TOKENIZE/ENCRYPT:**

1. **Primary Account Number (PAN)**
   - Full 16-digit card number
   - **NEVER store in plain text**
   - **NEVER log in logs**

2. **CVV/CVC (Card Verification Value)**
   - 3-4 digit security code
   - **NEVER store** (even encrypted)
   - **NEVER send to backend after initial tokenization**
   - Use only for one-time tokenization

3. **Expiry Date**
   - Month/Year (MM/YY)
   - Should be encrypted if stored
   - Can be tokenized

4. **Cardholder Name**
   - Name on card
   - Should be encrypted if stored

### 🟡 **CAN STORE (Non-Sensitive):**

1. **Last 4 Digits**
   - ✅ Safe to store: `**** **** **** 1234`
   - Used for display purposes
   - Not considered sensitive

2. **Card Brand/Type**
   - ✅ Safe to store: `Visa`, `Mastercard`, etc.
   - Not sensitive data

3. **BIN (Bank Identification Number)**
   - ✅ First 6 digits can be stored
   - Used for identification
   - Not considered full PAN

---

## 5. Implementation Recommendations

### Option 1: Use Payment Gateway Tokenization (RECOMMENDED)

**Best Practice: Let Payment Gateway Handle Tokenization**

#### Using Stripe:
```dart
// Frontend: Send card to backend
POST /api/cards/tokenize
{
  "card_number": "4532123456789010",
  "expiry_month": "12",
  "expiry_year": "2025",
  "cvv": "123",
  "cardholder_name": "John Doe"
}

// Backend: Send to Stripe
Stripe API → Returns: "tok_abc123xyz"

// Backend: Store token
Database: {
  user_id: "user123",
  card_token: "tok_abc123xyz",
  last4: "9010",
  brand: "Visa",
  expiry_month: "12",
  expiry_year: "2025"
}
```

#### Using Square:
```dart
// Similar flow with Square API
Square API → Returns: "cnon:abc123xyz"
```

**Benefits:**
- ✅ PCI DSS compliance handled by gateway
- ✅ Secure vault managed by experts
- ✅ Industry-standard security
- ✅ Easy to implement

### Option 2: Self-Hosted Tokenization (Advanced)

**Only if you have PCI DSS Level 1 compliance**

```
1. Use PCI-compliant vault (VGS, Basis Theory)
2. Implement secure key management
3. Regular security audits
4. Compliance certifications
```

---

## 6. Security Best Practices

### ✅ **DO:**

1. **Use HTTPS/TLS for all communications**
   - Encrypt data in transit
   - Use TLS 1.2 or higher

2. **Never log card data**
   ```dart
   // ❌ BAD
   logger.info("Card: ${cardNumber}");
   
   // ✅ GOOD
   logger.info("Card: **** **** **** ${last4}");
   ```

3. **Store only tokens**
   ```dart
   // ❌ BAD
   database.save({
     "card_number": "4532123456789010"
   });
   
   // ✅ GOOD
   database.save({
     "card_token": "tok_abc123xyz",
     "last4": "9010"
   });
   ```

4. **Validate card format before sending**
   ```dart
   // Validate Luhn algorithm
   // Validate card length
   // Validate expiry date
   ```

5. **Use secure key management**
   - Store keys in secure vault
   - Rotate keys regularly
   - Use environment variables

6. **Implement access controls**
   - Only authorized services can access tokens
   - Audit all token access

7. **Encrypt sensitive data at rest**
   - Use AES-256 encryption
   - Encrypt database fields

### ❌ **DON'T:**

1. **Never store CVV**
   - Even encrypted
   - Even temporarily
   - Use only for initial tokenization

2. **Never store full PAN**
   - Even encrypted in your database
   - Let payment gateway handle it

3. **Never send card data in URLs**
   ```dart
   // ❌ BAD
   GET /api/cards?number=4532123456789010
   
   // ✅ GOOD
   POST /api/cards/tokenize
   Body: { encrypted_card_data }
   ```

4. **Never cache card data**
   - Clear from memory after use
   - Don't store in local storage

5. **Never expose tokens in logs**
   - Log only last 4 digits
   - Use token IDs, not full tokens

---

## 7. Recommended Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    SECURE ARCHITECTURE                     │
└─────────────────────────────────────────────────────────┘

┌──────────────┐
│   Frontend   │
│  (Flutter)   │
└──────┬───────┘
       │
       │ HTTPS/TLS
       │ Encrypted
       │
       ▼
┌──────────────┐
│   Backend    │
│    API       │
│              │
│  • Validate  │
│  • Encrypt   │
│  • Forward   │
└──────┬───────┘
       │
       │ Secure API
       │ (Payment Gateway)
       │
       ▼
┌──────────────┐
│   Payment    │
│   Gateway    │
│              │
│  • Tokenize  │
│  • Store     │
│  • Vault     │
└──────┬───────┘
       │
       │ Returns Token
       │
       ▼
┌──────────────┐
│   Backend    │
│  Database    │
│              │
│  Store:      │
│  • Token     │
│  • Last 4    │
│  • Brand     │
│  • Expiry    │
└──────────────┘
```

---

## 8. Code Example (Backend - Node.js/Python)

### Node.js Example:
```javascript
// Backend: Tokenize card via Stripe
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);

async function tokenizeCard(cardData) {
  try {
    // Create token via Stripe
    const token = await stripe.tokens.create({
      card: {
        number: cardData.card_number,
        exp_month: cardData.expiry_month,
        exp_year: cardData.expiry_year,
        cvc: cardData.cvv,
        name: cardData.cardholder_name,
      },
    });

    // Store only token in database
    await database.save({
      user_id: cardData.user_id,
      card_token: token.id, // tok_abc123xyz
      last4: token.card.last4,
      brand: token.card.brand,
      expiry_month: token.card.exp_month,
      expiry_year: token.card.exp_year,
    });

    return { success: true, token: token.id };
  } catch (error) {
    // Never log full card data
    logger.error('Tokenization failed', { 
      error: error.message,
      last4: cardData.card_number.slice(-4)
    });
    throw error;
  }
}
```

### Python Example:
```python
import stripe

stripe.api_key = os.getenv('STRIPE_SECRET_KEY')

def tokenize_card(card_data):
    try:
        # Create token via Stripe
        token = stripe.Token.create(
            card={
                'number': card_data['card_number'],
                'exp_month': card_data['expiry_month'],
                'exp_year': card_data['expiry_year'],
                'cvc': card_data['cvv'],
                'name': card_data['cardholder_name'],
            }
        )
        
        # Store only token
        database.save({
            'user_id': card_data['user_id'],
            'card_token': token.id,
            'last4': token.card.last4,
            'brand': token.card.brand,
            'expiry_month': token.card.exp_month,
            'expiry_year': token.card.exp_year,
        })
        
        return {'success': True, 'token': token.id}
    except Exception as e:
        # Never log full card data
        logger.error(f'Tokenization failed: {e}', extra={
            'last4': card_data['card_number'][-4:]
        })
        raise
```

---

## 9. PCI DSS Compliance Checklist

### ✅ **Requirements:**

1. **Never store full PAN** (except in secure vault)
2. **Never store CVV** (even encrypted)
3. **Encrypt data in transit** (HTTPS/TLS)
4. **Encrypt data at rest** (AES-256)
5. **Implement access controls**
6. **Regular security audits**
7. **Secure key management**
8. **Network segmentation**
9. **Vulnerability management**
10. **Monitor and log access**

---

## 10. Summary

### ✅ **RECOMMENDED APPROACH:**

1. **Backend Tokenization** via Payment Gateway
2. **Store only tokens** in database
3. **Never store CVV** or full PAN
4. **Use HTTPS/TLS** for all communications
5. **Encrypt sensitive data** at rest
6. **Implement proper access controls**
7. **Regular security audits**

### ❌ **AVOID:**

1. Frontend tokenization
2. Hashing for card data
3. Storing CVV or full PAN
4. Logging card data
5. Caching card data
6. Self-hosted tokenization (unless PCI Level 1 compliant)

---

## 11. Payment Gateway Options

### Recommended Gateways:

1. **Stripe**
   - ✅ Excellent API
   - ✅ PCI DSS Level 1 compliant
   - ✅ Global support
   - ✅ Good documentation

2. **Square**
   - ✅ Easy integration
   - ✅ PCI compliant
   - ✅ Good for POS systems

3. **PayPal**
   - ✅ Widely accepted
   - ✅ PCI compliant
   - ✅ Good for global payments

4. **Adyen**
   - ✅ Enterprise-grade
   - ✅ PCI compliant
   - ✅ Multi-region support

---

**Document Version:** 1.0  
**Last Updated:** 2024  
**Security Level:** PCI DSS Compliant Recommendations

