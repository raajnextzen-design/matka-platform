# Matka Platform Android Client

Separate Flutter/Dart Android client for the existing FastAPI service. It provides onboarding, registration/login, market search and details, schedules, published and historical results, favourites, and profile/logout. All data is informational. Betting, deposits, and payouts are not implemented.

## Tool availability

The development container used for this project does not have Flutter, Dart, `adb`, or an Android SDK installed. It does have Java and Gradle, but those alone cannot build a Flutter APK. No Flutter or Android tools need to be installed on your work laptop if you use the hosted workflow below.

## Local development

Install Flutter from the official Flutter instructions on a development machine and confirm Android support with `flutter doctor -v`. The Flutter SDK and Android SDK are needed to run the Android app locally.

Start the FastAPI backend using the instructions in the repository root README. In the Android emulator, the host machine's loopback address is `10.0.2.2`; use a reachable LAN IP for a physical device.

From `mobile/`, generate the standard Android runner once without replacing the Dart source files, then resolve packages and run:

```bash
flutter create --platforms=android --project-name matka_platform_mobile --org com.matkaplatform /tmp/matka-platform-mobile-scaffold
cp -a /tmp/matka-platform-mobile-scaffold/android ./android
flutter pub get
flutter analyze
flutter test
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

`API_BASE_URL` is a compile-time setting and has no production URL default. For a device, substitute a development API host that the device can reach. Do not use an emulator-only address in a release build. Commit the generated `pubspec.lock` after package resolution to keep future dependency versions reproducible.

## Zero-cost hosted APK build

The repository root contains `.github/workflows/mobile-android.yml`. After pushing the project to GitHub, open **Actions → Mobile Android APK → Run workflow**, enter the HTTPS API base URL for that build, and start it. The hosted runner installs Flutter, generates the Android runner in a temporary directory, runs `flutter analyze` and all widget tests, builds a release APK with that URL, and uploads `app-release.apk` as a seven-day workflow artifact. No credentials, production signing keys, paid APIs, or local Flutter installation are required for this development APK; it is not configured for Play Store release signing.

GitHub Actions hosted-runner usage is free for public repositories; private repositories have plan-dependent free-minute quotas and may incur charges if those quotas are exceeded. Check the repository's current Actions usage/plan before dispatching. The workflow uses standard hosted Ubuntu/Java/Flutter tooling and does not call a paid build service.

## Authentication and API behavior

- API paths and JSON fields match the existing backend routes and Pydantic schemas; see the API contract map below.
- Set the environment-specific URL only with `--dart-define=API_BASE_URL=...`. For a hosted APK workflow, provide an HTTPS endpoint. The app does not embed any actual production URL.
- Access tokens are stored with `flutter_secure_storage` and removed on logout, local expiry, or a backend 401. Passwords are not persisted.
- Public market/result calls and authenticated profile/favourite calls show loading, empty, offline, and retryable error states.
- Android secure storage reduces token exposure compared with ordinary preferences, but does not replace device security or HTTPS. Use a reviewed signing key and secure distribution process before public release.

## Existing backend API contract

- `POST /api/auth/register`: `{ "email", "password" }`; registration is followed by login.
- `POST /api/auth/login`: `{ "email", "password" }`; response includes `access_token` and `token_type`.
- `GET /api/users/me`: profile fields `id`, `email`, `role`, `created_at`.
- `GET /api/markets`, `GET /api/markets/{market_id}`, `GET /api/markets/{market_id}/schedules`.
- Schedule fields: `id`, `market_id`, `weekday` (Monday `0` through Sunday `6`), `opens_at`, `closes_at`, `is_active`.
- `GET /api/results?limit=100` and `GET /api/results/history?before=YYYY-MM-DD&limit=100`; both support `market_id`.
- Result fields: `id`, `market_id`, `result_date`, `value`, `published_at`.
- `GET /api/users/me/favourites`, `PUT /api/users/me/favourites/{market_id}`, and `DELETE /api/users/me/favourites/{market_id}`.

Market search is performed locally on the markets returned by the backend because no search endpoint exists. The API has no logout/revocation route, so logout clears the token on-device; server-side token revocation is not available in this MVP.