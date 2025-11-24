# Cloudinary FREE Setup Guide - 25 GB Storage (No Payment!)

## 🎯 Goal: FREE Unlimited Image Storage with Cloudinary

Cloudinary offers **25 GB storage + 25 GB bandwidth/month** completely FREE - no credit card required!

---

## 📝 Step 1: Create FREE Cloudinary Account

1. Go to: **https://cloudinary.com/users/register/free**

2. Sign up with:
   - Email
   - Or use Google/GitHub login

3. Fill in:
   - **Name**: Your name
   - **Email**: Your email
   - **Password**: Choose password
   - **Cloud name**: Choose a unique name (e.g., `ibalik-yourname`)
     - This will be your `CLOUD_NAME`
     - Can't be changed later!

4. Click **"Create Account"**

5. Verify your email

---

## 🔑 Step 2: Get Your Credentials

After login, you'll see the **Dashboard**:

### Find Your Credentials:

1. Look for **"Product Environment Credentials"** section
2. You'll see:
   ```
   Cloud name: dxxxxxxxxxxxxx
   API Key: 123456789012345
   API Secret: xxxxxxxxxxxxxxxxxxxxxxxxx
   ```

3. **Copy your `Cloud name`** - you'll need it!

---

## 🔧 Step 3: Create Upload Preset (Important!)

1. In Cloudinary Dashboard, click **Settings** (⚙️ icon top-right)

2. Go to **"Upload"** tab

3. Scroll down to **"Upload presets"** section

4. Click **"Add upload preset"**

5. Configure:
   - **Preset name**: `flutter_lost_items` (or any name)
   - **Signing Mode**: Select **"Unsigned"** ⚠️ (Important!)
   - **Folder**: Leave blank or use `lost_items`
   - **Use filename**: Enable if you want
   - **Unique filename**: Enable (recommended)
   - **Overwrite**: Disable

6. Click **"Save"**

7. **Copy the preset name** - you'll need it!

---

## 💻 Step 4: Update Your Flutter App

Open `lib/services/cloudinary_service.dart` and update these lines:

```dart
// Line 11-12: Replace with YOUR credentials
static const String _cloudName = 'YOUR_CLOUD_NAME'; // e.g., 'dxxxxxxx'
static const String _uploadPreset = 'YOUR_UPLOAD_PRESET'; // e.g., 'flutter_lost_items'
```

### Example:
```dart
static const String _cloudName = 'dqf3k4rtn'; // Your cloud name
static const String _uploadPreset = 'flutter_lost_items'; // Your preset name
```

---

## ✅ Step 5: Test It!

1. Run your app:
   ```bash
   flutter run
   ```

2. Try posting an item with photos

3. Check Cloudinary Dashboard:
   - Go to **"Media Library"**
   - You should see your uploaded images in `lost_items` folder!

---

## 📊 Your FREE Limits

| Feature | Free Tier |
|---------|-----------|
| **Storage** | 25 GB |
| **Bandwidth** | 25 GB/month |
| **Transformations** | 25,000 credits/month |
| **Upload requests** | Unlimited |
| **Credit card** | NOT REQUIRED ✅ |

### How many posts can you handle?

With our compression (300 KB per image, 5 images per post):

| Posts | Storage | Status |
|-------|---------|---------|
| 1,000 | 1.5 GB | ✅ Excellent |
| 5,000 | 7.5 GB | ✅ Great |
| 10,000 | 15 GB | ✅ Good |
| 16,000 | 25 GB | ✅ At limit |

**With 90-day auto-cleanup**: You'll never hit the limit! 🎉

---

## 🔒 Security: Make Preset Unsigned

⚠️ **Important**: Your upload preset MUST be "unsigned" for the app to work.

To verify:
1. Settings → Upload → Upload presets
2. Click on your preset
3. Check **"Signing Mode"** = **"Unsigned"**
4. If it says "Signed", change it to "Unsigned"

---

## 🎨 Bonus Features (FREE)

Cloudinary includes FREE:
- ✅ **Automatic image optimization**
- ✅ **Format conversion** (JPEG, PNG, WebP)
- ✅ **Responsive images**
- ✅ **Image transformations** (crop, resize, effects)
- ✅ **Global CDN** (fast loading worldwide)
- ✅ **Backup & versioning**

---

## 🔍 View Your Images

### In Cloudinary Dashboard:
1. Click **"Media Library"** in left sidebar
2. Navigate to **`lost_items`** folder
3. See all uploaded images organized by item ID

### In Your App:
Images are automatically displayed using the Cloudinary URLs returned from upload.

---

## 🛠️ Troubleshooting

### Error: "Upload preset not found"
- Check that preset is **unsigned**
- Verify preset name matches exactly in code
- Wait 1-2 minutes after creating preset

### Error: "Invalid cloud name"
- Verify cloud name in Dashboard
- No spaces or special characters
- Exact match required

### Images not uploading
1. Check internet connection
2. Verify credentials in `cloudinary_service.dart`
3. Check Cloudinary Dashboard → Usage for errors
4. Try creating a new upload preset

---

## 💰 Cost Comparison

| Service | Free Storage | Free Bandwidth | Credit Card? |
|---------|--------------|----------------|--------------|
| **Cloudinary** | 25 GB | 25 GB/month | NO ✅ |
| Firebase Storage | 5 GB | 1 GB/day | NO ✅ |
| AWS S3 | 5 GB (12 months) | 15 GB | YES ❌ |
| Google Cloud | 5 GB (90 days) | 1 GB | YES ❌ |

**Cloudinary is the BEST free option!** 🏆

---

## 📱 Your Setup Checklist

- [ ] Created Cloudinary account
- [ ] Copied Cloud name
- [ ] Created upload preset (unsigned)
- [ ] Copied preset name
- [ ] Updated `cloudinary_service.dart` with credentials
- [ ] Ran `flutter pub get`
- [ ] Tested posting item with photos
- [ ] Verified images in Cloudinary Media Library

---

## 🎉 You're Done!

Your app now has:
✅ **FREE 25 GB storage**
✅ **No payment required**
✅ **Automatic image optimization**
✅ **Fast global CDN**
✅ **Professional image management**

Enjoy your unlimited free storage! 🚀
