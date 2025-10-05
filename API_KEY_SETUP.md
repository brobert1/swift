# API Key Setup

This project uses OpenAI API for generating AI challenges. To run the app, you need to configure your API key.

## Setup Instructions

### Option 1: Using Config.plist (Recommended)

1. Copy the template file:
   ```bash
   cp MindfulBreak/Config-Template.plist MindfulBreak/Config.plist
   ```

2. Open `MindfulBreak/Config.plist` and replace `YOUR_OPENAI_API_KEY_HERE` with your actual OpenAI API key

3. Add `Config.plist` to Xcode project (if not already added):
   - Right-click on `MindfulBreak` folder in Xcode
   - Select "Add Files to MindfulBreak..."
   - Select `Config.plist`
   - Make sure "Copy items if needed" is checked
   - Click "Add"

4. **IMPORTANT**: `Config.plist` is already in `.gitignore` so it won't be committed to git

### Option 2: Using Environment Variable

Set the `OPENAI_API_KEY` environment variable in your Xcode scheme:

1. In Xcode, select **Product > Scheme > Edit Scheme...**
2. Select **Run** from the left sidebar
3. Go to **Arguments** tab
4. Under **Environment Variables**, add:
   - Name: `OPENAI_API_KEY`
   - Value: `your-api-key-here`

### Option 3: Hardcode (NOT RECOMMENDED - For Testing Only)

In `MindfulBreak/Config.swift`, uncomment line 28 and add your key:

```swift
// Option 3: Hardcode for testing (REMOVE BEFORE PRODUCTION)
return "sk-proj-your-api-key-here"
```

**⚠️ WARNING**: Never commit this change to git!

## Getting an OpenAI API Key

1. Go to https://platform.openai.com/api-keys
2. Sign in or create an account
3. Click "Create new secret key"
4. Copy the key and store it securely

## Cost Estimates

- Model used: `gpt-4o-mini`
- Cost per challenge: ~$0.0001-0.0003 (very cheap)
- Expected monthly cost: < $1 for typical usage

## Security Notes

- **Never commit** `Config.plist` to version control
- **Never hardcode** API keys in source code that will be committed
- The `.gitignore` file is configured to exclude `Config.plist` automatically
- If you accidentally commit your key, **revoke it immediately** at https://platform.openai.com/api-keys
