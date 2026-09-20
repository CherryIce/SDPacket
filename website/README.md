# Moving Box website

Dependency-free static website for 搬家箱 / Moving Box.

## Files

- `index.html`: bilingual product website
- `privacy.html`: bilingual privacy policy
- `styles.css`: shared responsive and print styles
- `site.js`: language preference, language-aware links, and mobile navigation
- `assets/app-icon.png`: web copy of the current app icon
- `assets/home-screen.png`: optimized product screenshot
- `assets/project-screen.png`: optimized project-detail screenshot

## Local preview

Serve this directory with any static HTTP server and open `index.html`. Opening
the HTML files directly also works, but an HTTP preview more closely matches
production hosting.

## Required before publishing

1. Replace every Chinese and English operator/contact placeholder in
   `privacy.html` with confirmed public details.
2. Use the final public privacy URL and support email in release builds through
   `PRIVACY_POLICY_URL` and `SUPPORT_EMAIL`.
3. Recheck the policy whenever app permissions, SDKs, storage, export, speech,
   sync, account, analytics, or advertising behavior changes.
4. Have the final policy reviewed for the countries and regions where the app
   will be distributed. This repository draft is product-specific compliance
   content, not legal advice.
