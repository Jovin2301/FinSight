# 💰 FinSight (Apollo 11)

Try the app here: https://ms3-finsight.vercel.app/


## 👥 Team

**Team Name:** FinSight

**Programme:** NUS Orbital 2026

**Level of Achievement:** Apollo 11

**Team Members:** Jovin Wong See Xuan & Lim Zhi Hui



> **Track smarter. Budget better.**

FinSight is a full-stack personal finance application designed to help students and young adults manage their spending more clearly. Users can record and manage transactions, monitor category budgets, track saving goals, receive budget notifications, scan receipts and bills, export transaction data, and view financial summaries through a dashboard.

---

## 🎯 Motivation

Many students and young adults struggle to keep track of their spending, especially when small but frequent expenses such as meals, transport, shopping and subscriptions accumulate over time. Although each expense may appear insignificant on its own, their combined impact can make it difficult for users to understand where their money has gone.

Existing personal finance applications may contain complex banking, investment or accounting tools that are unnecessary for users who only want a simple way to monitor everyday spending. Some budgeting applications also place useful features behind paid subscriptions. As a result, users may only realise that they have overspent after exceeding their budgets.

FinSight addresses this problem by combining transaction management, category budgets, saving goals, spending visualisations and budget notifications in one application. Users may enter transactions manually or use receipt scanning to reduce repetitive data entry. Bills and subscriptions can also be tracked separately from one-time expenses. In addition to issuing a notification when budget usage reaches 80%, FinSight uses a machine-learning risk service to identify users who may be at risk of overspending based on their current spending progress.

---

## ✨ Features

### Main Prototype Features

| Feature | Description | Status |
|---|---|---|
| Transaction Management | Add, edit, delete, search and filter transactions. Receipt scanning can pre-fill transaction details before confirmation. Synced with dashboard, budgets and analytics | ✅ Completed |
| Budget Management | Create, edit and delete category budgets, with automatic spending-progress updates. Active budgets are shown while inactive budgets remain for history/ML training | ✅ Completed |
| Budget Alerts & Notifications | Automatic notifications when spending reaches predefined thresholds (e.g. 80%), plus alerts from the ML overspending prediction service | ✅ Completed |
| Saving Goals | Create, edit and monitor multiple saving goals with progress tracked from recorded contributions | ✅ Completed |
| Dashboard / Home Overview | Consolidated view of recent transactions, spending summaries, category breakdowns, active budgets, saving goals and notifications | ✅ Completed |
| Topic / Help Pages | Financial tips, FAQs, privacy information and support pages | ✅ Completed |
| Receipt Scanning | Upload a receipt image for OCR processing; extracted merchant, amount, date and suggested category shown for user verification | ✅ Completed |
| Bill & Subscription Scanning | Record recurring bills/subscriptions manually or via OCR-assisted scanning, tracked separately from one-time expenses | ✅ Completed |
| Advanced Spending Insights (ML) | Machine-learning model predicts overspending likelihood, complementing rule-based budget alerts with earlier warnings | ✅ Completed |
| Data Exporting | Export transaction records for backup, reporting or analysis in external tools | ✅ Completed |

### Supporting Features

| Feature | Description | Status |
|---|---|---|
| Login & Registration | Secure account creation and login | ✅ Implemented |
| Profile & Preferences | Update currency, budget cycle, notification settings and appearance | ✅ Implemented |
| Privacy, Terms & Security | Information on how the app handles user data | ✅ Implemented |
| Splash Page | Animated landing page while the app loads | ✅ Implemented |
| Change Password | Change password with password-strength validation | ✅ Implemented |

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter / Dart |
| Backend | Node.js with Express, deployed on Render |
| Database | Supabase — PostgreSQL |
| Machine Learning | Python |
| OCR / Scanning | ML Kit / Tesseract OCR |
| Version Control | Git & GitHub |

---

## 🏗️ System Architecture

FinSight follows a three-tier architecture, with a separate machine-learning service and OCR service supporting the core app:

```
Flutter Frontend
      ↕ HTTP REST API Requests
Node.js / Express Backend (Render)
      ↕ SQL Queries              ↕ Risk scoring
Supabase PostgreSQL DB      Machine-Learning Service
      ↕
OCR / Scanning Service (receipts & bills)
```

The Flutter frontend handles UI, navigation, forms, charts, and data display. The Node.js/Express backend manages API endpoints, JWT authentication, request validation, and business logic. Supabase PostgreSQL stores all persistent user and finance-related data. The ML service predicts overspending risk, and the OCR service extracts details from scanned receipts and bills.

### Component Responsibilities

| Component | Responsibility |
|---|---|
| Flutter Frontend | Displays the interface, manages navigation and state, collects input, calls backend APIs, and renders charts and summaries |
| Node.js / Express Backend | Provides REST API endpoints, validates JWTs, processes requests, and applies business logic |
| Supabase PostgreSQL | Stores persistent user, preference, transaction, budget, notification, saving-goal, and recurring-payment data |
| OCR / Scanning Service | Extracts merchant, amount, date, category and bill details from uploaded receipt/bill images |
| Machine-Learning Service | Predicts overspending risk from transaction and budget data, returning a risk score |
| JWT Authentication | Creates signed tokens after login and protects user-specific endpoints |
| bcrypt | Hashes passwords before storage and verifies them securely during login |
| Environment Variables | Stores database config, API URLs, and secret keys separately from source code |

### Design Patterns Used

| Pattern | Where It Was Used | Why It Was Used |
|---|---|---|
| Router Pattern | Express route files (users, budgets, transactions, notifications, recurring payments) | Groups related API endpoints and keeps routing organised |
| Service Layer Pattern | Backend service files handling DB queries/logic separately from routes | Keeps route handlers clean and separates concerns |
| Strategy Pattern | ML overspending prediction used when data is available; rule-based alerts as fallback | Supports both ML-based insights and simple threshold alerts |
| Chain of Responsibility | Auth and validation middleware before route handlers | Ensures protected routes are checked before feature logic runs |

---

## 🗄️ Database Design

The database is centred around the **User** table, with all finance-related records linked to a specific account.

### Main Tables

| Table | Purpose |
|---|---|
| User | Stores core identity and authentication data |
| User Preference | Stores personalisation settings (currency, theme, budget cycle, notifications) |
| Transaction History | Records every income and expense entry; primary source for insights and budget tracking |
| Transaction Category | Classifies transactions into groups (e.g. Food, Transport, Salary) |
| Budget | Stores spending limits per category for a defined period |
| Saving Goals | Tracks financial targets and progress |
| Notification | Stores system-generated alerts and their read status |
| Recurring Transactions | Stores bills/subscriptions separately from one-time transactions, enabling auto-generation of future transactions and bill reminders |

---

## 📱 Current Progress (Milestone 3)

The application is now an integrated full-stack prototype with all main finance-tracking features, OCR-based scanning, ML prediction, data export, and automated/system/user testing implemented and refined.

```
Splash → Login / Register → Home Dashboard → Transactions (manual or OCR scan)
→ Bills & Subscriptions → Budgets → Budget/ML Alerts → Saving Goals
→ Data Export → Profile / Preferences / Change Password → Help Pages
```

### Key Improvements from Milestone 2

- Bills & subscriptions: create, view, edit, delete, with OCR-assisted pre-fill
- Receipt scanning via OCR to extract merchant, amount, date and category
- Transaction data export for backup/external analysis
- Budget interface updated to separate active vs. inactive budgets
- Profile editing, preferences, and change-password with strength validation
- Machine-learning overspending risk service deployed alongside rule-based fallback notifications
- UI refinements based on user-testing feedback
- Automated tests added across frontend logic, backend endpoints and integrated flows
- Multiple bug fixes (dashboard refresh, budget calculation consistency, form validation, navigation)

---

## ⚙️ Setup Instructions

### Prerequisites

Ensure you have the following installed:
- [Flutter](https://docs.flutter.dev/get-started/install)
- [Android Studio](https://developer.android.com/studio) (for Android emulator)
- [Xcode](https://developer.apple.com/xcode/) (for iOS/macOS — macOS only)
- [Node.js](https://nodejs.org/)

### Running the App

```bash
# 1. Clone the repository
git clone https://github.com/Jovin2301/FinSight.git

# 2. Navigate into the project folder
cd FinSight/finsight

# 3. Obtain the .env file and replace BASE_URL with your own IP address

# 4. Install backend dependencies and start the server
npm install
node server.js

# 5. Install Flutter dependencies
flutter pub get

# 6. Run the application
flutter run
```

When prompted, select a supported device:
- **Chrome** — for web preview
- **macOS desktop** — for desktop preview
- **Android/iOS emulator** — if available

> ⚠️ Ensure the `.env` file is obtained before running. Replace `BASE_URL` with your own IP address.

### macOS Configuration

For local development on macOS, the following entitlements are required:

**`macos/Runner/DebugProfile.entitlements`** and **`macos/Runner/Release.entitlements`**:
```xml
<key>com.apple.security.network.client</key>
<true/>

<key>com.apple.security.files.downloads.read-write</key>
<true/>
```

The `files.downloads.read-write` entitlement is required for the data-export feature to write CSV/PDF files to device storage during macOS development.

**`ios/Runner/Info.plist`**:
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

---

## 🔐 Software Engineering Practices

- **Version Control** — Git with meaningful commit messages, feature branches, pull requests, GitHub Issues, labels and milestones for task tracking
- **Separation of Concerns** — Flutter (UI), Node.js (logic), PostgreSQL (data), ML service and OCR service kept clearly separated
- **Code Modularity** — Screens, models, and reusable components separated in Flutter; routes and service logic organised by feature in Express
- **RESTful API Design** — Consistent endpoints using appropriate HTTP methods (GET, POST, PUT, DELETE)
- **Input Validation** — Validated on both frontend and backend to reduce invalid records
- **Password Security** — Passwords hashed with bcrypt; no plaintext storage
- **JWT Authentication** — Protected API endpoints verify bearer tokens after login
- **Error Handling** — Graceful error handling with user-friendly feedback
- **Environment Variables** — Sensitive credentials stored outside committed source code
- **Testing** — Unit, integration/API, system/widget, automated CI checks (GitHub Actions), and user testing with 5 testers via Google Form
- **Documentation** — Maintained README, project log and GitHub Issues throughout development

---

## 🧪 Testing Summary

| Test Type | Purpose | Result |
|---|---|---|
| Unit Testing | Budget/goal progress, transaction & recurring-payment model conversion, receipt/bill parsing | ✅ Pass |
| Integration / API Testing | Login, budgets, transactions, notifications, recurring payments routes | ✅ Pass |
| System / Widget Testing | App startup, navigation, login validation, budget card interaction | ✅ Pass |
| Automated Checks (CI/CD) | Dart formatting, Flutter analysis, Flutter tests w/ coverage, backend `npm test`, GitHub Actions | ✅ Pass |
| User Testing | 5 testers via Google Form covering usability, clarity and feature usefulness | ✅ Completed |

---

## 🚧 Current Limitations

- OCR accuracy depends on image quality/layout; users must review extracted details before saving
- ML risk model is limited by training data size/diversity and relies on recognised budget-category name mappings
- ML service is deployed separately; falls back to rule-based budget notifications if temporarily unavailable
- Data export currently provides a standard export only (no date-range/category/field selection yet)

---

## 🗓️ Future Improvements

| Area | Planned Work |
|---|---|
| Quick Transaction Entry | Gesture-based shortcut (e.g. double-tap on phone back) to open a quick-add transaction screen |
| Part-Time Income Tracking | Hourly income tracking for users on hourly salary type, calculating earnings from hours worked |
| Smart Budget Recommendations | Suggest personalised budget limits based on past spending history and income |
| Shared / Group Budgets | Shared budgets for roommates or group expenses with tracking of who owes what |
| OCR Accuracy | Improve text extraction for varied/low-quality receipts; add fallback manual-correction prompts for low-confidence scans |
| Data Export | Allow selecting date ranges, categories or fields before exporting |
