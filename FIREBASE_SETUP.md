# Firebase Setup — DRIFT Expense Sharing

## ✅ Status
- Project created: **drift-expenses**
- Config deployed: **DONE**
- Anonymous Auth required: **YES** — enable in Firebase Console
- Firestore Rules: **PASTE BELOW**

---

## Step 1: Enable Anonymous Authentication

1. Go to: https://console.firebase.google.com/project/drift-expenses/authentication
2. Click **"Get started"**
3. Under **"Sign-in method"** tab → **"Add new provider"** → select **"Anonymous"**
4. Toggle **Enable** → **Save**

---

## Step 2: Set Firestore Security Rules

1. Go to: https://console.firebase.google.com/project/drift-expenses/firestore/rules
2. Replace the default rules with:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Trip documents — only members can read/write
    match /trips/{tripId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null
        && request.auth.uid in resource.data.memberUids;
      
      // Subcollections (members, expenses, settlements)
      match /{document=**} {
        allow read, write: if request.auth != null;
      }
    }
    
    // Deny everything else
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

3. Click **"Publish"**

---

## Step 3: Check Firestore Region (default is fine)

Your database creates instances in `nam5 (us-central)` by default. That's fine — lowest latency for most users.

---

## That's It!

After enabling Anonymous Auth + pasting rules:
1. Open https://solo-cipher.github.io/drift-app/
2. Tap the 👥 **Expenses** button (green FAB)
3. Create a group → share the code with friends
4. Everyone logs the same expenses → real-time balances appear

---

## 💰 Cost: $0 (Spark/Free Plan)

- **50K reads/day** — ~500 expense views per day
- **20K writes/day** — ~200 new expenses per day  
- **1 GiB storage** — millions of expense records
- **Anonymous auth** — unlimited users, no personal data

A 10-day trip with 5 friends logging 20 expenses/day = ~2K reads/day. **Well within free tier.**

---

## Optional: Upgrade to Blaze (if you ever need more)

If you exceed free limits (unlikely for personal travel):
1. Go to: Firebase Console → Usage and billing
2. Add a payment method → Blaze plan (pay-as-you-go)
3. Cost: ~$0.06/100K reads, ~$0.18/100K writes
4. You'd need ~300K reads/day before spending $1/month
