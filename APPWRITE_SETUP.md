# MyNest — Appwrite Setup Guide

## Step 1: Create a Project
1. Go to [Appwrite Console](https://cloud.appwrite.io)
2. Create a new project called **MyNest**
3. Copy the **Project ID**

## Step 2: Create a Database
1. In your project, go to **Databases**
2. Create a database called **mynest_db**
3. Copy the **Database ID**

## Step 3: Create Collections

### Collection: `users`
| Attribute | Type | Required |
|-----------|------|----------|
| userId | String (255) | Yes |
| fullName | String (255) | Yes |
| dateOfBirth | String (50) | No |
| email | String (255) | Yes |
| profileSetupComplete | Boolean | No |

### Collection: `family_members`
| Attribute | Type | Required |
|-----------|------|----------|
| userId | String (255) | Yes |
| fullName | String (255) | Yes |
| dateOfBirth | String (50) | No |
| gender | String (20) | No |
| relation | String (100) | No |
| relatedTo | String (255) | No |
| notes | String (1000) | No |
| photoUrl | String (500) | No |
| isDeceased | Boolean | No (default: false) |
| isApproved | Boolean | No (default: true) |

**Indexes to create:**
- Key: `userId` → Attribute: `userId` → Type: Key
- Key: `isApproved` → Attribute: `isApproved` → Type: Key

### Collection: `memories`
| Attribute | Type | Required |
|-----------|------|----------|
| userId | String (255) | Yes |
| title | String (255) | Yes |
| story | String (5000) | No |
| photoUrl | String (500) | No |
| audioUrl | String (500) | No |
| taggedPersonId | String (255) | No |
| taggedPersonName | String (255) | No |
| contributorName | String (255) | No |
| contributorRelation | String (255) | No |
| eventDate | String (100) | No |
| location | String (255) | No |
| isApproved | Boolean | No (default: true) |
| status | String (50) | No (default: "raw") |

**Indexes to create:**
- Key: `userId` → Attribute: `userId` → Type: Key
- Key: `isApproved` → Attribute: `isApproved` → Type: Key
- Key: `taggedPersonId` → Attribute: `taggedPersonId` → Type: Key

## Step 4: Create Storage Bucket
1. Go to **Storage**
2. Create bucket called **mynest_files**
3. Set max file size to **20MB**
4. Allow file extensions: jpg, jpeg, png, heic, mp3, wav, m4a

## Step 5: Set Permissions
For each collection and the storage bucket:
- Set **Document Security** to enabled
- Add role **Any** with permissions: Create, Read
- Add role **Users** with permissions: Create, Read, Update, Delete

## Step 6: Add Platform
1. Go to project **Settings** → **Platforms**
2. Add **Android** platform with package name: `com.mynest.mynest_app`
3. Add **Web** platform with hostname: `localhost` (for dev)

## Step 7: Update Config in Code

### Flutter App
Edit `lib/config/appwrite_config.dart`:
```dart
static const String endpoint = 'https://cloud.appwrite.io/v1';
static const String projectId = 'YOUR_PROJECT_ID';    // ← paste here
static const String databaseId = 'YOUR_DATABASE_ID';  // ← paste here
```

### Web Portal
Edit `mynest_web/index.html`:
```javascript
const APPWRITE_ENDPOINT = 'https://cloud.appwrite.io/v1';
const APPWRITE_PROJECT = 'YOUR_PROJECT_ID';    // ← paste here
const APPWRITE_DATABASE = 'YOUR_DATABASE_ID';  // ← paste here
```

## Done! 🎉
Now run the Flutter app with: `flutter run`
