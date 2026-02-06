# Hardware Integration Guide (Customer App + POS App)
This project has two separate application roles:
- Customer app (Flutter mobile): creates sessions, shows QR, polls backend.
- POS app (Flutter on Android POS device): reads QR from scanner/camera, interacts with palm vein hardware SDK, and submits results to backend.

The customer app does not talk to palm hardware. Hardware integration is exclusively a POS responsibility.

## 1) Hardware in scope
### 1.1 Palm vein device (enrollment)
- Example model referenced in docs: Leshun LSP980 / LS* series
- Output expected by backend: `template_id` (plus optional quality/liveness metadata)

### 1.2 QR code scanning on POS
Two patterns are referenced:
- Serial port barcode/QR scanner (common on POS hardware)
  - Example serial device path: `/dev/ttyHSL3`
  - Example baud rate: `9600`
- Camera scanning (only if serial scanner not available)

## 2) Customer App (Flutter) — what to implement
Customer app responsibilities are session-oriented, not hardware-oriented:
- Create an enrollment session via backend.
- Render the returned short-lived `qr_data` as a QR image on screen.
- Poll session status until it becomes terminal: `enrolled`, `failed`, or `expired`.
- Provide reset UX if backend returns `ALREADY_ENROLLED` / reset-required behavior.

### 2.1 Customer app does not need native hardware code
No vendor SDK files are required in the customer app for enrollment. The customer app simply displays a QR and waits for the POS device to complete enrollment.

### 2.2 Customer enrollment session flow (recommended)
Backend endpoints referenced in docs:
- `POST /api/palm/enroll/sessions`
- `GET /api/palm/enroll/sessions/{session_id}`
- `GET /api/palm/me/status`
- `POST /api/palm/me/reset`

UI state machine (typical):
- Generate QR (status `created`)
- Waiting for scan (status changes to `claimed`)
- Enrollment complete (status `enrolled`) or error (`failed`/`expired`)

## 3) POS App (Flutter on Android POS device) — what to implement
POS app responsibilities include hardware integration and backend submission:
- Read the enrollment session QR payload from the scanner/camera.
- Call backend to claim the session and bind it to a stable `device_id`.
- Start palm enrollment via vendor SDK.
- Receive `template_id` from SDK on success (or vendor error code on failure).
- Submit the result to backend.

Backend endpoints referenced in docs:
- `POST /api/palm/enroll/sessions/claim`
- `POST /api/palm/enroll/sessions/{session_id}/submit-result`

### 3.1 Native Android code is required for POS hardware
In most POS devices, you will need native Android integration for:
- Serial port reading from `/dev/tty*`
- Palm vein enrollment SDK (vendor-provided `.aar`/`.jar`)

Flutter communicates with native Android using platform channels:
- `MethodChannel` for one-shot calls (claim/start enrollment)
- `EventChannel` for continuous streams (scanner input, enrollment progress)

Suggested platform channel surface:
- `scanQrStream()` → stream of scanned strings (EventChannel)
- `scanQrOnce()` → one scanned string (MethodChannel, optional)
- `startPalmEnrollment()` → returns `{ template_id, quality_score, liveness }` or `{ error_code, error_message }`

## 4) Vendor SDK files (where they are on your machine)
These are not committed into this repo currently; they exist in your local Downloads.

### 4.1 Palm SDK (.aar) bundle
Path:
- `/Users/alinawab/Downloads/leshun_plam_v2.10/libs/`

Observed libraries:
- `BaseLine-1.00.aar`
- `ShunPalm-2.01.aar`
- `ShunPalm-LS2-2.10.aar`

Notable contents (high-level):
- Java/Kotlin classes under `com.leshun.support.shunpalm.*` and `com.api.stream.*`
- Native `.so` libraries under `jni/` (e.g., `arm64-v8a`)
- Model assets under `assets/models/`

### 4.2 POS hardware adapter / serial utilities (.jar)
Path:
- `/Users/alinawab/Downloads/LeShun Xinke LSF980 Series Horizontal Consumer Machine API User Manual V1.01/`

Observed libraries:
- `com.leshun.hwadapter_1.13.jar` (includes `SerialPortAdapter`, `NFCAdapter`, `SystemAdapter`, etc.)
- `printsdk.jar` (also includes an `android_serialport_api` implementation)

## 5) Integration approach (recommended)
### 5.1 Customer app
- Keep it pure Dart/Flutter.
- Implement only the enrollment session APIs + QR rendering + polling.
- No native SDK dependencies.

### 5.2 POS app
- Implement a thin native Android layer:
  - Serial scanner reader (device file → stream of strings)
  - Palm enrollment SDK wrapper (start enrollment → return `template_id`)
- Expose the minimal primitives to Dart via platform channels.
- Keep business rules in Dart:
  - “scan → claim → enroll → submit-result” state machine
  - UI mapping for backend error codes

## 6) Security and data handling rules (must-follow)
- Do not store raw palm images.
- Do not log full QR payloads in production logs.
- Treat `template_id` as a sensitive identifier; avoid logging it.
- Use HTTPS and POS-specific authentication for POS endpoints.

## 7) What is already implemented in this repo (Customer app)
- QR display uses `qr_flutter`: [my_qr_code_screen.dart](file:///Users/alinawab/Flutter%20Tasks/palmpay/lib/features/qr_code/screens/my_qr_code_screen.dart)
- Palm enrollment UI is currently only a placeholder (no backend session flow): [enroll_palm_vein_screen.dart](file:///Users/alinawab/Flutter%20Tasks/palmpay/lib/features/payment_methods/screens/enroll_palm_vein_screen.dart)
- No native platform channels exist yet: [MainActivity.kt](file:///Users/alinawab/Flutter%20Tasks/palmpay/android/app/src/main/kotlin/com/example/palmpay/MainActivity.kt)
