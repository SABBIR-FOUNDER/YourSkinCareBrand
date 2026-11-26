![YourSkinCareBrand wordmark](assets/horizontal-logo.svg)

# YourSkinCareBrand · Flutter skincare storefront

**Author and project maintainer · [SABBIR AHAMMED](https://github.com/SABBIR-FOUNDER)**

YourSkinCareBrand is an Android and iOS storefront for browsing multi-brand skincare, saving products and placing test orders. The offline demo takes a shopper from a product page to an order receipt. Staging connects the same app to a customer account, a server-backed bag and cash-on-delivery checkout.

![Flutter](https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?logo=dart&logoColor=white)
![Riverpod](https://img.shields.io/badge/State-Riverpod-8D405B)

## What works today

| Area | Offline demo | Connected staging |
| --- | --- | --- |
| Catalogue | Browse sample products, shades, Sale and Clearance. Search loaded products and save favourites. | Browse the first public product page. Prices use whole Bangladeshi taka, so an API value of `12000` displays as **BDT 12,000**. |
| Account | Try registration, email verification, sign-in and profile editing with the on-screen examples. | Sign in with an existing customer account, view the profile returned at login and sign out locally. |
| Bag | Select a variant, change quantities and review the subtotal. | Add an in-stock product without options. Refresh or page through the customer's bag to see server quantities and prices. |
| Checkout | Walk through delivery, payment, confirmation and cancellation. Demo controls can simulate a failed submission. | Place a cash-on-delivery test order. The receipt shows the order ID, total and payment status returned by the server. |
| Orders | Open a receipt and inspect its original items and delivery details. | View recent orders or look up a specific order ID. |

**Release status:** Production ordering and online payment are disabled. If a staging checkout response is lost, the app remembers the uncertain attempt on that installation and blocks a second submission. Production checkout still needs a server-side checkout reference that identifies the original order after a retry, plus end-to-end verification.

## Run the demo

Use Flutter **3.38.9** and Dart **3.10.8**, the versions used to verify this project. From the repository root, connect a device or start a simulator and run:

```sh
flutter pub get
flutter run --dart-define=APP_ENV=development --dart-define=DEMO_MODE=true
```

Open **Petal Serum → Add to bag → Checkout → Fill sample address**. Choose cash on delivery and open the receipt. To see how the app handles a lost payment response, use **Demo** in the header. Restarting the demo clears its sample session.

## Connect a staging store

Set `API_BASE_URL` to your staging API and `CHECKOUT_RETURN_URL` to a store-controlled HTTPS return address. Replace both example domains below. The staging checkout sends an order to the configured backend, so use a test customer and test delivery details.

```sh
flutter run --dart-define=APP_ENV=staging --dart-define=API_BASE_URL=https://api.example.com/api --dart-define=CHECKOUT_RETURN_URL=https://shop.example.com/checkout/return
```

The staging COD button appears when the complete, priced bag fits on one page and a return URL is configured. Platform secure storage holds the customer session token. Supply signing credentials through the build environment and keep private keys outside the repository. Integration details are in [API_CONTRACT_GAPS.md](API_CONTRACT_GAPS.md).

## Technology and project layout

The app uses **Flutter and Dart** for the interface, **Riverpod** for state, **GoRouter** for navigation, **Dio** for HTTP and **flutter_secure_storage** for customer tokens.

| Directory | Responsibility |
| --- | --- |
| [lib/app/](lib/app/) | Shared navigation, theme and demo controls |
| [lib/features/catalogue/](lib/features/catalogue/) | Browse, search, product details and wishlist |
| [lib/features/account/](lib/features/account/) | Sign-in, customer profiles and addresses |
| [lib/features/checkout/](lib/features/checkout/) | Shopping bag, delivery, checkout and order lookup |
| [lib/core/network/](lib/core/network/) | Request construction, response validation, session handling and API errors |
| [assets/](assets/) | Ribbon identity, product imagery and Public Sans typography |
| [test/](test/) and [integration_test/](integration_test/) | Automated checks and device shopping journeys |

## Verify changes

```sh
flutter analyze
flutter test
flutter test --dart-define=APP_ENV=staging --dart-define=CHECKOUT_RETURN_URL=https://store.invalid/return test/server_checkout_test.dart
flutter test --dart-define=APP_ENV=production test/production_test.dart
```

The staging test simulates a lost order response, reopens the bag and checks that the app sends only one order request. To exercise the demo shopping journey on a connected device, replace `DEVICE_ID` with its identifier from `flutter devices`.

```sh
flutter test integration_test/shop_flow_test.dart -d DEVICE_ID --dart-define=APP_ENV=development
```

## Author and contact

**SABBIR AHAMMED** maintains YourSkinCareBrand. For project questions, release coordination or collaboration, contact the maintainer through [GitHub · SABBIR-FOUNDER](https://github.com/SABBIR-FOUNDER) or [LinkedIn · SABBIR AHAMMED](https://www.linkedin.com/in/sabbir911/).

## License and attribution

Copyright © 2026 SABBIR AHAMMED. Consult the repository's `LICENSE` file for source-code terms. Public Sans is distributed with its own [SIL Open Font License](assets/OFL.txt).
