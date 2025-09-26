# Environment Variables Setup

This project uses environment variables to store sensitive information like API keys and secrets. Follow these steps to set up your environment:

## 1. Create Configuration File

Copy the example configuration file and fill in your actual values:

```bash
cp pacepal/Configuration.example.plist pacepal/Configuration.plist
```

## 2. Update Configuration Values

Edit `pacepal/Configuration.plist` and replace the placeholder values with your actual credentials:

- `StravaClientId`: Your Strava application client ID
- `StravaClientSecret`: Your Strava application client secret
- `KeychainAccessTokenKey`: A unique key for storing access tokens in keychain
- `KeychainRefreshTokenKey`: A unique key for storing refresh tokens in keychain
- `KeychainExpiresAtKey`: A unique key for storing token expiration in keychain

## 3. Security Notes

- **Never commit `Configuration.plist`** - it's already added to `.gitignore`
- The `Configuration.example.plist` file is safe to commit as it contains only placeholder values
- Keep your actual API keys and secrets secure and never share them publicly

## 4. Strava API Setup

To get your Strava API credentials:

1. Go to [Strava API Settings](https://www.strava.com/settings/api)
2. Create a new application
3. Set the Authorization Callback Domain to match your app's redirect URI
4. Copy the Client ID and Client Secret to your configuration file

## 5. Keychain Keys

Generate unique, random strings for your keychain keys. You can use online generators or create them programmatically. These keys should be:
- Unique to your application
- Random and unpredictable
- Different from the example values

## 6. Verification

After setting up your configuration, the app should load without any configuration-related errors. The `ConfigurationService` will automatically load the values from your plist file when the app starts.
