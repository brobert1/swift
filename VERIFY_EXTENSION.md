# How to Verify Extension is Working

## ✅ What I Fixed

1. **Added App Groups to Extension Entitlements**
   - Updated `MindfulBreakMonitor.entitlements`
   - Added `group.com.developer.mindfullness.shared`

2. **Added Extension Logging**
   - Extension now logs all events to App Group storage
   - Main app can read and display these logs

3. **Fixed Build Error**
   - Added `CODE_SIGN_ALLOW_ENTITLEMENTS_MODIFICATION = YES`
   - Extension should build successfully now

4. **Added Debug UI in Settings**
   - Shows extension status (Active/Not Running)
   - Displays extension logs
   - Refresh button to check latest status

## 🧪 How to Verify Extension is Running

### **Step 1: Build and Run**
1. Clean build folder (⇧⌘K)
2. Build for your physical device (⌘B)
3. Run on device (⌘R)

### **Step 2: Complete Onboarding**
1. Go through onboarding
2. Select Instagram (or any app)
3. **Enable monitoring** in Permissions step
4. Complete setup

### **Step 3: Check Extension Status**
1. Go to **Settings** tab
2. Scroll to **Debug** section
3. Look for **Extension Status**:
   - 🔴 **Red** = Not Running
   - 🟢 **Green** = Active ✅

### **Step 4: View Extension Logs**
If extension is running, you'll see logs like:
```
[2025-10-04T14:30:00Z] intervalDidStart
[2025-10-04T14:30:01Z] eventWillReachThresholdWarning: limit_app123
[2025-10-04T14:35:00Z] eventDidReachThreshold: limit_app456
```

**What Each Log Means:**
- `intervalDidStart` - Monitoring started (happens at midnight)
- `intervalDidEnd` - Monitoring ended (happens at 11:59 PM)
- `eventWillReachThresholdWarning` - 5 min warning before time limit
- `eventDidReachThreshold` - Time limit reached, app shielded!
- `intervalWillStartWarning` - Warning before monitoring starts
- `intervalWillEndWarning` - Warning before monitoring ends

### **Step 5: Trigger Extension Events**

**Force Monitoring Start:**
1. Go to Settings
2. Toggle monitoring OFF then ON
3. Check logs - should see `intervalDidStart`

**Test Time Limit:**
1. Set Instagram limit to 1 minute
2. Use Instagram for 1 minute
3. Extension should shield it automatically
4. Check logs - should see `eventDidReachThreshold`

## 🔍 Troubleshooting

### **Extension Shows "Not Running" (Red)**

**Possible Causes:**
1. **App Groups not configured in Xcode**
   - Open Xcode
   - Select **MindfulBreakMonitor** target
   - Go to **Signing & Capabilities**
   - Click **+ Capability**
   - Add **App Groups**
   - Check `group.com.developer.mindfullness.shared`

2. **Extension not embedded properly**
   - Check project.pbxproj includes extension
   - Verify "Embed Foundation Extensions" build phase exists

3. **Monitoring not started**
   - Go to onboarding Permissions step
   - Tap "Enable Monitoring"
   - Or toggle in Settings

4. **Extension needs time to launch**
   - iOS may take 10-30 seconds to start extension
   - Wait a bit, then tap "Refresh Extension Status"

### **No Logs Appearing**

**Try:**
1. Stop monitoring, then restart
2. Kill app completely (swipe up)
3. Reopen app and enable monitoring
4. Wait 30 seconds
5. Tap "Refresh Extension Status"

**Check Xcode Console:**
```bash
# Filter for extension logs
Window → Devices and Simulators → Select your device → View Device Logs
# Search for "EXTENSION" or "MindfulBreakMonitor"
```

### **Build Errors**

**If you see entitlements error:**
- Already fixed with `CODE_SIGN_ALLOW_ENTITLEMENTS_MODIFICATION = YES`
- Clean build folder and rebuild

**If extension won't compile:**
- Make sure FamilyControls framework is linked
- Check extension deployment target (iOS 16+)

## 📱 Manual Verification (Alternative)

If Debug section doesn't work, verify extension manually:

**1. Check in Xcode:**
- Window → Devices and Simulators
- Select your device
- Look for `MindfulBreakMonitor.appex` under MindfulBreak app

**2. Check with Console App:**
- Open Console.app on Mac
- Connect iPhone
- Filter: `process:MindfulBreakMonitor`
- Should see extension logs when events trigger

**3. Check Device Settings:**
- Settings → Screen Time → See All Activity
- Your app should appear in the list
- This confirms iOS recognizes the monitoring

## ✅ Success Indicators

**Extension is working if you see:**
- ✅ Green status in Settings → Debug
- ✅ Logs appear with timestamps
- ✅ `intervalDidStart` log when monitoring begins
- ✅ `eventDidReachThreshold` when you hit time limit
- ✅ App automatically shields when limit reached

## 🎯 Next Steps After Verification

Once extension is confirmed working:

1. **Test Automatic Shielding:**
   - Set very short limit (1-5 min)
   - Use app until limit
   - Should see gray shield screen

2. **Check Shield Status:**
   - Dashboard shows "Apps Shielded" status
   - Orange shield icon appears

3. **Implement Challenge System:**
   - User completes challenge
   - Grant temporary unlock (5-10 min)
   - Re-shield after grace period

## 📊 Expected Flow

**When Extension Works Correctly:**

```
User uses Instagram → 55 min
                ↓
Extension: eventWillReachThresholdWarning (5 min left)
                ↓
User continues → 60 min (limit reached)
                ↓
Extension: eventDidReachThreshold
                ↓
Extension: Automatically shields Instagram
                ↓
Dashboard: Shows "Apps Shielded"
                ↓
User tries to open Instagram → Gray shield
                ↓
User opens MindfulBreak → Completes challenge
                ↓
[YOUR NEXT FEATURE] Temporary unlock
```

## 🛠️ Quick Fix Checklist

- [ ] Extension target added to Xcode ✅
- [ ] Extension has App Groups capability
- [ ] Entitlements file has App Groups ✅
- [ ] `CODE_SIGN_ALLOW_ENTITLEMENTS_MODIFICATION = YES` ✅
- [ ] Built for physical device
- [ ] Monitoring enabled in app
- [ ] Debug section shows green status
- [ ] Logs appear when monitoring starts

---

**TIP:** The easiest way to verify is:
1. Build & run
2. Complete onboarding with monitoring enabled
3. Go to Settings → Debug
4. If you see green "Active" → Extension works! 🎉
5. If red "Not Running" → Add App Groups capability in Xcode
