# Whisked iOS — pre-merge security audit

Audit the staged changes against the following classes.
List every finding before touching anything. Surgical edits only.

## 1. Auth surface
- Magic link: tokens must be single-use (GETDEL on verify) and
  expiry-checked server-side. Never accept a token the app generated
  itself; the server issues and consumes them.
- JWT: stored in Keychain only — never UserDefaults, never in-memory
  across app restarts. Any JWT decoded client-side without server
  verification is a finding.
- Push token registration: only sent after successful authentication.
  A pending push token must not be flushed to an unauthenticated session.
- APNs: silent pushes must not trigger privileged actions without a
  subsequent server-side auth check.

## 2. Networking
- All requests to `api.fraise.box` must use HTTPS. Flag any HTTP URL.
- URLSession certificate handling: `didReceive challenge` must never
  return `.useCredential` unconditionally. Pinning or default validation only.
- API responses trusted without schema validation? Missing `guard let`
  or force unwraps on server-returned data are findings.
- Auth token must travel in the `Authorization: Bearer` header, never
  in URL query parameters or request body.
- Dorotka AI requests go to `whisked.fraise.box/api/dorotka/ask`. The
  `context` field must NOT be sent by the client — the server resolves
  context from the Host header. Flag any code that sends `context` in
  the request body.

## 3. Sensitive data storage
- JWT and push token in Keychain only — not UserDefaults, not NSCache,
  not URLCache response storage.
- Loyalty balance and steep count are not sensitive, but user email and
  display name must not appear in logs (`print`, `Logger`, `os_log`).
- No PII or tokens in crash reporter payloads or analytics events.

## 4. Input handling
- User input passed to the API without length validation? The server
  enforces 500-char limit on Dorotka queries and 4 KB body cap — the
  client should pre-validate to match.
- Magic link email field: validate format client-side before sending.
  Empty or malformed emails that reach the server waste a rate-limit slot.
- NFC tag data (sticker UUID) is passed directly to the server. The
  client must not transform or re-encode it — pass the raw UUID string.

## 5. Known pattern recurrence
Check for these specific patterns already found and patched in the
server — same bug class, Whisked iOS surface:

- **Client-controlled context**: any code that sends `context: "whisked"`
  or `context: "fraise"` to the Dorotka endpoint. Context is server-side
  only (derived from Host header). The field must be absent from the
  request body.
- **Fail-open on service unavailable**: if the loyalty or auth service
  returns an error, the app must not silently grant access or show a
  reward as available. Errors surface as `.unavailable` state, not success.
- **Rate limit slot leakage**: magic link requests are limited to one per
  email per 2 minutes server-side. Retrying on network error without
  user intent wastes the slot. Confirm retry logic is user-triggered only.
- **Push token flushed before auth**: `flushPushToken()` must only be
  called after a confirmed authenticated session. Any path that calls it
  from an `.unauthenticated` or `.awaitingMagicLink` state is a finding.
- **Business scope on loyalty**: loyalty endpoints include `business_id`
  in the path (`/api/businesses/{id}/loyalty/...`). The client must read
  `Config.businessID` — never hardcode an integer literal or accept it
  from a server response without validation against the known value.

List file, line, class, and recommended fix for each finding.
