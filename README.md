# whisked-ios

iOS client for **Whisked** — a matcha pickup app. Customers browse the menu, place an order, and pick it up at the bar. The pickup code (e.g. `W-4829`) is the artifact staff use to hand off the drink.

The app is a Whisked-branded customer surface for the [box-fraise-platform](https://github.com/q04-oss/box-fraise-platform) backend. There is no separate Whisked-only backend — `WHISKED_API_BASE_URL` points at a box-fraise deployment.

Built with **SwiftUI**, **Swift Concurrency**, **iOS 17 minimum**. Every API request is HMAC-SHA256 signed; tokens are stored in the biometric Keychain.

---

## MVP scope

The four flows the v1 app supports:

1. **Sign in** — email magic link via box-fraise-platform's `/api/auth/magic-link`. The link redirects to `whisked://auth?token=…`, which `WhiskedApp.swift::onOpenURL` captures and exchanges.
2. **Browse menu** — list of drinks with name, description, and price. Tap `+` to add to cart. (Currently stubbed; real fetch lands when `GET /api/whisked/menu` ships server-side.)
3. **Place order** — review cart, see total, hit "Place order". Server returns an order with status `pending`. (Currently stubbed; real call goes to `POST /api/whisked/orders`.)
4. **Pickup** — Order tab shows live status (`pending → preparing → ready → collected`). Once `ready`, the pickup code displays in 64-pt rounded text. Status refreshes on app foreground and on `notification_type = "order_update"` silent push.

What's deliberately **not** in v1: payments, order history, loyalty, location/map, popups, in-app menu management.

---

## Xcode setup (Mac required)

The Xcode project is created on a Mac:

1. Open Xcode → File → New → Project → iOS App
2. Name `Whisked`, Bundle ID `ca.whisked.app`, Language Swift, Interface SwiftUI, minimum iOS 17
3. Save into this repo directory
4. Delete the generated placeholders (`ContentView.swift`, `WhiskedApp.swift`)
5. File → Add Files → select the `Whisked/` folder

### Secrets

```bash
cp Secrets.xcconfig.example Secrets.xcconfig
# Fill in your values
```

```
WHISKED_API_BASE_URL = https://<your-box-fraise>.up.railway.app
WHISKED_HMAC_KEY     = <FRAISE_HMAC_SHARED_KEY from your box-fraise deployment>
WHISKED_BUSINESS_ID  = <the business id this Whisked app instance is built for>
```

Wire `Secrets.xcconfig` into the project: Project → Info → Configurations → set Debug + Release to `Secrets`.

Add the variable bindings to `Info.plist`:

```xml
<key>WHISKED_API_BASE_URL</key>
<string>$(WHISKED_API_BASE_URL)</string>
<key>WHISKED_HMAC_KEY</key>
<string>$(WHISKED_HMAC_KEY)</string>
<key>WHISKED_BUSINESS_ID</key>
<string>$(WHISKED_BUSINESS_ID)</string>
```

---

## File layout

```
Whisked/
├── WhiskedApp.swift                @main — three @Observable stores, deep-link handler
├── AppDelegate.swift               push token registration, silent-push routing
├── Config.swift                    Info.plist → typed runtime config
│
├── Networking/
│   ├── APIClient.swift             actor — HMAC-SHA256 signing, JWT, token refresh
│   ├── APIError.swift
│   ├── Keychain.swift              biometric-protected storage
│   └── Endpoints/
│       ├── AuthEndpoints.swift     /api/auth/{login,register,logout,magic-link}
│       ├── CustomerEndpoints.swift /api/auth/{me,display-name,push-token}
│       └── Orders.swift            /api/whisked/{menu,orders,orders/:id,…}
│
├── Domain/
│   ├── Auth/                       AuthModels, AuthService, AuthStore (state machine)
│   └── Orders/                     OrderModels, OrderStore (cart + currentOrder)
│
├── Components/
│   ├── PrimaryButton.swift         dark-fill CTA, max one per surface
│   └── CelebrationOverlay.swift    bell-mark + haptic
│
├── Resources/
│   └── WhiskedColors.swift         brand palette
│
└── Views/
    ├── Root/RootView.swift         auth gate
    ├── Auth/AuthView.swift         magic-link request + sent screens
    ├── Main/MainTabView.swift      Menu / Cart / Order / Profile tabs
    ├── Menu/MenuView.swift
    ├── Cart/CartView.swift
    ├── Orders/OrderStatusView.swift
    └── Profile/ProfileView.swift
```

---

## Security

- **HMAC-SHA256** on every request — `METHOD\nPATH\nTIMESTAMP\nNONCE\nBODY_SHA256_HEX` signed with `WHISKED_HMAC_KEY`. Server-side replay protection via Redis nonce dedup (see box-fraise-platform `server/src/http/middleware/hmac.rs`).
- **UUID nonce** per request.
- **Biometric Keychain** — JWT access token requires Face ID / Touch ID to read.
- **Certificate pinning** — `PinningDelegate` in `APIClient.swift` is currently a stub. Wire the production cert hash before shipping (see TODO in source).
- **HMAC key** never in source — injected at build time via `Secrets.xcconfig`.

---

## Backend dependency

This app expects the following routes on box-fraise-platform:

- `POST /api/auth/magic-link` — request a sign-in link
- `POST /api/auth/magic-link/verify` — exchange a token for a JWT
- `GET /api/auth/me` — current customer profile
- `PATCH /api/auth/push-token` — register the APNs token
- `GET /api/whisked/menu` — drink catalogue *(not yet implemented)*
- `POST /api/whisked/orders` — place an order *(not yet implemented)*
- `GET /api/whisked/orders/:id` — order status + pickup code *(not yet implemented)*
- `GET /api/whisked/orders/:id/pickup-code` — explicit pickup-code endpoint *(not yet implemented)*

The MVP runs against the menu / orders endpoints in **stub mode** until the server side lands — `OrderStore` returns hardcoded placeholders so the full UX renders end-to-end.
