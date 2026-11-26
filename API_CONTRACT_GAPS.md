# Store integration contract

The supplied handoff lists 43 requests, including admin and test operations. The collection has no saved response examples. A separately supplied login response established the token and customer-profile format. The Flutter client defines the 29 documented customer requests in `lib/core/network/customer_request.dart`. Both order methods send a top-level checkout return URL and a shipping address. The deployment supplies that URL.

## What is connected

The demo uses local fixtures. An anonymous GET on the supplied collection host returned a successful product list with 75 records, paginated in groups of ten. The sample included electronics and books. Staging displays the first page using product IDs, titles, brands and categories. The owner confirmed whole Bangladeshi taka for product prices and order totals. A live build does not populate inventory, authenticate from demo credentials or create orders from demo data. Adding a base URL alone does not activate an unverified feature.

The transport requires an HTTPS base URL, a matching endpoint-specific response adapter, and a secure session for token-protected requests. The request header is `token`. Paths retain the configured base prefix. Public requests omit credentials. HTTP redirects are rejected. Request bodies, passwords, OTPs and server error bodies are never logged. A matching authenticated 401 clears that session. No token-refresh or remote sign-out protocol is assumed.

## Evidence needed to activate each area

| Area | Evidence from the store or backend owner | App behavior until verified |
| --- | --- | --- |
| Environment and authentication | Identify the staging and production URLs. Supply sanitized signup, verify, resend and profile responses, accepted credential formats, token extraction, expiry, refresh/revocation policy and OTP rules. | Existing-customer sign-in and local sign-out are wired. Login validates the returned identity and stores the token in the secure vault. Registration, persistent profile restoration and profile changes await verification. |
| Catalogue and media | Capture both anonymous and authenticated product-list requests, detail by ID and slug, brand/category relationships, media URLs and allowed origins, page defaults and end-of-list rules. Supply approved production inventory and media origins. | Staging reads the first anonymous page. Local search covers those loaded products. Production awaits the approved store catalogue. |
| Product information | Verify sizes, shades, availability, ingredient order, instructions, claims and net units. Supply approved images and copy. | Unknown prices cannot be purchased. Unsupported product panels are omitted. |
| Offers, slides and reviews | Confirm Sale/Clearance membership, meaning of previous price, valid slide destinations, review identity and aggregate/rating semantics. | Demo offers are illustrative. No calculated live discounts or review claims. |
| Cart and wishlist | Verify option selection, quantity updates, deletion, wishlist mutations and guest-to-member merge rules. | Authenticated staging customers can add one simple product, read cart rows from data.results and page through the bag. |
| Addresses | Confirm saved-address CRUD, deletion, selection and ownership. The profile API describes basic address/city fields only. | Multiple saved addresses exist within the demo. |
| Order submission | Confirm shipping, tax and discount rules and a server-enforced key per checkout attempt. | Staging COD sends shipping_address and top-level redirect_url. HTTP 201 supplies the order ID, total_price and payment_status. tran_id can be null. No client total is sent. |
| Interrupted payment | SSLCommerz sandbox initiation supplies only gateway_url. Provide the production callback and authoritative payment status transitions. Return the order ID and transaction reference, and support lookup by the client-generated key after response loss. Provide exact duplicate/idempotency rules and a durable recovery design. | HTTP requests never follow redirects or automatically replay order creation. Ambiguous outcomes surface as unknown. No client callback declares payment successful. A local pending marker blocks uncertain COD replay on the same installation. Cross-device safety requires the backend. |
| Orders, cancellation and support | Verify customer-visible statuses, immutable line/address records, cancellation eligibility and response, guest access, tracking, and approved delivery, returns, privacy, terms and support content. | Live cancellation requires server eligibility. Store-policy text awaits approval. |

## Connecting a verified feature

1. Capture redacted success, empty and failure responses in staging. Confirm authentication, nullability, stable IDs, error/status semantics and pagination with the backend owner.
2. In the feature repository, bind a `VerifiedResponse<T>` for the particular `CustomerOperation` and map JSON to its domain model. Reject invalid shape or missing required fields. Use `acceptEmptyBody` only for endpoints whose confirmed success contract explicitly permits an empty body.
3. Call the matching `CustomerRequest` through `apiProvider`. For inventory, inject the validated product list adapter through `catalogueResponseProvider`. Set `catalogueAccessProvider` to `CatalogueAccess.verifiedAnonymous` only after verifying public access. Login can use `signInAndStore` with a verified token decoder. On session expiry the UI should clear account-bound state while retaining an appropriate local checkout draft. Never infer ownership or automatically merge a guest bag.
4. Enable feature UI only after testing the complete flow and its recovery against staging. An unknown checkout result requires reconciliation against the existing attempt across app restarts before another order can be created. The HTTP transport’s in-process duplicate guard cannot establish server idempotency.

The admin status-update routes and the transaction test endpoint are excluded from the mobile client. The app has no protocol for live cards, refunds, guest-order creation, password reset, search suggestions or remote address books.
