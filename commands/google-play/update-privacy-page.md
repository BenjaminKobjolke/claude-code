---
description: Update an app's privacy policy web page (e.g. the app-landing-page framework's privacy-policy-app page) so it matches the Google Play Data safety CSV answers
---

# Google Play: Update Privacy Policy Page From Data Safety CSV

Google requires the privacy policy to match the Data safety form. This command rewrites the
app's privacy policy page so it discloses exactly what the CSV declares.

Run this in the **app project** (the Android / Flutter repo). The page itself usually lives in
another repo; its path comes from the config.

## Step 1: Load or create the project config

Same file as `/google-play:check-data-safety`: `.google-play.json` at the project root.

```json
{
  "data_safety_csv": "docs/data_safety_export.csv",
  "privacy_page_source": "D:/wamp64/www/app-landing-page/sites/<site>/lang/privacy-policy-app/en.json",
  "privacy_page_url": "https://example.com/<site>/privacy-policy-app"
}
```

- `data_safety_csv`: if missing, look in `docs/` for the Data safety export (header starts
  with `Question ID (machine readable)`), otherwise ask the user.
- `privacy_page_source`: the file that holds the page text. If missing, ask the user where
  the privacy policy page is. For the app-landing-page framework it is
  `<landing-page repo>/sites/<site>/lang/privacy-policy-app/en.json`, rendered by
  `templates/default/pages/privacy-policy-app.twig` at `/<site>/privacy-policy-app`.
- `privacy_page_url`: the live URL. Ask if missing; it is also the URL for Play Console's
  Privacy Policy field.
- Save every answer back into the config. Make sure `.google-play.json` is in the project's
  `.gitignore`; add the line if missing. Never commit the config.

## Step 2: Check the CSV first

If `/google-play:check-data-safety` has not run in this session, tell the user the page will
copy whatever the CSV says, and ask whether to run that check first. A page that matches a
wrong form is still wrong.

## Step 3: Turn the CSV into a disclosure list

Read the CSV with a real CSV parser (UTF-8 with BOM). An option is selected when
`Response value` is `true`. Build, per declared data type:

- data type (human label from the last column),
- collected and/or shared,
- purposes (collection and sharing),
- required or optional, ephemeral or not,
- which SDK or feature causes it (from the app code: dependencies, manifest, network calls).

Also take: encrypted in transit, deletion request option and URL, account creation methods.

## Step 4: Update the page

Read the page source in full first. Keep its language, tone, structure, contact details and
links; change only what the disclosure list requires.

The page must state, consistent with the CSV:

1. What is collected, by whom (us vs. a named SDK such as Google AdMob), and why.
2. What is shared and with whom.
3. What stays on the device only (and drop any absolute claim the CSV contradicts, e.g. "we do
   not collect or transmit any data" in an app with ads).
4. Services the user connects themselves (cloud storage, own API endpoints): data goes
   directly between the device and that provider, under its policy.
5. Payments, if the app uses Play Billing: handled by Google Play, no payment details reach us.
6. Encryption in transit, and how users can request deletion (or that no account data exists).
7. A link to each third-party SDK's own privacy policy / ad settings where it applies.

**app-landing-page framework** (`.../lang/privacy-policy-app/en.json`):

- Shape: `{"privacy_app": {"title", "intro", "sections": [{"title", "content", "links":
  [{"url", "label"}], "content_after", "links_after", "subsections": [{"title", "content"}]}]}}`.
- Numbered section titles (`"1. ..."`); renumber when you add or remove a section.
- `content` is plain text with `\n` line breaks (rendered through `nl2br`), no HTML.
- Edit with a UTF-8 aware tool and validate the JSON afterwards.
- The page is English only unless other locale files sit next to `en.json`. If they do, the
  changed keys must be removed from those locales and re-translated with the site's
  translator tool (see that repo's CLAUDE.md "Translations").

Other page types (plain HTML, CMS export): edit the text in the same spirit, keep the markup.

## Step 5: Verify

- Validate the edited file (JSON parse, or HTML well-formed).
- If a local URL exists (app-landing-page: `http://localhost/<clone>/<site>/privacy-policy-app`),
  fetch it and check it returns 200 and shows the new section titles.
- Compare once more: every data type declared in the CSV is mentioned on the page, and the
  page claims nothing the CSV does not declare.

## Step 6: Report

Tell the user, short:

- which sections changed and why (one line each),
- the file path that changed,
- what still has to happen: commit in the page's repo (app-landing-page: commit inside the
  `sites/` submodule, then bump the pointer), deploy, and check the live `privacy_page_url`.

Do not commit or deploy unless the user asks.
