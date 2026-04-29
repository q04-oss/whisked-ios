# whisked-ios

Swift iOS app for the Whisked loyalty program. Built with SwiftUI, Swift Concurrency, and HMAC-signed requests to the [whisked-platform](https://github.com/q04-oss/whisked-platform) backend.

---

## Xcode setup (Mac required)

All Swift source files are in `Whisked/`. The Xcode project is created on a Mac:

1. **Open Xcode** → File → New → Project → iOS App
2. Name: `Whisked`, Team: your Apple Developer team, Bundle ID: `ca.whisked.app`
3. Language: Swift, Interface: SwiftUI, minimum deployment: iOS 17
4. Save into this repo directory — Xcode creates `Whisked.xcodeproj`
5. Delete the generated placeholder files (`ContentView.swift`, `WhiskedApp.swift`)
6. In Xcode: File → Add Files → select the `Whisked/` folder — add all files

### Secrets

```bash
cp Secrets.xcconfig.example Secrets.xcconfig
# Edit Secrets.xcconfig with your values
```

Wire Secrets.xcconfig into the project:
- Project → Info → Configurations → expand Debug and Release
- Set both to `Secrets`

Add to `Info.plist`:
```xml
<key>WHISKED_API_BASE_URL</key>
<string>$(WHISKED_API_BASE_URL)</string>
<key>WHISKED_HMAC_KEY</key>
<string>$(WHISKED_HMAC_KEY)</string>
```

---

## Architecture

```
Whisked/
  WhiskedApp.swift              @main entry — injects stores into environment
  Config.swift                  API base URL and HMAC key from Info.plist

  Networking/
    APIClient.swift             actor — HMAC-signed requests, JWT auth, token refresh
    APIError.swift              typed errors
    Keychain.swift              biometric-protected token storage
    Endpoints/
      AuthEndpoints.swift       register, login, refresh, logout
      LoyaltyEndpoints.swift    balance, history, stamp, redeem
      CustomerEndpoints.swift   me, updateMe, deleteMe

  Domain/
    Auth/
      AuthModels.swift          TokenPair, CustomerProfile
      AuthService.swift         network calls + Keychain persistence
      AuthStore.swift           @Observable @MainActor — auth state machine
    Loyalty/
      LoyaltyModels.swift       LoyaltyBalance, LoyaltyEvent
      LoyaltyService.swift      network calls
      LoyaltyStore.swift        @Observable @MainActor — loyalty state

  Views/
    Root/RootView.swift         auth gate — switches on AuthStore.state
    Auth/
      LoginView.swift
      RegisterView.swift
    Main/MainTabView.swift      Steeps / History / Profile tabs
    Loyalty/
      BalanceView.swift         steep passport — progress ring, stamp, redeem
      HistoryView.swift         loyalty event log
    Profile/ProfileView.swift

  Components/
    SteepProgressView.swift     9-dot progress ring
    PrimaryButton.swift         full-width button with loading state
    CelebrationOverlay.swift    post-stamp animation
```

---

## Security

- **HMAC-SHA256** — every request signed with `METHOD\nPATH\nTIMESTAMP\nNONCE\nBODY_HASH`
- **UUID nonce** per request — replay prevention enforced server-side via Redis
- **Biometric Keychain** — access and refresh tokens require Face ID / Touch ID
- **Certificate pinning** — `PinningDelegate` placeholder in `APIClient.swift`; add production cert hash before shipping
- **HMAC key injection** — never in source, injected at build time via `Secrets.xcconfig`
- **Automatic token refresh** — 401 triggers one silent refresh attempt before surfacing the error

---

## Certificate pinning (before production)

1. Export the Railway server certificate: `openssl s_client -connect your-api.railway.app:443 | openssl x509 -pubkey -noout | openssl pkey -pubin -outform DER | openssl dgst -sha256 -binary | base64`
2. Add the hash to `PinningDelegate` in `APIClient.swift`
3. Bundle the `.cer` file in the Xcode project
