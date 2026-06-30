---
name: dejoule-authentication
description: DeJoule/JouleTRACK authentication best-practice guide. Use when users ask about login, JWT/session design, OTP/MFA, reCAPTCHA risk fallback, cookies, token refresh/logout, service tokens, on-prem auth, or secure frontend auth handling in jt-api-v2 and JouleTRACK.
---

# DeJoule Authentication

**Scope:** `jt-api-v2`, Angular `JouleTRACK`, on-prem handoff, service-to-service auth.
**Goal:** Authenticate users and services safely, keep sessions revocable, and hand a trustworthy `_userMeta` to RBAC.

Authentication answers "who is this?" RBAC answers "what can this authenticated principal do?"

---

## Current DeJoule Auth Map

| Area | Files |
|---|---|
| Login | `jt-api-v2/api/controllers/auth/login.js` |
| JWT issue/verify | `api/services/auth/auth.private.js`, `auth.service.js`, `auth.public.js` |
| Refresh token/site switch | `api/controllers/auth/refresh-token.js` |
| Logout/revocation | `api/controllers/auth/logout.js`, `api/services/cache/cache.service.js` |
| Protected request policy | `api/policies/isAuthorized.js` |
| Cookie handling | `api/utils/cookieHelper.js`, `config/sockets.js` |
| OTP | `api/controllers/otp/send-otp.js`, `api/services/otp/*` |
| Frontend login/refresh | `JouleTRACK/src/app/sharedServices/auth.service.ts`, `effects/userEffects.ts`, `effects/tokenEffects.ts` |
| Frontend bearer header | `JouleTRACK/src/app/sharedServices/auth.interceptor.ts` |
| Site policy/bootstrap after auth | `siteBootstrap`, `dejoule-rbac` skill |

Current flow:

1. Angular creates a browser fingerprint secret and sends it in `Authorization` during login.
2. Login validates password or OTP.
3. In production, password login uses reCAPTCHA Enterprise risk scoring; failure triggers OTP email flow.
4. Backend selects a default/restored site the user can access.
5. Backend issues JWT containing `id`, `_role`, `_site`, unit prefs, password timestamp, internal-user flag, `auth_key`, and `_h_`.
6. Backend sets `authToken` cookie and stores current token in Redis by `auth:<userId>:<siteId>`.
7. `isAuthorized` accepts Bearer header first, then cookie fallback, verifies JWT, checks Redis token validity, attaches `_userMeta`, and verifies site access.
8. Refresh token reissues JWT for a site switch if browser secret matches and user has access.
9. Logout deletes all cached tokens for the user.

---

## Best-Practice Baseline

Use OWASP Authentication and Session Management Cheat Sheets plus NIST SP 800-63B as the baseline:

- Every auth endpoint must use HTTPS.
- Passwords are never logged, returned, stored, or compared in plaintext.
- Sessions must be revocable server-side, even if JWTs are self-contained.
- Cookies carrying auth tokens must be `HttpOnly`, `Secure` in HTTPS/prod, bounded by `SameSite`, and scoped carefully.
- Login, OTP, password reset, and token refresh need rate limits and abuse detection.
- Auth failures should not reveal whether user id, password, OTP, or site access was the differentiator.
- MFA/OTP codes must be short-lived, one-time-use, rate-limited, and stored hashed if persisted.
- Session renewal should rotate tokens and preserve revocation semantics.
- Reauthenticate for high-risk actions such as role changes, command writes, credential changes, and destructive configuration.

---

## DeJoule Recommended Auth Architecture

### Browser User Sessions

Recommended model:

```text
Frontend
  -> POST /m2/auth/v2/login
  <- HttpOnly authToken cookie + token response during transition
  -> API requests with Authorization Bearer or cookie

Backend
  -> verify JWT signature and exp
  -> verify token is current/valid in Redis
  -> attach _userMeta
  -> RBAC/site policies
```

Target direction:
- Prefer `HttpOnly` cookie for browser session transport.
- Keep Bearer token support while Angular and legacy clients need it.
- Keep Redis token validation so logout/password reset/role emergencies can revoke sessions.
- Store a token id/session id (`jti`/`sid`) in Redis instead of the full JWT when practical.
- Shorten access token lifetime and use explicit refresh/session renewal if UX requires long sessions.

### Service-To-Service

Do not reuse user JWTs for machine calls. Use one of:
- short-lived service JWT from `issue-service-token`
- mTLS/internal network plus signed token
- per-service credential in secret manager

Service tokens should contain:

```json
{
  "sub": "service:cloud-to-onprem-sync",
  "aud": "jt-api-v2",
  "scope": ["devconfig:read", "ontology:sync"],
  "exp": 1234567890,
  "jti": "unique-token-id"
}
```

Avoid hardcoded query-token secrets in new code. Move legacy static secrets to environment/secret manager and rotate them.

---

## Login Guidelines

Do:
- Normalize user id/email before lookup.
- Use constant-style generic login failure messages.
- Require password or verified OTP; never accept empty password.
- Use risk-based challenge: reCAPTCHA score or suspicious login -> OTP/MFA.
- Rate-limit by user id, IP, and device/fingerprint.
- Record auth audit events: success/failure, user id hash/email, site, risk score bucket, IP, user agent, transaction id.
- Never log passwords, OTPs, JWTs, auth headers, or cookies.

Do not:
- Expose "user not found" vs "bad password" to public clients.
- Rely on browser fingerprint as proof of identity.
- Put secrets or auth keys in query strings.
- Keep JWT signing secret hardcoded in source.

Current code note: `auth.private.js` has a hardcoded JWT secret. Best practice is to move this to `JWT_SECRET` or key management, support key rotation with `kid`, and reject startup if no strong secret is configured.

---

## JWT And Session Guidelines

Recommended JWT claims:

```json
{
  "iss": "dejoule-auth",
  "aud": "jouletrack",
  "sub": "user@example.com",
  "sid": "session-id",
  "jti": "token-id",
  "_site": "suh-hyd",
  "_role": "operator",
  "iat": 1234567890,
  "exp": 1234571490
}
```

Rules:
- Keep JWT payload minimal; avoid long-lived mutable data where possible.
- Use `exp`, `iat`, `iss`, `aud`, and `jti`/`sid`.
- Keep `_site` and `_role` only if downstream code needs them, but verify current access server-side.
- Validate algorithm explicitly if changing JWT library usage.
- Store revocation/session validity in Redis keyed by `sid`/`jti`.
- Rotate token on login, refresh, site switch, privilege change, and password change.
- Invalidate all sessions on password reset or suspicious account activity.

Current code note: Redis validation stores one current token per `auth:<userId>:<siteId>` and logout deletes all user tokens. That is good for revocation, but compare the presented token to the stored token; do not treat any cached token as enough. If Redis is unavailable, fail closed in production for high-risk routes.

---

## Cookie Guidelines

Current helper sets:
- `httpOnly: true`
- `secure` for production/HTTPS
- `sameSite: 'None'` when secure, otherwise `Lax`
- domain scoping and duplicate-cookie clearing

Keep:
- `HttpOnly`
- `Secure` in HTTPS/prod
- `Path=/`
- tight domain scoping
- duplicate-cookie clearing

Improve when possible:
- Set cookie lifetime no longer than session/token lifetime.
- Prefer `SameSite=Lax` when same-site app/API layout allows it.
- Use `SameSite=None; Secure` only when cross-site browser requests require it.
- Add CSRF protection for cookie-authenticated unsafe methods if cookies are used without a custom header/token pattern.

---

## OTP / MFA Guidelines

Current OTP flow:
- 6-digit random OTP
- bcrypt hash persisted
- 10-minute expiry
- one-time verified flag
- plain OTP cached briefly for email/resend

Do:
- Rate-limit send and verify attempts per user/IP/purpose.
- Enforce max failed attempts per OTP and invalidate after threshold.
- Delete plain OTP from cache after send if resend does not require retrieving the same value; generate a new OTP on resend where feasible.
- Use generic error text in public responses.
- Keep OTP purpose-specific (`login`, `password-reset`, etc.).
- Log delivery result without logging OTP value.
- Prefer authenticator app/WebAuthn/passkey for stronger MFA where feasible; email OTP is better than password-only but weaker than phishing-resistant MFA.

Do not:
- Store plain OTP beyond delivery need.
- Let OTP bypass user/site status checks.
- Let OTP remain valid after password reset, login success, or account lock.

---

## Refresh / Site Switch Guidelines

Current refresh uses `_h_` browser secret and requested `siteId`.

Do:
- Verify user still has site access for the requested site.
- Rotate JWT on every site switch.
- Update Redis session validity.
- Preserve redirect only after validating site existence and user access.
- Treat browser fingerprint as a continuity hint, not strong authentication.

Prefer:
- server-issued refresh/session id stored in HttpOnly cookie over localStorage-derived fingerprint secret
- `sid`-based session record with allowed sites and revocation state

---

## Frontend Guidelines

Current Angular stores base64 JWT in localStorage and also uses `withCredentials`.

Do:
- Move toward HttpOnly cookie-only session handling for browser auth.
- If Bearer token in localStorage remains during transition, minimize lifetime and never store extra secrets.
- Interceptor must not attach auth headers to third-party URLs.
- Treat decoded JWT as display/convenience only; never as authorization source.
- On logout, clear NgRx state and localStorage token/fingerprint/session markers where safe.
- Do not log token, decoded full token, auth headers, or OTP.

Do not:
- Use `isAuthenticated()` based only on fingerprint/localStorage keys as actual auth proof.
- Gate security in Angular only.
- Store password, OTP, refresh token, or auth key in localStorage.

---

## High-Risk Reauthentication

Require fresh auth or step-up challenge for:
- role/permission changes
- assigning/removing site access
- command writes or automation deployment
- configuration publish/delete
- password/email/auth-key change
- service token generation
- exporting sensitive site/user data

Pattern:

```text
User initiates high-risk action
  -> backend returns STEP_UP_REQUIRED
  -> frontend prompts OTP/MFA
  -> backend verifies MFA and issues short-lived step-up grant
  -> action must be completed before grant expiry
```

Keep step-up grant short-lived, action-scoped, and server-side revocable.

---

## Password And Reset Guidelines

Do:
- Hash passwords with bcrypt/argon2 using strong parameters.
- Require current password or step-up for password changes.
- Invalidate all sessions after password reset/change.
- Store `passwordUpdatedAt` and reject tokens older than this timestamp.
- Use short-lived, single-use reset tokens.
- Rate-limit forgot-password and reset attempts.

Do not:
- Put reset tokens in logs.
- Reveal whether a user id exists in forgot-password responses.
- Allow old JWTs after password reset.

---

## API Implementation Checklist

- [ ] Auth endpoint has rate limiting.
- [ ] Secrets come from env/secret manager, not source.
- [ ] JWT has `exp`; ideally `iss`, `aud`, `sid`, `jti`.
- [ ] Redis/session validation is fail-closed for production high-risk routes.
- [ ] Login failure message is generic.
- [ ] OTP is short-lived, one-time-use, hashed, and attempt-limited.
- [ ] Cookie is `HttpOnly`, `Secure` in prod, correctly scoped, and SameSite reviewed.
- [ ] Logout revokes server-side session/token state.
- [ ] Password reset invalidates sessions.
- [ ] Auth logs are structured and scrubbed.
- [ ] RBAC receives `_userMeta` only from backend auth policy.

---

## Review Smells

- JWT secret is hardcoded or weak.
- Auth token appears in query string.
- New endpoint bypasses `isAuthorized` without a service/webhook auth policy.
- Redis token check returns allow on cache miss in production for sensitive routes.
- OTP has no attempt counter or rate limit.
- Login reveals "user not found" vs "wrong password".
- Frontend localStorage token is treated as proof of auth.
- Cookie lacks `HttpOnly`/`Secure` where applicable.
- Logout only clears frontend state and does not revoke server-side session.
- Password reset does not invalidate existing sessions.
