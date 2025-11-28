# Firestore Security Rules Deployment Guide

## Overview
This guide explains how to deploy the Firestore security rules for the iBalik app to ensure proper access control for the Return Confirmation flow and other claim operations.

## Prerequisites
- Firebase CLI installed (`npm install -g firebase-tools`)
- Authenticated with Firebase (`firebase login`)
- Firebase project initialized in the workspace

## Deployment Steps

### 1. Verify Rules File
Ensure `firestore.rules` exists in the project root:
```
c:\Users\DELL\Desktop\iBalik\firestore.rules
```

### 2. Test Rules Locally (Optional but Recommended)
```bash
firebase emulators:start --only firestore
```

### 3. Deploy to Firebase
```bash
cd c:\Users\DELL\Desktop\iBalik
firebase deploy --only firestore:rules
```

### 4. Verify Deployment
- Go to [Firebase Console](https://console.firebase.google.com/)
- Select your project: `flutter-ibalik`
- Navigate to **Firestore Database** → **Rules** tab
- Verify the rules are updated with the latest timestamp

## Security Rules Summary

### Claims Collection Rules
The new rules enforce the following access control for claims:

#### **Read Access**
- Claimer can read their own claims
- Founder (item poster) can read claims for their items

#### **Create Access**
- Any authenticated user can create a claim
- Must be the claimer (claimerId matches auth.uid)

#### **Update Access**
1. **Claimer Updates (Pending Claims)**
   - Claimer can update their own pending claims
   - Example: Adding proof images

2. **Founder Approval/Rejection**
   - Founder can approve or reject pending claims
   - Transition: `pending` → `approved` or `rejected`

3. **Founder Confirm Return** ✅ **NEW**
   - Only the founder can mark approved claims as completed
   - Transition: `approved` → `completed`
   - This enforces that only the item finder confirms the return

#### **Delete Access**
- Claimer can delete their own pending claims only

### Lost Items Collection Rules
- Item owner can update their items
- System can update status to `claimed` when a claim is approved
- Founder can update status to `returned` when confirming return

## Testing the Rules

### Test Case 1: Confirm Return (Should Succeed)
**Scenario**: Founder confirms return of an approved claim
```dart
// User: Founder (userId matches founderId in claim)
// Claim status: approved
// Action: Update status to completed
// Expected: ✅ Success
```

### Test Case 2: Unauthorized Return (Should Fail)
**Scenario**: Claimer tries to confirm return
```dart
// User: Claimer (userId matches claimerId, NOT founderId)
// Claim status: approved
// Action: Update status to completed
// Expected: ❌ Permission Denied
```

### Test Case 3: Invalid Status Transition (Should Fail)
**Scenario**: Founder tries to complete a pending claim
```dart
// User: Founder
// Claim status: pending (not approved)
// Action: Update status to completed
// Expected: ❌ Permission Denied
```

## Troubleshooting

### Error: "Permission Denied"
**Causes**:
1. User is not authenticated
2. User is not the founder of the item
3. Claim status is not "approved"
4. Firestore rules haven't been deployed

**Solutions**:
1. Ensure user is logged in
2. Check that `founderId` in claim matches current user's UID
3. Verify claim status is "approved" before confirming return
4. Deploy rules: `firebase deploy --only firestore:rules`

### Error: "Network Error"
**Causes**:
1. No internet connection
2. Firebase service unavailable

**Solutions**:
1. Check internet connection
2. Retry operation
3. Check Firebase status page

## Frontend Integration

The frontend code in `claim_details_page.dart` now includes:

### ✅ Authentication Checks
```dart
if (currentUser == null || currentUserId == null) {
  // Show "must be logged in" error
}
```

### ✅ Authorization Checks
```dart
if (!isFounder) {
  // Show "only finder can confirm" error
}
```

### ✅ Status Validation
```dart
if (currentStatus != 'approved') {
  // Show invalid status error
}
```

### ✅ Error Handling
```dart
on FirebaseException catch (e) {
  if (e.code == 'permission-denied') {
    // Show permission denied dialog with retry
  }
}
```

### ✅ Retry Mechanism
- Snackbar with "Retry" action for network errors
- Dialog with "Retry" button for permission errors
- Automatic claim data reload on retry

## Next Steps

1. **Deploy the rules**:
   ```bash
   firebase deploy --only firestore:rules
   ```

2. **Test the flow**:
   - Create a test item
   - Submit a claim
   - Approve the claim as founder
   - Confirm return as founder ✅
   - Try confirming as claimer (should fail) ❌

3. **Monitor in production**:
   - Check Firebase Console → Firestore → Usage tab
   - Monitor for permission denied errors
   - Adjust rules if needed based on real usage

## Important Notes

⚠️ **Status Transition Flow**:
```
pending → approved/rejected (by founder)
approved → completed (by founder confirming return)
```

⚠️ **Security**:
- Only founder can confirm return (enforced by rules)
- Frontend validates before calling Firestore
- Backend (Firestore rules) validates again for security

⚠️ **Data Integrity**:
- Claims can only transition through valid states
- Completed claims cannot be modified
- Deleted claims (pending only) cannot be recovered
