# DRIFT × Splitwise: Expense Sharing Feature — Research & Implementation Plan

**Date:** June 29, 2026  
**App:** DRIFT (Flutter Web, GitHub Pages static hosting)  
**Goal:** Add Splitwise-style group expense sharing

---

## 1. Splitwise Feature Breakdown

### Core UX Flow
1. **Create group** → name it, set currency, add members
2. **Share invite** → link or code friends open in their browser
3. **Add expenses** → who paid, how much, split how, category, date
4. **View balances** → net position per person, simplified debts
5. **Settle up** → record payments, balances update

### Split Methods
| Method | Example | Use case |
|--------|---------|----------|
| Equal | $100 ÷ 4 = $25 each | Dinner, taxi |
| Exact amounts | A=$30, B=$15, C=$55 | Different orders |
| Percentage | A=60%, B=40% | Tip split, tax |
| Shares | A=2 shares, B=1 share | Room size difference |

### Simplify Debts Algorithm
- **Problem:** N people can have up to N×(N-1) pairwise debts
- **Solution:** Greedy matching — match biggest debtor with biggest creditor, settle min of the two, repeat
- **Result:** At most N-1 transactions
- **Complexity:** O(n log n) — fast enough for travel groups (2-10 people)

### Other Features
- **Categories:** Food, Transport, Accommodation, Activity, Shopping, Other
- **Multi-currency:** Convert at expense creation time using exchange rate API
- **Settlements:** Record cash/Venmo/transfer payments (no actual payment processing)
- **Receipts:** Photo upload (v2 — requires cloud storage)
- **Recurring expenses:** Weekly/monthly auto-creation (v2)

---

## 2. Architecture Decision: The Big Choice

### Constraint
DRIFT is hosted on GitHub Pages — **static only, no server**. This is the defining constraint.

### Options Analysis

| Approach | Real-time | Offline | Privacy | Cost | Complexity |
|----------|-----------|---------|---------|------|------------|
| **Firebase Firestore** | ✅ Native | ✅ Built-in | ⚠️ Google | Free tier generous | Low |
| **Supabase** | ✅ Native | ⚠️ Manual | ⚠️ AWS | Free 500MB | Low-Med |
| **Client-only + JSON export** | ❌ Manual | ✅ Always | ✅ Perfect | Free | Medium |
| **WebRTC P2P** | ✅ Direct | ❌ All online | ✅ Perfect | Free | High |
| **GitHub Gist as DB** | ❌ Poll | ❌ | ⚠️ GitHub | Free | Low |

### ✅ RECOMMENDED: Firebase Firestore (Spark Plan — Free)

**Why Firebase wins for DRIFT:**

1. **Real-time sync** — when Solo adds an expense, Ahmed sees it instantly (WebSocket, no polling)
2. **Offline-first** — Firestore caches to IndexedDB. Works on spotty hotel WiFi. Syncs when back online. *This is critical for travel.*
3. **Free tier is plenty** — 50K reads/day, 20K writes/day. A 10-day trip with 5 people logging 20 expenses/day = ~2K reads/day. Well within limits.
4. **Anonymous auth** — no email/password needed. User gets a random ID. Privacy preserved.
5. **Flutter Web support** — `cloud_firestore` package works natively in browser.
6. **No credit card** — Spark plan is free forever.
7. **Security rules** — trip data only accessible to members with the trip code.

**Privacy approach:**
- Use **anonymous auth** (no personal data)
- Trip code = random UUID (e.g., `DRIFT-A7X9K2`)
- Firestore Security Rules: only users who are members of a trip can read/write its data
- Optional: client-side encryption of expense descriptions using trip code as key

**Cost:** $0/month forever (unless you exceed free tier, which won't happen for personal travel)

---

## 3. Data Model

### New Classes

```dart
// ─── Trip Group (replaces/augments TripData for sharing) ───
class TripGroup {
  final String id;           // UUID, also the share code
  final String name;         // "Vietnam 2026"
  final String currency;     // Base currency (OMR, USD, etc.)
  final List<TripMember> members;
  final List<SharedExpense> expenses;
  final List<Settlement> settlements;
  final DateTime createdAt;
  final String createdBy;    // memberId of creator
}

// ─── Group Member ───
class TripMember {
  final String id;           // Firebase anonymous UID
  final String name;         // Display name ("Solo", "Ahmed")
  final String? email;       // Optional, for notifications
  final DateTime joinedAt;
  final bool isCurrentUser;  // Local flag
}

// ─── Shared Expense ───
class SharedExpense {
  final String id;
  final String description;   // "Dinner at Quán Ăn Ngon"
  final double amount;        // In expense currency
  final String currency;      // Original currency
  final double amountInBase;  // Converted to group base currency
  final String category;      // Food, Transport, etc.
  final String paidBy;        // memberId
  final Map<String, double> splits; // memberId -> amount owed
  final SplitMethod splitMethod;
  final DateTime date;
  final int dayNumber;        // Day of trip (1-13)
  final String? receiptUrl;   // v2
  final DateTime createdAt;
  final String createdBy;     // memberId
}

enum SplitMethod { equal, exact, percentage, shares }

// ─── Settlement (recording a payment between members) ───
class Settlement {
  final String id;
  final String fromMemberId;  // Who paid
  final String toMemberId;    // Who received
  final double amount;
  final String currency;
  final DateTime date;
  final String? note;         // "Venmo transfer"
}
```

### Firestore Structure
```
trips/{tripId}                    → TripGroup document
trips/{tripId}/members/{userId}   → TripMember documents
trips/{tripId}/expenses/{expId}   → SharedExpense documents
trips/{tripId}/settlements/{sId}  → Settlement documents
```

---

## 4. Debt Simplification Algorithm (Dart Implementation)

```dart
class SettlementSuggestion {
  final String fromMemberId;
  final String toMemberId;
  final double amount;
  SettlementSuggestion(this.fromMemberId, this.toMemberId, this.amount);
}

List<SettlementSuggestion> simplifyDebts(Map<String, double> netBalances) {
  // netBalances: memberId -> net amount
  //   positive = owed money, negative = owes money
  
  final debtors = <_Balance>[];  // people who owe money
  final creditors = <_Balance>[]; // people who are owed money
  
  for (final entry in netBalances.entries) {
    if (entry.value < -0.01) {
      debtors.add(_Balance(entry.key, -entry.value)); // store as positive
    } else if (entry.value > 0.01) {
      creditors.add(_Balance(entry.key, entry.value));
    }
  }
  
  // Sort: biggest first
  debtors.sort((a, b) => b.amount.compareTo(a.amount));
  creditors.sort((a, b) => b.amount.compareTo(a.amount));
  
  final suggestions = <SettlementSuggestion>[];
  var i = 0, j = 0;
  
  while (i < debtors.length && j < creditors.length) {
    final amount = math.min(debtors[i].amount, creditors[j].amount);
    
    suggestions.add(SettlementSuggestion(
      debtors[i].memberId, creditors[j].memberId, amount
    ));
    
    debtors[i] = _Balance(debtors[i].memberId, debtors[i].amount - amount);
    creditors[j] = _Balance(creditors[j].memberId, creditors[j].amount - amount);
    
    if (debtors[i].amount < 0.01) i++;
    if (creditors[j].amount < 0.01) j++;
  }
  
  return suggestions;
}
```

**Properties:**
- At most N-1 transactions for N people
- O(n log n) time complexity
- Handles any split configuration
- Produces intuitive results (biggest debts settled first)

---

## 5. Multi-Currency Strategy

### Approach
- Each group has a **base currency** (set at creation, defaults to first user's preference)
- Expenses logged in any currency
- **Conversion at creation time** using free API
- Store both original amount AND converted amount

### Free Exchange Rate APIs
| API | Free Tier | Auth | Reliability |
|-----|-----------|------|-------------|
| `open.er-api.com` | Unlimited | None | Good |
| `openexchangerates.org` | 1K/mo | App ID | Excellent |
| `exchangerate-api.com` | 1.5K/mo | None | Good |

**Recommendation:** `https://open.er-api.com/v6/latest/USD` — no API key needed, returns JSON with 160+ currencies.

### Caching
- Cache rates in localStorage with timestamp
- Refresh every 24 hours
- Fallback to last known rate if offline

---

## 6. Feature Roadmap

### v1 — MVP (What we build first)
- [ ] Trip group creation with share code
- [ ] Join group via code
- [ ] Add expense (equal split, single currency)
- [ ] View group balance dashboard
- [ ] Simplify debts (who pays whom)
- [ ] Record settlement
- [ ] Firebase anonymous auth + Firestore
- [ ] Real-time sync across browsers
- [ ] Offline support (Firestore cache)
- [ ] Categories (Food, Transport, Accommodation, Activity, Shopping, Other)

### v2 — Enhanced
- [ ] Unequal splits (exact amounts, percentages, shares)
- [ ] Multi-currency with auto-conversion
- [ ] Expense editing/deletion
- [ ] Comments on expenses
- [ ] Daily expense summary
- [ ] Export to CSV
- [ ] Receipt photo upload (Firebase Storage)

### v3 — Premium
- [ ] Recurring expenses
- [ ] Payment reminders
- [ ] Spending analytics/charts
- [ ] Splitwise import (migrate existing groups)
- [ ] Custom categories

---

## 7. Implementation Plan (Ordered)

### Phase 1: Firebase Setup (You do this — 10 minutes)
1. Go to console.firebase.google.com
2. Create project "drift-expenses"
3. Enable Authentication → Anonymous provider
4. Create Firestore database (start in test mode)
5. Get config values (apiKey, projectId, etc.)
6. Give me the config — I'll wire it into the Flutter app

### Phase 2: Data Models + Firebase Service (Me — 2-3 hours)
1. Add `cloud_firestore`, `firebase_core`, `firebase_auth` to pubspec.yaml
2. Create `lib/models/expense_models.dart` (TripGroup, TripMember, SharedExpense, Settlement)
3. Create `lib/services/expense_service.dart` (CRUD + realtime listeners)
4. Create `lib/services/exchange_rate_service.dart` (currency conversion)
5. Implement `simplifyDebts()` algorithm

### Phase 3: UI Screens (Me — 3-4 hours)
1. **Group Create/Join screen** — entry point (new tab in app bar)
2. **Group Dashboard** — balance overview, member list, activity feed
3. **Add Expense sheet** — amount, payer, split method, category, day
4. **Settle Up flow** — record payment, select amount
5. **Integrate into existing nav** — add "Expenses" button next to "Budget"

### Phase 4: Polish + Deploy (Me — 1-2 hours)
1. Loading states, error handling
2. Offline indicator
3. Deploy to GitHub Pages
4. Test with 2 browsers side-by-side

### Phase 5: Sri Lanka & Indonesia (You confirm dates, I add configs)
1. Add CityConfig entries (already partially done!)
2. Confirm itinerary
3. Generate trip

---

## 8. What I Need From You

### For Firebase Setup (Phase 1):
1. Create a Firebase project at console.firebase.google.com
2. Enable **Anonymous Authentication**
3. Create a **Firestore** database
4. Copy the Firebase config object (it looks like):
```javascript
const firebaseConfig = {
  apiKey: "AIza...",
  authDomain: "drift-expenses.firebaseapp.com",
  projectId: "drift-expenses",
  storageBucket: "drift-expenses.appspot.com",
  messagingSenderId: "123...",
  appId: "1:123...:web:abc..."
};
```
5. Send me those values (they're public — security comes from Firestore Rules)

### For Firestore Security Rules (I'll write these, you paste them):
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /trips/{tripId} {
      allow read, write: if request.auth != null 
        && request.auth.uid in resource.data.memberIds;
    }
  }
}
```

### For Destinations:
- Sri Lanka: dates + which cities
- Indonesia: dates + which cities

---

## 9. Existing DRIFT Code Integration Points

| File | What changes |
|------|-------------|
| `pubspec.yaml` | Add firebase_core, cloud_firestore, firebase_auth |
| `lib/main.dart` | Initialize Firebase on startup |
| `lib/screens/home_screen.dart` | Add "Expenses" button to FAB column |
| `lib/screens/cost_screen.dart` | Can stay as-is (budget estimate) or merge with expenses |
| `lib/models/trip_data.dart` | Add `groupId` field to link TripData to TripGroup |
| `lib/data/city_configs.dart` | Already has Sri Lanka & Indonesia! ✅ |
| New: `lib/models/expense_models.dart` | TripGroup, TripMember, SharedExpense, Settlement |
| New: `lib/services/expense_service.dart` | Firebase CRUD + realtime listeners |
| New: `lib/services/exchange_rate_service.dart` | Currency conversion |
| New: `lib/screens/expense_group_screen.dart` | Main expense sharing screen |
| New: `lib/screens/create_group_screen.dart` | Create/join group flow |
| New: `lib/screens/expense_detail_screen.dart` | View/edit single expense |
| New: `lib/widgets/add_expense_sheet.dart` | Bottom sheet for adding expenses |
| New: `lib/widgets/balance_card.dart` | Balance display widget |
| New: `lib/widgets/settlement_card.dart` | Settlement suggestion widget |
