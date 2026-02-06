# PALM VEIN ENROLLMENT IMPLEMENTATION GUIDE (Flutter + Laravel/PHP)
**Scope:** Palm vein **enrollment only** (no card charging / no payment gateway).
**Hardware model:** POS app controls scanner, **pulls** enrollment result from SDK, then **calls backend** with `template_id`.

**Source basis:** Consolidated from repository documentation:
- `PALM_VEIN_SYSTEM_EXPLANATION.md`
- `APP_FLOW.md`
- `APP_FLOW_CLIENT.md`
- `QR_CODE_FLOW_EXPLANATION.md`
- `QR_CODE_IMPLEMENTATION_GUIDE.md`
- `PAYMENT_CONFIRMATION_CLARIFICATION.md` *(flow reference only; charging not implemented)*
- `CARD_TOKENIZATION_SECURITY_GUIDE.md` *(tokenization guidance; charging not implemented)*

---

## 1. Overview

Palm vein enrollment links a **customer user account** to a **biometric template reference** (`template_id`) produced by the palm vein device SDK (e.g., Leshun LSP980). The system must ensure:

- The actual palm **image is never stored** (only biometric template / vector reference).
- Enrollment happens through a **secure, time-limited session** initiated by the customer app.
- POS device scans a session QR code, performs enrollment on the scanner, obtains a `template_id`, and submits it to Laravel.
- Laravel stores the final association: `user_id ↔ (device_id, template_id)`.

This guide provides:
- Required flows and state machine
- API endpoints (Laravel)
- Payload formats and error codes
- Database schema + constraints
- Security requirements
- Flutter (customer) responsibilities
- POS responsibilities (scanner + backend calls)
- Text sequence diagrams

---

## 2. Roles and Responsibilities

### 2.1 Customer App (Flutter)
- Creates an enrollment session
- Displays a QR code that represents the session
- Polls for completion and updates UI state (step progress)

### 2.2 POS App (Flutter/Android)
- Scans session QR code (serial scanner / camera)
- Calls backend to claim the session (locks it to device)
- Initiates enrollment via palm vein SDK
- Receives `template_id` from SDK (Case 1)
- Submits enrollment result (`template_id`) to backend

### 2.3 Palm Vein Device / SDK (e.g., LSP980)
- Captures palm vein pattern
- Performs feature extraction and enrollment
- Returns a `template_id` to the POS app
- Must **not** persist or expose raw palm images outside secure vendor handling

### 2.4 Backend (Laravel/PHP)
- Issues secure enrollment sessions and validates QR signatures
- Tracks session lifecycle
- Enforces enrollment rules (one template per user, explicit reset required)
- Stores `template_id` and `device_id` for the user

---

## 3. Enrollment Rules (Enforced)

### 3.1 Enrollment Rules
- **One palm template per user**
- **Re-enrollment only via explicit reset**
- **No automatic overwrite**
- **No silent replacement**

### 3.2 Template ID Rules
- `template_id` unique per device
- `(device_id, template_id)` must never be reused across users
- Never auto-linked to a different user
- Never reused across users

---

## 4. Session State Machine

### 4.1 Session Status Values
- `created` — Customer created session; QR generated
- `claimed` — POS scanned QR and claimed session; locked to `device_id`
- `enrolled` — POS submitted success and backend stored the mapping
- `failed` — POS submitted failure with reason
- `expired` — Session exceeded `expires_at` without enrollment
- `cancelled` *(optional)* — Admin/customer cancelled flow

### 4.2 Allowed Transitions
- `created → claimed`
- `claimed → enrolled`
- `claimed → failed`
- `created|claimed → expired` (time-based)

---

## 5. QR Session Format

Enrollment uses a **session QR** (NOT the persistent customer payment QR). This QR is short-lived and used only for pairing the customer session to the POS device.

### 5.1 Recommended QR Data Format
`PALMENROLL:{sessionId}:{expUnix}:{nonce}:{sig}`

Where:
- `sessionId` = UUID
- `expUnix` = session expiry unix timestamp
- `nonce` = random per session
- `sig` = `HMAC_SHA256(sessionId|expUnix|nonce, SERVER_SECRET)`

### 5.2 Validation Requirements (Backend)
- Prefix must match `PALMENROLL`
- Signature must match HMAC (prevents forgery)
- `expUnix` must not be in the past
- `sessionId` must exist and not be expired/enrolled

---

## 6. Backend API Specification (Laravel)

### Authentication model (recommended)
- **Customer endpoints** use customer auth (Bearer token).
- **POS endpoints** use POS auth (device key / merchant credential).
- Do not reuse customer tokens for POS calls.

---

### 6.1 Create Enrollment Session (Customer)
**POST** `/api/palm/enroll/sessions`

**Auth:** Customer

**Request**
```json
{
  "purpose": "palm_enrollment"
}
```

**Success Response**
```json
{
  "session_id": "b1b3d7b0-2c14-4a6a-9d2a-5b6f3b7f4c1d",
  "status": "created",
  "qr_data": "PALMENROLL:b1b3d7b0-2c14-4a6a-9d2a-5b6f3b7f4c1d:1705920000:NONCE:SIG",
  "expires_at": "2026-01-22T11:33:00Z"
}
```

**Failure Responses**
- `409 ALREADY_ENROLLED` (user must reset first)

---

### 6.2 Claim Session (POS)
**POST** `/api/palm/enroll/sessions/claim`

**Auth:** POS

**Request**
```json
{
  "qr_data": "PALMENROLL:...:SIG",
  "device_id": "POS-001"
}
```

**Success Response**
```json
{
  "session_id": "b1b3d7b0-2c14-4a6a-9d2a-5b6f3b7f4c1d",
  "status": "claimed",
  "expires_at": "2026-01-22T11:33:00Z"
}
```

**Failure Codes**
- `400 INVALID_QR`
- `401 UNAUTHORIZED_DEVICE`
- `403 SIGNATURE_INVALID`
- `410 SESSION_EXPIRED`
- `409 SESSION_ALREADY_CLAIMED`
- `409 SESSION_ALREADY_ENROLLED`

---

### 6.3 Submit Enrollment Result (POS)
**POST** `/api/palm/enroll/sessions/{session_id}/submit-result`

**Auth:** POS

#### Success Request
```json
{
  "device_id": "POS-001",
  "result": "success",
  "template_id": "LSP980-TPL-0000123456",
  "quality_score": 87,
  "liveness": "pass"
}
```

#### Success Response
```json
{
  "status": "enrolled",
  "user_id": "USER-UUID",
  "device_id": "POS-001",
  "template_id": "LSP980-TPL-0000123456",
  "enrolled_at": "2026-01-22T11:32:10Z"
}
```

#### Failure Request
```json
{
  "device_id": "POS-001",
  "result": "failed",
  "error_code": "LOW_QUALITY",
  "error_message": "Palm capture quality too low"
}
```

#### Failure Response
```json
{
  "status": "failed",
  "error_code": "LOW_QUALITY"
}
```

**Server-side enforcement**
- Session must be `claimed`
- `device_id` must match `claimed_device_id`
- Session must not be expired
- If `result=success`, `template_id` is required
- Reject if user already enrolled (no overwrite)
- Reject if `(device_id, template_id)` already linked to another user

**Failure Codes**
- `403 SESSION_DEVICE_MISMATCH`
- `410 SESSION_EXPIRED`
- `409 ALREADY_ENROLLED`
- `409 TEMPLATE_ALREADY_LINKED`
- `422 VALIDATION_ERROR`

---

### 6.4 Poll Session Status (Customer)
**GET** `/api/palm/enroll/sessions/{session_id}`

**Auth:** Customer

**Response**
```json
{
  "session_id": "b1b3d7b0-2c14-4a6a-9d2a-5b6f3b7f4c1d",
  "status": "created|claimed|enrolled|failed|expired",
  "failure": null,
  "template_id": "LSP980-TPL-0000123456"
}
```

---

### 6.5 Check Enrollment Status (Customer)
**GET** `/api/palm/me/status`

**Auth:** Customer

**Response**
```json
{
  "is_enrolled": true,
  "device_id": "POS-001",
  "template_id": "LSP980-TPL-0000123456",
  "enrolled_at": "2026-01-22T11:32:10Z"
}
```

---

### 6.6 Explicit Reset (Customer)
Re-enrollment is only allowed after reset.

**POST** `/api/palm/me/reset`

**Auth:** Customer

**Request**
```json
{
  "reason": "user_requested"
}
```

**Response**
```json
{
  "status": "reset",
  "reset_at": "2026-01-22T11:40:00Z"
}
```

**Implementation notes**
- Prefer soft revoke (`revoked_at`) for audit, or hard delete for simplicity.
- After reset, user can create a new enrollment session and enroll again.

---

## 7. Standard Error Codes (Recommended)

Use a stable `code` field to simplify UI mapping:

- `ALREADY_ENROLLED`
- `RESET_REQUIRED`
- `TEMPLATE_ALREADY_LINKED`
- `SESSION_EXPIRED`
- `SESSION_ALREADY_CLAIMED`
- `SESSION_DEVICE_MISMATCH`
- `INVALID_QR`
- `SIGNATURE_INVALID`
- `LOW_QUALITY`
- `LIVENESS_FAIL`
- `VALIDATION_ERROR`

---

## 8. Database Design

### 8.1 `palm_identities` (One row per user)
**Purpose:** stores the authoritative enrolled mapping.

Columns:
- `user_id` (unique)
- `device_id` (not null)
- `template_id` (not null)
- `enrolled_at`
- `revoked_at` *(optional)*
- timestamps

Constraints:
- `UNIQUE(user_id)`
  Ensures one template per user.
- `UNIQUE(device_id, template_id)`
  Ensures template is not reused across users and is unique per device.

---

### 8.2 `palm_enrollment_sessions`
Columns:
- `id` (uuid)
- `user_id`
- `status`
- `expires_at`
- `qr_nonce`
- `claimed_device_id`
- `failure_code`
- timestamps

Indices:
- `user_id`, `status`, `expires_at`

---

## 9. Security Requirements

### 9.1 What must never happen
- Do not store palm images in backend DB or logs.
- Do not accept raw palm images into Laravel unless unavoidable.
- Do not allow session reuse across devices.

### 9.2 Transport security
- All endpoints via HTTPS (TLS).
- POS should have device-specific credentials.
- HMAC-sign QR data to prevent forging sessions.

### 9.3 Logging hygiene
- Never log `qr_data` in full in production logs.
- Never log sensitive biometric payloads (if any).
- Log only:
  - session id
  - device id
  - result codes
  - timestamps

---

## 10. Flutter (Customer App) Implementation Notes

### 10.1 UI steps (typical)
1. “Generate QR and show it”
2. “Waiting for scan”
3. “Enrollment complete”

### 10.2 Customer app logic
- Call `POST /api/palm/enroll/sessions`
- Render `qr_data` with `qr_flutter`
- Poll `GET /api/palm/enroll/sessions/{id}` every 1–2 seconds
- Stop polling when status becomes:
  - `enrolled` → show success
  - `failed` → show error + allow retry
  - `expired` → regenerate session

### 10.3 Retry behavior
- On expired session: create a new session (new QR).
- On `ALREADY_ENROLLED`: show “Reset required” and offer reset CTA.

---

## 11. POS Implementation Notes (Scanner + Backend)

### 11.1 POS flow
- Scan QR (serial scanner / camera)
- Call `POST /api/palm/enroll/sessions/claim`
- Start scanner enrollment via SDK
- On SDK result:
  - success: you get `template_id`
  - failure: you get vendor error code/quality feedback
- Call `POST /api/palm/enroll/sessions/{id}/submit-result`

### 11.2 Minimum SDK info to pass
- `device_id`
- `template_id` (success)
- `quality_score` and `liveness` if available

---

## 12. Text Sequence Diagrams

### 12.1 Enrollment (Happy Path)
```text
Customer App           Laravel Backend               POS App               Palm SDK/Device
    | POST /sessions         |                         |                         |
    |----------------------->|                         |                         |
    |<-- session_id,qr_data--|                         |                         |
    | Display QR             |                         |                         |
    |                        |      scan QR            |                         |
    |                        |<------------------------|                         |
    |                        |  POST /claim            |                         |
    |                        |<------------------------|                         |
    |                        |-- 200 claimed --------->|                         |
    |                        |                         | start enrollment        |
    |                        |                         |------------------------>|
    |                        |                         |<--- template_id --------|
    |                        | POST /submit-result     |                         |
    |                        |<------------------------|                         |
    |                        | store palm_identities   |                         |
    |                        |-- 200 enrolled -------->|                         |
    | poll /sessions/{id}    |                         |                         |
    |----------------------->|                         |                         |
    |<------ status=enrolled-|                         |                         |
    | show success           |                         |                         |
```

### 12.2 Enrollment (Already Enrolled)
```text
Customer App -> POST /sessions -> Laravel
Laravel -> 409 ALREADY_ENROLLED
Customer App -> show "Reset required" -> optional POST /me/reset
```

### 12.3 Enrollment (Template Already Linked)
```text
POS -> submit-result(template_id) -> Laravel
Laravel detects UNIQUE(device_id,template_id) conflict -> 409 TEMPLATE_ALREADY_LINKED
POS shows error + stops
```

---

## 13. Testing Checklist

### 13.1 Backend
- Create session returns valid HMAC QR
- Claim rejects invalid signature
- Claim locks session to a `device_id`
- Submit-result rejects:
  - wrong device_id
  - expired session
  - already enrolled user
  - template already linked
- Reset allows a new session creation and enrollment

### 13.2 Customer app
- QR renders correctly
- Polling stops on terminal state
- UI handles expired/failed states cleanly

### 13.3 POS app
- QR scan → claim → SDK enrollment → submit-result works end-to-end
- Properly displays backend error codes

---

## 14. Future Extensions (Out of Scope)
- Palm vein verification for payments
- Payment gateway tokenization and charging
- Device-to-algorithm-service direct matching
- Persistent customer QR payment flow

---
**End of document**
