# Naitri — customer mobile app (Flutter)

Handset-loan customer app for Naitri Credit Co-operative Society. Structure and
navigation modelled on common finance apps (Home / Service / Scan QR / Pay EMIs /
Menu), with Naitri branding. Talks to the `naitri-crm` backend's `/api/app` routes.

## Screens
- **Login + OTP** — phone → one-time code (in dev the code is `123456` and auto-fills)
- **Home** — search, "Your relations" (your loans), quick actions, bottom nav
- **Loan details** — Overview / Schedule / Transactions + device lock status
- **Pay EMIs** — Overdue / Upcoming lists, one-tap Pay
- **Make payment** sheet — upcoming / advance / part-pre / overdue / foreclosure
- **Verify handover** — captures two photos: your selfie + a selfie with the handset

## Run
```bash
flutter pub get
# start the backend first (see naitri-crm), then:
flutter run
```

### Point the app at your server
Default base URL is `http://10.0.2.2:3000/api/app` (Android emulator → your PC's localhost).
Override without editing code:
```bash
flutter run --dart-define=API=https://api.naitri.in/api/app
```

## Made to run fast
- Lightweight stack: `http` only, no heavy state-management framework.
- Bottom tabs use `IndexedStack` + `AutomaticKeepAlive` → instant switching, no reload.
- Lists use `ListView.builder` (lazy). `const` widgets throughout to cut rebuilds.
- Each screen is **one** API call; the backend `/api/app` endpoints avoid N+1 queries.
- Selfies are compressed on-device (`imageQuality: 70`, `maxWidth: 1080`) before upload.

## Notes
- Payments here mark the EMI paid directly. In production, open a UPI / payment-gateway
  flow and call `/api/app/pay` only on gateway success, passing the real reference.
- Device lock status is **read-only** for customers; locking/unlocking stays in the
  super-admin portal. The screen explains how to get the phone unlocked (clear dues).
- `usesCleartextTraffic` is on for local http testing — turn it off and use https in production.
