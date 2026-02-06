# QR Code Implementation Guide
## Backend Generation vs Frontend Generation

---

## 📋 Summary: Recommended Approach

### ✅ **RECOMMENDED: Hybrid Approach**

1. **Backend**: Generates and stores QR code **data** (the content/string)
2. **Backend**: Stores QR code data in database
3. **Frontend**: Fetches QR code data from backend
4. **Frontend**: Generates QR code **image** for display

---

## 🔄 Complete Flow

```
┌─────────────────────────────────────────────────────────┐
│                    QR CODE FLOW                            │
└─────────────────────────────────────────────────────────┘

1. REGISTRATION
   Frontend → Backend: Registration Data
   Backend → Generates QR Code Data
   Backend → Stores QR Code Data in Database
   Backend → Returns QR Code Data to Frontend

2. DISPLAY QR CODE
   Frontend → Backend: GET /api/users/{userId}/qr-code
   Backend → Returns QR Code Data (string)
   Frontend → Generates QR Code Image
   Frontend → Displays QR Code Image

3. PAYMENT
   Customer → Shows QR Code (from phone/print)
   Cashier → Scans QR Code
   Scanner → Reads QR Code Data
   Backend → Validates QR Code Data
   Backend → Processes Payment
```

---

## 🎯 What Should Be Generated Where?

### Backend Responsibilities:

1. **Generate QR Code Data (String)**
   ```json
   {
     "user_id": "user123",
     "account_number": "ACC456789",
     "encrypted_data": "encrypted_string_here",
     "qr_data": "PALMPAY:user123:ACC456789:encrypted_string"
   }
   ```

2. **Store QR Code Data**
   - Save in database linked to user account
   - Ensure uniqueness
   - Link to user ID

3. **Validate QR Code**
   - Verify QR code belongs to active user
   - Check if QR code is revoked/deactivated
   - Validate format

### Frontend Responsibilities:

1. **Fetch QR Code Data**
   - Call backend API to get QR code data
   - Handle errors gracefully

2. **Generate QR Code Image**
   - Use QR code library to convert data string to image
   - Display image to user

3. **Save/Share QR Code**
   - Allow user to save QR code image
   - Allow user to print QR code
   - Allow user to share QR code

---

## 💻 Implementation

### Backend Implementation

#### 1. Generate QR Code Data (During Registration)

**Node.js Example:**
```javascript
// Backend: Generate QR code data
const crypto = require('crypto');

function generateQRCodeData(userId, accountNumber) {
  // Create unique identifier
  const timestamp = Date.now();
  const randomString = crypto.randomBytes(16).toString('hex');
  
  // Encrypt sensitive data
  const encryptedData = encryptData({
    userId: userId,
    accountNumber: accountNumber,
    timestamp: timestamp
  });
  
  // Generate QR code data string
  const qrData = `PALMPAY:${userId}:${accountNumber}:${encryptedData}`;
  
  // Store in database
  await database.save({
    user_id: userId,
    qr_code_data: qrData,
    qr_code_hash: hashQRCode(qrData), // For quick lookup
    created_at: new Date(),
    is_active: true
  });
  
  return qrData;
}

// During registration
async function registerUser(userData) {
  // 1. Create user account
  const user = await createUser(userData);
  
  // 2. Generate QR code automatically
  const qrCodeData = await generateQRCodeData(user.id, user.account_number);
  
  // 3. Return user data with QR code data
  return {
    user_id: user.id,
    qr_code_data: qrCodeData,
    // Don't return full QR code image, just the data
  };
}
```

**Python Example:**
```python
import hashlib
import secrets
from datetime import datetime

def generate_qr_code_data(user_id, account_number):
    # Create unique identifier
    timestamp = datetime.now().timestamp()
    random_string = secrets.token_hex(16)
    
    # Encrypt sensitive data
    encrypted_data = encrypt_data({
        'user_id': user_id,
        'account_number': account_number,
        'timestamp': timestamp
    })
    
    # Generate QR code data string
    qr_data = f"PALMPAY:{user_id}:{account_number}:{encrypted_data}"
    
    # Store in database
    database.save({
        'user_id': user_id,
        'qr_code_data': qr_data,
        'qr_code_hash': hash_qr_code(qr_data),
        'created_at': datetime.now(),
        'is_active': True
    })
    
    return qr_data

# During registration
async def register_user(user_data):
    # 1. Create user account
    user = await create_user(user_data)
    
    # 2. Generate QR code automatically
    qr_code_data = await generate_qr_code_data(user.id, user.account_number)
    
    # 3. Return user data with QR code data
    return {
        'user_id': user.id,
        'qr_code_data': qr_code_data,
    }
```

#### 2. API Endpoint to Fetch QR Code

**Node.js Example:**
```javascript
// GET /api/users/:userId/qr-code
app.get('/api/users/:userId/qr-code', authenticateUser, async (req, res) => {
  try {
    const userId = req.params.userId;
    
    // Verify user owns this QR code
    if (req.user.id !== userId) {
      return res.status(403).json({ error: 'Unauthorized' });
    }
    
    // Fetch QR code data from database
    const qrCode = await database.findOne({
      user_id: userId,
      is_active: true
    });
    
    if (!qrCode) {
      return res.status(404).json({ error: 'QR code not found' });
    }
    
    // Return QR code data (not image)
    res.json({
      qr_code_data: qrCode.qr_code_data,
      user_id: qrCode.user_id,
      account_number: qrCode.account_number,
      created_at: qrCode.created_at
    });
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
});
```

**Python Example:**
```python
# GET /api/users/{userId}/qr-code
@app.get('/api/users/{user_id}/qr-code')
async def get_qr_code(user_id: str, current_user: User = Depends(get_current_user)):
    # Verify user owns this QR code
    if current_user.id != user_id:
        raise HTTPException(status_code=403, detail='Unauthorized')
    
    # Fetch QR code data from database
    qr_code = database.find_one({
        'user_id': user_id,
        'is_active': True
    })
    
    if not qr_code:
        raise HTTPException(status_code=404, detail='QR code not found')
    
    # Return QR code data (not image)
    return {
        'qr_code_data': qr_code['qr_code_data'],
        'user_id': qr_code['user_id'],
        'account_number': qr_code['account_number'],
        'created_at': qr_code['created_at']
    }
```

#### 3. Validate QR Code (During Payment)

**Node.js Example:**
```javascript
// POST /api/payments/validate-qr
app.post('/api/payments/validate-qr', async (req, res) => {
  try {
    const { qr_code_data } = req.body;
    
    // Validate QR code format
    if (!qr_code_data.startsWith('PALMPAY:')) {
      return res.status(400).json({ error: 'Invalid QR code format' });
    }
    
    // Parse QR code data
    const parts = qr_code_data.split(':');
    const userId = parts[1];
    const accountNumber = parts[2];
    const encryptedData = parts[3];
    
    // Verify QR code exists and is active
    const qrCode = await database.findOne({
      qr_code_data: qr_code_data,
      is_active: true
    });
    
    if (!qrCode) {
      return res.status(404).json({ error: 'QR code not found or inactive' });
    }
    
    // Verify user account is active
    const user = await database.findOne({
      id: userId,
      is_active: true
    });
    
    if (!user) {
      return res.status(404).json({ error: 'User account not found' });
    }
    
    // Return user information for payment
    res.json({
      user_id: user.id,
      account_number: user.account_number,
      valid: true
    });
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
});
```

---

### Frontend Implementation (Flutter)

#### 1. Add QR Code Package

**pubspec.yaml:**
```yaml
dependencies:
  qr_flutter: ^4.1.0  # For generating QR code images
  http: ^1.1.0        # For API calls
```

#### 2. Fetch QR Code Data from Backend

```dart
// services/qr_code_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class QRCodeService {
  final String baseUrl = 'https://api.yourapp.com';
  
  Future<String> fetchQRCodeData(String userId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/$userId/qr-code'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['qr_code_data'] as String;
      } else {
        throw Exception('Failed to fetch QR code');
      }
    } catch (e) {
      throw Exception('Error fetching QR code: $e');
    }
  }
}
```

#### 3. Display QR Code Image

```dart
// screens/qr_code_screen.dart
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:palmpay/services/qr_code_service.dart';

class QRCodeScreen extends StatefulWidget {
  final String userId;
  final String token;
  
  const QRCodeScreen({
    Key? key,
    required this.userId,
    required this.token,
  }) : super(key: key);
  
  @override
  State<QRCodeScreen> createState() => _QRCodeScreenState();
}

class _QRCodeScreenState extends State<QRCodeScreen> {
  String? _qrCodeData;
  bool _isLoading = true;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _loadQRCode();
  }
  
  Future<void> _loadQRCode() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      
      final qrCodeService = QRCodeService();
      final qrData = await qrCodeService.fetchQRCodeData(
        widget.userId,
        widget.token,
      );
      
      setState(() {
        _qrCodeData = qrData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My QR Code'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $_error'),
                      ElevatedButton(
                        onPressed: _loadQRCode,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _qrCodeData != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Display QR Code Image
                          QrImageView(
                            data: _qrCodeData!,
                            version: QrVersions.auto,
                            size: 250.0,
                            backgroundColor: Colors.white,
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Scan this QR code to make payments',
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 24),
                          // Save QR Code Button
                          ElevatedButton(
                            onPressed: _saveQRCode,
                            child: const Text('Save QR Code'),
                          ),
                        ],
                      ),
                    )
                  : const Center(child: Text('No QR code available')),
    );
  }
  
  Future<void> _saveQRCode() async {
    // Implement save QR code to gallery
    // You can use packages like 'image_gallery_saver' or 'path_provider'
  }
}
```

#### 4. Cache QR Code Data (Optional)

```dart
// For offline access, cache QR code data
class QRCodeCache {
  static String? cachedQRCodeData;
  static DateTime? cacheTimestamp;
  
  static Future<String?> getQRCodeData(
    String userId,
    String token,
  ) async {
    // Check cache first
    if (cachedQRCodeData != null && cacheTimestamp != null) {
      final cacheAge = DateTime.now().difference(cacheTimestamp!);
      if (cacheAge.inHours < 24) {
        // Cache is still valid (less than 24 hours)
        return cachedQRCodeData;
      }
    }
    
    // Fetch from backend
    try {
      final qrCodeService = QRCodeService();
      final qrData = await qrCodeService.fetchQRCodeData(userId, token);
      
      // Update cache
      cachedQRCodeData = qrData;
      cacheTimestamp = DateTime.now();
      
      return qrData;
    } catch (e) {
      // Return cached data if available, even if expired
      return cachedQRCodeData;
    }
  }
}
```

---

## 📊 Database Schema

### QR Code Table

```sql
CREATE TABLE qr_codes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    qr_code_data TEXT NOT NULL UNIQUE,
    qr_code_hash VARCHAR(64) NOT NULL UNIQUE, -- For quick lookup
    account_number VARCHAR(50) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    revoked_at TIMESTAMP NULL,
    
    INDEX idx_user_id (user_id),
    INDEX idx_qr_code_hash (qr_code_hash),
    INDEX idx_is_active (is_active)
);
```

---

## 🔒 Security Considerations

### 1. QR Code Data Format

```
Format: PALMPAY:{userId}:{accountNumber}:{encryptedData}

Example: PALMPAY:user123:ACC456789:encrypted_string_here
```

### 2. Encryption

- Encrypt sensitive data in QR code
- Use AES-256 encryption
- Store encryption keys securely

### 3. Validation

- Always validate QR code format
- Check if QR code is active
- Verify user account is active
- Log all QR code scans for audit

### 4. Revocation

- Allow QR code revocation if compromised
- Generate new QR code if needed
- Invalidate old QR code

---

## ✅ Best Practices

### Backend:

1. ✅ Generate QR code data during registration
2. ✅ Store QR code data in database
3. ✅ Return QR code data (not image) to frontend
4. ✅ Validate QR code format and status
5. ✅ Implement QR code revocation mechanism

### Frontend:

1. ✅ Fetch QR code data from backend
2. ✅ Generate QR code image for display
3. ✅ Cache QR code data for offline access
4. ✅ Allow user to save/print QR code
5. ✅ Handle errors gracefully

---

## 📝 Summary

### ✅ **RECOMMENDED APPROACH:**

1. **Backend generates QR code data** (string) during registration
2. **Backend stores QR code data** in database
3. **Frontend fetches QR code data** from backend API
4. **Frontend generates QR code image** for display
5. **Frontend allows save/print** of QR code image

### ❌ **AVOID:**

1. Generating QR code data in frontend (security risk)
2. Storing QR code image in backend (waste of storage)
3. Generating QR code on every request (performance issue)
4. Not validating QR code format (security risk)

---

**Document Version:** 1.0  
**Last Updated:** 2024

