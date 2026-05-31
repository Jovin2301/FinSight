# 💰 FinSight (Apollo 11)

> **Track smarter. Budget better.**

FinSight is a personal finance application designed to help students and young adults take control of their spending. It allows users to record daily expenses, visualise spending habits through an interactive dashboard, and monitor budgets — all in one place.

---

## 🎯 Motivation

Many students struggle to keep track of their spending, especially when small but frequent expenses — such as meals, transport, shopping, and subscriptions — add up over time. Existing finance applications can feel too complicated or feature-heavy for students who simply want a clear and convenient way to monitor their expenses.

FinSight addresses this by making personal finance tracking more organised and meaningful, helping users understand their financial behaviour, identify unnecessary spending, and make more informed budgeting decisions.

---

## ✨ Features

| Feature | Description | Status |
|---|---|---|
| User Authentication | Secure login to access personal financial records | 🔄 In Progress |
| Dashboard Visualisation | Overview of balance, income, expenses, and recent transactions | ✅ Prototype Ready |
| Expense Management | Add, view, edit, and delete expense records (CRUD) | 🔄 In Progress |
| Profile & Settings | Manage user details and financial preferences | ✅ Prototype Ready |
| Budget Monitoring | Set spending limits and track against actual spending | 🔄 Planned |
| Transaction Filtering | Filter expenses by date, category, or type | 🔄 Planned |
| Budget Alerts | Notifications when spending approaches budget limits | 📋 Planned |
| Spending Insights | AI-driven insights on spending patterns and overspending risks | 📋 Planned |

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter |
| Backend | Node.js with Express |
| Database | PostgreSQL |
| ML / Insights | Python with all the relevant python libraries |
| Version Control | Git & GitHub |

---

## 🏗️ System Architecture

**Current Prototype (Milestone 1)**
The prototype consists of a Flutter frontend using sample/local data to demonstrate the intended user flow and interface.

**Planned System**
```
Flutter Frontend
      ↕ HTTP Requests
Node.js / Express REST API
      ↕ SQL Queries
PostgreSQL Database
```

The Flutter frontend will communicate with a Node.js/Express REST API, which acts as middleware between the application and the PostgreSQL database. The backend will expose API endpoints for authentication, expense CRUD operations, budget tracking, and dashboard summaries.

---

## 📱 Current Progress (Milestone 1)

The current prototype demonstrates the following user flow:

```
Login → Dashboard → Transactions → Add/Edit Expense → Profile/Settings
```

### Screens Implemented
- **Login Screen** — Demonstrates the intended authentication flow (currently uses hardcoded credentials)
- **Dashboard** — Displays a summary of finances using sample data (balance, income, expenses, recent transactions)
- **Transactions** — Lists expense records with access to the edit screen
- **Add/Edit Expense** — Allows updating of expense title, amount, category, and date
- **Profile/Settings** — Displays user details and preferences (currency, income type, budget cycle, notifications, appearance)

> ⚠️ The current prototype is frontend-only. Backend integration, PostgreSQL storage, and persistent data are planned for later milestones.


---

## 🗓️ Development Plan

### Milestone 2
- [ ] PostgreSQL database integration
- [ ] Node.js/Express REST API connection
- [ ] Expense CRUD backend integration
- [ ] Dashboard real data integration
- [ ] Transaction filtering
- [ ] Basic budget alerts
- [ ] Login screen refinement (Google sign-in, email verification, password reset)
- [ ] Profile screen verification (username, email, password updates)
- [ ] UI/UX refinement
- [ ] Testing and debugging

### Milestone 3
- [ ] AI spending insights
- [ ] Spending trend analysis
- [ ] Budget monitoring improvements
- [ ] Final UI/UX polishing
- [ ] System and user testing
- [ ] Documentation update (README, poster, video)

---

## ⚙️ Setup Instructions

### Prerequisites
Ensure you have the following installed before running the application:
- [Flutter](https://docs.flutter.dev/get-started/install)
- [Android Studio](https://developer.android.com/studio) (for Android emulator)
- [Xcode](https://developer.apple.com/xcode/) (for iOS/macOS, macOS only)

### Running the App

```bash/terminal
# 1. Clone the repository
git clone https://github.com/Jovin2301/FinSight.git

# 2. Navigate into the project folder
cd FinSight/finsight

# 3. Install Flutter dependencies
flutter pub get

# 4. Run the application
flutter run
```

When prompted, select a supported device:
- **Chrome** — for web preview
- **macOS desktop** — for desktop preview
- **Android/iOS emulator** — if available

> 💡 No `.env` file is required for Milestone 1. The prototype runs on sample/local data with hardcoded login logic.

---

## 🔐 Software Engineering Practices

- **Version Control** — Git with meaningful commit messages and feature branches
- **Separation of Concerns** — Flutter (UI), Node.js (logic), PostgreSQL (data) kept clearly separated
- **RESTful API Design** — Consistent endpoints with proper HTTP methods and status codes
- **Input Validation & Sanitisation** — Validated on both frontend and backend to prevent SQL injection
- **Password Security** — Passwords hashed with bcrypt; no plaintext storage
- **Error Handling** — Graceful error handling with user-friendly messages
- **Code Modularity** — Reusable Flutter widgets and modular Express route files
- **Testing** — Unit, integration, and manual UI testing
- **Environment Variables** — Sensitive credentials stored in `.env` files, never hardcoded
- **Documentation** — Inline comments and maintained README

---

## 👥 Team

**Team Name:** FinSight

**Programme:** NUS Orbital 2026

**Team Member:** Jovin Wong See Xuan &amp; Lim Zhi Hui
