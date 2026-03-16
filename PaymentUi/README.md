# Traks Payment UI

This directory contains the React/Vite payment frontend used during the Traks upgrade flow. It is opened from the Flutter app when a user selects the premium or reporter tier.

## What It Does

- reads `userId`, `return_url`, and `tier` from the query string
- launches Interswitch Webpay
- attempts to notify the backend after successful payment
- redirects the user back into the app through the provided return URL or the `traksapp://payment` deep link

## Local Development

```bash
cd TraksApp2026/PaymentUi
npm install
npm run dev
```

## Query Parameters

| Parameter | Purpose |
| --- | --- |
| `userId` | User being upgraded. |
| `return_url` | URL or custom scheme to redirect back to after checkout. |
| `tier` | Selected upgrade tier. Expected values: `premium` or `reporter`. |

## Relationship To The Flutter App

- The Flutter subscription screen builds the payment URL using `PAYMENT_UI_BASE_URL`.
- The payment UI is not a separate product; it is one step inside the Traks subscription flow.
- The expected redirect target in the mobile flow is `traksapp://payment`.

## Important Caveats

- The current implementation contains a hardcoded backend verification URL.
- The payment flow expects a verification endpoint that is not visible in the current FastAPI routes.
- Review the workspace-level `../../docs/known-gaps.md` for the latest mismatch list.
