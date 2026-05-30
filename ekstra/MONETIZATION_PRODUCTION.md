# Monetization Production Checklist

## Store Product
- Product id: `ekstra_pro_lifetime`
- Type: non-consumable, one-time purchase.
- App Store Connect and Google Play Console product ids must match exactly.
- The product must be approved and available in the target countries before release.

## Purchase Validation
- Current app flow uses `in_app_purchase` and local entitlement storage.
- Production release should add server-side receipt validation before treating a purchase as permanently trusted.
- Recommended future flow:
  1. Client sends purchase token/receipt to backend.
  2. Backend validates with Apple/Google.
  3. Backend returns signed entitlement state.
  4. App stores the signed entitlement locally for offline use.

## AdMob
- Rewarded ads are user-initiated only.
- Do not add app-open ads, random interstitial ads, or forced ads after saving entries.
- Replace test ad units using dart defines:
  - `ADMOB_ANDROID_REWARDED_ID`
  - `ADMOB_IOS_REWARDED_ID`

## Entitlement Rules
- Free users can record overtime, use salary estimate, and see basic reports.
- Free users may unlock exports and advanced analysis with rewarded ads.
- Pro users bypass ads and use all gated features.
- Debug Pro switch must remain debug-only.
