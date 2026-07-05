# 💰 FinSight (Apollo 11)

Try the app here: https://finsight2-orbitalnus.vercel.app/

> **Track smarter. Budget better.**

FinSight is a personal finance application designed to help students and young adults take control of their spending. It allows users to record daily expenses, monitor category budgets, track saving goals, receive budget alerts, and visualise spending habits through an interactive dashboard — all in one place.

---

## 🎯 Motivation

Many students struggle to keep track of their spending, especially when small but frequent expenses — such as meals, transport, shopping, and subscriptions — add up over time. While each expense may seem small on its own, the total can become difficult to monitor without a clear record.

Existing finance applications can also feel too complicated or feature-heavy for students who mainly want a simple way to track daily expenses and budgets. As a result, users may only realise they have overspent after it has already happened.

FinSight addresses this by making personal finance tracking simpler and more organised, helping users understand where their money goes and make more informed budgeting decisions.

---

## ✨ Features

### Main Features

| Feature | Description | Status |
|---|---|---|
| Transaction Management | Add, view, edit, delete, and filter transactions; view spending charts | ✅ Implemented |
| Budget Management | Create, view, edit, and delete category budgets with real-time progress tracking | ✅ Implemented |
| Budget Alerts & Notifications | Receive warnings when spending reaches the alert threshold; view and mark notifications as read | ⚠️ Partially Implemented |
| Saving Goals | Create and update saving goals; track progress manually | ✅ Implemented |
| Dashboard Overview | View recent transactions, spending summaries, category breakdown, budget progress, and saving goal progress | ✅ Implemented |
| Topic / Help Pages | Access FAQ pages and financial guidance | ✅ Implemented |

### Supporting Features

| Feature | Description | Status |
|---|---|---|
| Login & Registration | Secure account creation and login with hashed passwords | ✅ Implemented |
| Profile & Preferences | Update currency, budget cycle, notification settings, and appearance | ✅ Implemented |
| Privacy, Terms & Security | Essential information on how the app handles user data | ✅ Implemented |
| Splash Page | Animated landing page while the app loads | 📋 Planned |
| Onboarding Tutorial | Guide new users through the app setup | 📋 Planned |
| Change Password | Allow users to reset forgotten passwords | 📋 Planned |
| Remember Me / Auto Login | Keep users signed in to reduce login friction | 📋 Planned |

### Planned Milestone 3 Features

| Feature | Description | Status |
|---|---|---|
| Receipt Scanning | Extract transaction details from receipts for user confirmation | 📋 Planned |
| Bill & Subscription Scanning | Detect recurring payments and send reminders | 📋 Planned |
| AI Spending Insights | Analyse patterns and predict future spending | 📋 Planned |
| Data Export | Export transaction data for personal analysis | 📋 Planned |

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter / Dart |
| Backend | Node.js with Express |
| Database | Supabase — PostgreSQL |
| Version Control | Git & GitHub |
| Planned MS3 Extensions | Python / OCR |

---

## 🏗️ System Architecture

FinSight follows a three-tier architecture:

```
Flutter Frontend
      ↕ HTTP REST API Requests
Node.js / Express Backend
      ↕ SQL Queries
Supabase PostgreSQL Database
```

The Flutter frontend handles UI, navigation, forms, charts, and data display. The Node.js/Express backend manages API endpoints, JWT authentication, request validation, and business logic. Supabase PostgreSQL stores all persistent user and finance-related data.

### Component Responsibilities

| Component | Responsibility |
|---|---|
| Flutter Frontend | Displays the interface, manages navigation and state, collects input, calls backend APIs, and renders charts and summaries |
| Node.js / Express Backend | Provides REST API endpoints, validates JWTs, processes requests, and applies business logic |
| Supabase PostgreSQL | Stores persistent user, preference, transaction, budget, notification, and saving-goal data |
| JWT Authentication | Creates signed tokens after login and protects user-specific endpoints |
| bcrypt | Hashes passwords before storage and verifies them securely during login |
| Environment Variables | Stores database config, API URLs, and JWT secrets separately from source code |

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

## 📱 Current Progress (Milestone 2)

The prototype is now a functional full-stack application. The main demonstrable flow is:

```
Login / Register → Home Dashboard → Transactions → Add / Edit Transaction
→ Budgets → Budget Alerts / Notifications → Saving Goals → Profile / Help Pages
```

### Key Improvements from Milestone 1

- Full transaction CRUD with filtering
- Spending visualisations: category pie chart and monthly bar chart
- Category budget creation with real-time progress tracking
- Budget warning notifications when spending reaches 80% of the limit
- Saving goal creation, editing, deletion, and progress tracking
- Profile and preference settings (currency, budget cycle, notifications, appearance)
- Financial topic and FAQ pages
- Backend and database integration (Node.js/Express + Supabase PostgreSQL)
- Password hashing with bcrypt
- JWT-based authentication for protected API routes

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

### macOS HTTP Configuration

For local development on macOS, the following changes are required to allow HTTP access. These should be reverted before any public release.

**`macos/Runner/DebugProfile.entitlements`** and **`macos/Runner/Release.entitlements`**:
```xml
<key>com.apple.security.network.client</key>
<true/>
```

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

- **Version Control** — Git with meaningful commit messages, feature branches, pull requests, and GitHub Issues for task tracking
- **Separation of Concerns** — Flutter (UI), Node.js (logic), and PostgreSQL (data) kept clearly separated in a three-tier architecture
- **Code Modularity** — Screens, models, and reusable components separated in Flutter; routes and logic organised by feature in Express
- **RESTful API Design** — Consistent endpoints using appropriate HTTP methods (GET, POST, PUT, DELETE)
- **Input Validation** — Validated on both frontend and backend to reduce invalid records
- **Password Security** — Passwords hashed with bcrypt; no plaintext storage
- **JWT Authentication** — Protected API endpoints verify bearer tokens after login
- **Error Handling** — Graceful error handling with user-friendly feedback
- **Environment Variables** — Sensitive credentials stored in `.env` files, never committed to source control
- **Documentation** — Inline comments and maintained README throughout development

---

## 🗓️ Development Plan

### Milestone 3

| Area | Planned Work |
|---|---|
| Receipt Scanning | Extract transaction details from receipts; users confirm before saving |
| Bill & Subscription Scanning | Detect recurring payments, billing dates, and amounts |
| AI Spending Insights | Identify unusual spending patterns and overspending risks |
| Spending Trend Analysis | Analyse transaction data over time for habit tracking |
| Data Export | Allow users to export transaction data for personal analysis |
| Budget Monitoring Improvements | Clearer progress indicators and more useful feedback |
| UI/UX Polishing | Improve clarity, responsiveness, and ease of use based on testing |
| Testing & Bug Fixing | System testing, user testing, edge-case handling |
| Documentation Update | Final README, project log, poster, and video |

---

## 👥 Team

**Team Name:** FinSight

**Programme:** NUS Orbital 2026

**Team Members:** Jovin Wong See Xuan & Lim Zhi Hui
