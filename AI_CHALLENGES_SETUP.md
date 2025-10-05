# AI-Powered Challenges Setup Guide

## Overview

Your Neura app now uses OpenAI's GPT-4o-mini to generate **personalized, dynamic challenges** based on user interests!

## What Was Added

### New Files

1. **`AIChallengeModels.swift`** - Data models for AI challenges
2. **`AIChallengeGenerator.swift`** - OpenAI integration service
3. **`DynamicChallengeView.swift`** - SwiftUI view for AI challenges
4. **`Config.swift`** - API key configuration

### Modified Files

1. **`ChallengeView.swift`** - Integrated AI challenge loading with fallback
2. **`DataStore.swift`** - Pre-generates challenges when interests are saved

## How It Works

```
User selects interests (Fitness, Reading, Music, etc.)
          ↓
Pre-generates 3 AI challenges in background
          ↓
When user hits app limit → ChallengeView appears
          ↓
Shows loading spinner → Calls OpenAI API
          ↓
AI generates custom challenge based on interests
          ↓
User completes challenge → App unlocks
```

## Setup Instructions

### Step 1: Get OpenAI API Key

1. Go to [https://platform.openai.com/api-keys](https://platform.openai.com/api-keys)
2. Sign up or log in
3. Click "Create new secret key"
4. Copy the key (starts with `sk-proj-...`)

### Step 2: Add API Key to Your Project

**Option A: Environment Variable (Recommended for Development)**

```bash
# In Xcode, edit the scheme:
# Product → Scheme → Edit Scheme → Run → Arguments → Environment Variables
# Add:
OPENAI_API_KEY = sk-proj-your-actual-key-here
```

**Option B: Config.plist (Recommended for Production)**

1. Create a file named `Config.plist` in your project
2. Add to `.gitignore` to avoid committing secrets
3. Add this content:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>OPENAI_API_KEY</key>
    <string>sk-proj-your-actual-key-here</string>
</dict>
</plist>
```

**Option C: Hardcode (Testing Only - NOT RECOMMENDED)**

Edit `Config.swift`:

```swift
static var openAIAPIKey: String {
    return "sk-proj-your-actual-key-here"  // ⚠️ REMOVE BEFORE PRODUCTION
}
```

### Step 3: Add Files to Xcode

1. Open `MindfulBreak.xcodeproj`
2. Right-click on `MindfulBreak` folder
3. Select "Add Files to MindfulBreak..."
4. Add these files:
   - `AIChallengeModels.swift`
   - `AIChallengeGenerator.swift`
   - `DynamicChallengeView.swift`
   - `Config.swift`

### Step 4: Build and Run

```bash
# Clean build folder
Product → Clean Build Folder (⇧⌘K)

# Build
Product → Build (⌘B)

# Run
Product → Run (⌘R)
```

## How AI Challenges Work

### Example Prompts → Generated Challenges

**User Interests: Fitness**
```json
{
  "title": "Do 10 Pushups Right Now",
  "description": "Physical movement helps reset your mind and reduces the urge to mindlessly scroll.",
  "activityType": "fitness",
  "instructions": [
    "Find a clear space on the floor",
    "Get into pushup position",
    "Complete 10 pushups at your own pace",
    "Stand up and take a deep breath"
  ],
  "estimatedSeconds": 45
}
```

**User Interests: Music**
```json
{
  "title": "Hum Your Favorite Song",
  "description": "Musical engagement activates different parts of your brain and improves mood.",
  "activityType": "music",
  "instructions": [
    "Think of a song you love",
    "Hum or sing it for 30 seconds",
    "Focus on the melody and rhythm",
    "Notice how you feel afterward"
  ],
  "estimatedSeconds": 40
}
```

**User Interests: Reading, Learning**
```json
{
  "title": "Learn One New Word",
  "description": "Expanding your vocabulary stimulates your brain and makes you more articulate.",
  "activityType": "learning",
  "instructions": [
    "Open a dictionary or word-of-the-day app",
    "Read the definition carefully",
    "Use it in a sentence mentally",
    "Try to remember it for later"
  ],
  "estimatedSeconds": 60
}
```

## Features

### ✅ Implemented

- **Personalized challenges** based on 8 interest categories
- **Smart variety** - Avoids showing recent challenges
- **Intelligent fallback** - Uses hardcoded challenges if API fails
- **Challenge caching** - Pre-generates 3-5 challenges for instant loading
- **Cost-effective** - Uses `gpt-4o-mini` (90% cheaper than GPT-4)
- **Loading states** - Shows spinner while generating
- **Multi-step instructions** - Guides users through complex activities

### 🎯 Challenge Types Generated

Based on user interests:
- **Fitness**: Pushups, planks, jumping jacks, walks, stretches
- **Reading**: Book pages, poems, articles, quotes
- **Music**: Humming, listening, instrument playing, sound awareness
- **Mindfulness**: Breathing, meditation, gratitude, awareness exercises
- **Learning**: New words, facts, educational videos, languages
- **Art/Creativity**: Drawing, photography, poetry, sketching
- **Nature**: Observation, plants, fresh air, natural elements
- **Cooking**: Healthy snacks, water, herbs, mindful eating

## Cost Estimation

**GPT-4o-mini pricing** (as of 2025):
- Input: $0.15 per 1M tokens
- Output: $0.60 per 1M tokens

**Per challenge generation:**
- ~500 input tokens (prompt)
- ~200 output tokens (response)
- **Cost: ~$0.0002 per challenge** (0.02 cents)

**Monthly usage (heavy user):**
- 10 challenges/day × 30 days = 300 challenges
- **Total: ~$0.06/month** per user

Very affordable! 💰

## Testing

### Test Without API Key

The app will automatically fall back to hardcoded challenges if:
- No API key is configured
- OpenAI API is down
- Rate limit exceeded
- Network error

### Test AI Challenges

1. Set up API key
2. Run the app
3. Complete onboarding and select interests (e.g., "Fitness", "Reading")
4. Add an app to monitor and enable it
5. Trigger the challenge screen
6. You should see:
   - Loading spinner
   - AI-generated challenge title
   - Custom instructions based on your interests

### Debug Logs

Check Xcode console for:
```
✅ Loaded 2 cached AI challenges
🔄 Pre-generating 3 AI challenges in background...
✅ Pre-generated challenge 1/3: Do 10 Pushups
✅ AI Challenge loaded: Walk 100 Steps
⚠️ Failed to generate AI challenge: Missing API key
```

## Troubleshooting

### "Missing API key" error
- Check `Config.swift` → `openAIAPIKey` returns non-empty string
- Verify environment variable is set in Xcode scheme
- Try Option C (hardcode) for quick testing

### "Invalid response from OpenAI"
- Check your API key is valid at [https://platform.openai.com/api-keys](https://platform.openai.com/api-keys)
- Ensure you have billing set up (even with free credits)
- Check internet connection

### Challenges don't match interests
- The AI uses user interests from `DataStore.shared.userInterests`
- Make sure users select interests during onboarding
- Check console logs to see what interests are sent to API

### Always shows hardcoded challenges
- API key might be invalid
- Network request might be failing
- Check console for error messages

## Advanced Customization

### Change AI Model

Edit `AIChallengeGenerator.swift`:

```swift
private let model = "gpt-4o"  // More creative, more expensive
// or
private let model = "gpt-4o-mini"  // Faster, cheaper (default)
```

### Adjust Challenge Creativity

Edit `AIChallengeGenerator.swift`:

```swift
temperature: 0.8  // Default (balanced)
temperature: 1.2  // More creative/varied
temperature: 0.5  // More focused/consistent
```

### Change Cache Size

Edit `AIChallengeGenerator.swift`:

```swift
private let maxCachedChallenges = 20  // Store more challenges
```

### Modify Prompt

Edit the `buildPrompt()` function in `AIChallengeGenerator.swift` to:
- Add new challenge categories
- Change duration ranges
- Customize instruction style
- Add specific requirements

## Next Steps (Optional Enhancements)

1. **Analytics**: Track which challenges users complete most
2. **Difficulty levels**: Easy/Medium/Hard based on user progress
3. **Streaks**: Reward users for completing challenges X days in a row
4. **Custom challenges**: Let users create and save their own
5. **Voice challenges**: Text-to-speech for audio instructions
6. **Challenge history**: Show completed challenges with timestamps
7. **Social sharing**: Share favorite challenges with friends

## Security Notes

⚠️ **NEVER commit your API key to git!**

Add to `.gitignore`:
```
Config.plist
*.xcuserstate
```

## Support

If you encounter issues:
1. Check Xcode console logs
2. Verify API key is valid
3. Test with fallback challenges (remove API key temporarily)
4. Check OpenAI status: [https://status.openai.com](https://status.openai.com)

---

**Congratulations!** 🎉 You now have AI-powered, personalized challenges in your app!
