# Loan Agent App (Flutter)

Field Agent mobile app for the Loan Management System.  
Handles customer onboarding, document capture, loan application submission, field verification, and EMI collections.

## Features

| Feature | Description |
|---------|-------------|
| **Login** | Staff login with JWT (same credentials as admin panel) |
| **Dashboard** | Stats + quick actions |
| **Customers** | List, search, create (multi-step form + camera for KYC docs) |
| **Customer Detail** | Full profile + start loan from here |
| **Loan Applications** | List with filters, new application wizard (customer → product → eligibility → submit) |
| **Field Verification** | Mark KYC / Employment / Income / Field Visit complete |
| **Collections** | View active/disbursed loans and record EMI payments |
| **Profile** | Agent info + logout |

## UI

Modern fintech-style UI inspired by clean banking apps:
- Teal primary (`#00BFA5`)
- Soft cards, rounded corners
- Bottom navigation
- Multi-step wizards

## Setup

### 1. Prerequisites
- Flutter 3.16+ (`flutter doctor`)
- Android Studio / VS Code
- Backend server running (loan-management-server)

### 2. Configure API URL

Edit `lib/core/constants/api_constants.dart`:

```dart
// Android emulator → use 10.0.2.2
static const String baseUrl = 'http://10.0.2.2:8000';

// Real device → use your PC's LAN IP
// static const String baseUrl = 'http://192.168.1.10:8000';
```

Also ensure the backend CORS allows the origin or is open for mobile.

### 3. Install & Run

```bash
cd loan_agent_app
flutter pub get
flutter run
```

### 4. Login

Use any **staff user** created in the admin panel (Roles & Staff).

## Project Structure

```
lib/
├── core/
│   ├── constants/api_constants.dart
│   ├── network/api_client.dart
│   └── theme/app_theme.dart
├── models/
│   ├── user_model.dart
│   ├── customer_model.dart
│   └── loan_model.dart
├── services/
│   ├── auth_service.dart
│   ├── customer_service.dart
│   ├── loan_service.dart
│   └── group_service.dart
├── features/
│   ├── auth/          (login, auth_provider)
│   ├── dashboard/     (home shell, dashboard)
│   ├── customers/     (list, create, detail)
│   ├── loans/         (list, new wizard, detail + verification)
│   ├── collections/   (EMI collection)
│   └── profile/
├── widgets/common_widgets.dart
└── main.dart
```

## Backend APIs Used

- `POST /api/auth/login`
- `GET  /api/auth/me`
- `GET/POST /api/customers`
- `GET  /api/loans/products`
- `GET/POST /api/loans/applications`
- `PATCH /api/loans/applications/:id/status`
- `GET  /api/settings/loan-purposes`
- `POST /api/upload`

## Notes

- Cleartext HTTP is enabled for local development (`usesCleartextTraffic=true`).
- For production, switch to HTTPS and update `baseUrl`.
- Collection recording currently shows success UI; wire to a dedicated repayment endpoint when backend exposes `POST /api/loans/accounts/:id/repay`.
- Camera & storage permissions are declared for document capture.

## License

Private – for use with the Loan Management System.
