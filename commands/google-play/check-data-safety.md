---
description: Check an app's Google Play Data safety CSV export against what the app really collects (SDKs, permissions, network calls), report every mismatch and, on approval, write a corrected CSV for re-import
---

# Google Play: Check Data Safety CSV

Google requires the Data safety form to match the app's real behaviour **and** its privacy
policy. A wrong form (typical: "no data collected" in an app with AdMob) can get an update
rejected or the app removed.

Run this in the **app project** (the Android / Flutter repo), not in the website repo.

## Step 1: Load or create the project config

The config is `.google-play.json` at the project root. Both `google-play` commands share it:

```json
{
  "data_safety_csv": "docs/data_safety_export.csv",
  "privacy_page_source": "D:/wamp64/www/app-landing-page/sites/<site>/lang/privacy-policy-app/en.json",
  "privacy_page_url": "https://example.com/<site>/privacy-policy-app"
}
```

- Paths inside the project are relative to the project root; paths outside it are absolute.
- If the file exists, read it and use `data_safety_csv`.
- If it does not exist, create it with only the keys you know so far.
- Make sure `.google-play.json` is listed in the project's `.gitignore`. Add the line if it is
  missing (create `.gitignore` if the project has none). Never commit the config.

## Step 2: Find the CSV

1. Use `data_safety_csv` from the config if the file exists.
2. Otherwise look in the project's `docs/` folder for a `*.csv` that has the header
   `Question ID (machine readable),Response ID (machine readable),Response value,...`
   (prefer names containing `data_safety`).
3. Otherwise ask the user where the export is. Tell them how to make one if they have none:
   Play Console → the app → **App content** → **Data safety** → **Export to CSV**.

Store the found path in `data_safety_csv`.

## Step 3: Read the CSV

Columns: `Question ID`, `Response ID`, `Response value`, `Answer requirement`,
`Human-friendly question label`. Read it with a real CSV parser (labels contain commas and
quotes), file encoding UTF-8 (the export may or may not start with a BOM - keep whatever
the original has).

- A row with an empty `Response ID` is a direct question; `Response value` is the answer
  (`true` / `false` / text / URL).
- `MULTIPLE_CHOICE` / `SINGLE_CHOICE` rows: the option is **selected** when `Response value`
  is `true`; empty means not selected.
- Data types: `PSL_DATA_TYPES_<GROUP>` rows, `Response ID` = the type (`PSL_DEVICE_ID`,
  `PSL_APPROX_LOCATION`, `PSL_USER_INTERACTION`, `PSL_CRASH_LOGS`, ...).
- Per-type handling: `PSL_DATA_USAGE_RESPONSES:<TYPE>:<QUESTION>` rows — collected/shared,
  ephemeral, required/optional, collection purposes, sharing purposes.
- Key top-level questions: `PSL_DATA_COLLECTION_COLLECTS_PERSONAL_DATA`,
  `PSL_DATA_COLLECTION_ENCRYPTED_IN_TRANSIT`, `PSL_SUPPORT_DATA_DELETION_BY_USER`,
  `PSL_DATA_DELETION_URL`, `PSL_SUPPORTED_ACCOUNT_CREATION_METHODS`.

Summarise the current answers in a few lines (what is declared collected / shared and why).

## Step 4: Find what the app really does

Search the project read-only. Look at:

1. **Dependencies** — `pubspec.yaml`, `android/app/build.gradle(.kts)`, `app/build.gradle(.kts)`,
   `package.json`. Note every SDK that sends data off the device: ads (`google_mobile_ads`,
   `play-services-ads`, wrappers such as `easy_admob_ads_flutter`), Firebase (Analytics,
   Crashlytics, Messaging), Sentry, other analytics, Play Billing, sign-in SDKs.
2. **Manifest permissions** — `AndroidManifest.xml` (location, camera, microphone, contacts,
   storage, `BILLING`, `AD_ID`, `INTERNET`).
3. **Network calls in the app's own code** — HTTP clients and hard-coded endpoints. Separate:
   - calls to **our own servers** (data we collect),
   - calls to **services the user connects** (Google Drive, Dropbox, OneDrive, a user-entered
     API endpoint),
   - calls that only fetch content (no user data leaves the device).
4. **Accounts** — does the app create accounts or log in to our backend?
5. **Local / path dependencies** — follow `path:` / `git:` packages (our own client libraries)
   and look for base URLs there and in the app's config class. Our own backend often hides
   behind them (accounts, AI chat, feedback/support, purchase verification). Do not stop at
   the ad SDK.

Skip generated folders (`build/`, `.dart_tool/`, `graphify-out/`, `node_modules/`).

## Step 5: Work out what the form must say

For each SDK, look up its **official Play data disclosure page** instead of guessing, e.g.:

- Google Mobile Ads (AdMob): https://developers.google.com/admob/android/privacy/play-data-disclosure
- Firebase: https://firebase.google.com/docs/android/play-data-disclosure
- Other SDKs: search "<sdk name> Google Play data safety disclosure".

As a sanity baseline, AdMob alone means the form can **not** say "no data collected": it
collects approximate location (IP), app interactions, diagnostics / crash logs and device or
other IDs (advertising ID), used for advertising, analytics and fraud prevention, encrypted in
transit.

Rules to apply:

- Data an SDK in the app sends off the device counts as collected by the app.
- Data that never leaves the device is not collected.
- Data processed only ephemerally may be marked ephemeral.
- An app that lets users create an account must declare the account creation method, offer
  account deletion **inside the app** and give a public **account deletion URL** (a web page
  that works without the app). Check both: an API endpoint alone is not enough. Report a
  missing in-app path or web page as a blocking item.
- Data the app sends to a service the **user** chose (their own cloud account, their own API
  endpoint) is a judgement call. Do not decide it silently: list it and ask the user.

## Step 6: Report

Show the user a short table: **Item | Form says | App does | Fix**. Only list mismatches
and items you could not decide. If everything matches, say so in one line and stop.

Then ask: **Should I write a corrected CSV?** Wait for the answer.

## Step 7: Write the corrected CSV (only after approval)

1. Keep the original: copy it to `<name>.orig.csv` next to it (only if that copy does not exist
   yet).
2. Edit the CSV in place. Address rows by the pair (`Question ID`, `Response ID`) and stop
   if a pair does not exist; never add rows. Collected + shared = select both
   `PSL_DATA_USAGE_ONLY_COLLECTED` and `PSL_DATA_USAGE_ONLY_SHARED`. Ephemeral is a direct
   `true`/`false` answer. Leave a URL empty rather than enter a page that does not exist yet.
   Then: set `Response value` to `true` for each newly selected option, fill
   the per-type usage rows for every newly declared type (collected/shared, ephemeral,
   required/optional, purposes), and fix the top-level answers. Keep every row, the column
   order, the header, the BOM (or its absence), the line endings and the presence or
   absence of a final newline, so Play Console accepts the import.
3. Re-read the written file with the CSV parser and list the changed rows.
4. Tell the user how to apply it: Play Console → **App content** → **Data safety** →
   **Import from CSV** → review → **Save** → send for review.
5. The privacy policy must say the same thing. Suggest running
   `/google-play:update-privacy-page` next.
