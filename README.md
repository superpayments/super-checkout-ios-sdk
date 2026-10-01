# SuperCheckoutSDK

A SwiftUI component to accept Super Payments Checkout.

## Requirements

- iOS 15+
- Swift tools 6.4 / Xcode with Swift 6 support
- A Super Payments **checkout session token**, minted by your own backend.

## Installation

In Xcode: File → Add Package Dependencies… → enter `https://github.com/superpayments/super-checkout-ios-sdk`. Or, in `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/superpayments/super-checkout-ios-sdk", from: "0.3.0")
]
```

Then add `SuperCheckoutSDK` to your target's dependencies:

```swift
.target(
    name: "YourApp",
    dependencies: [
        .product(name: "SuperCheckoutSDK", package: "super-checkout-ios-sdk")
    ]
)
```

## Quick start

`SuperCheckoutView` doesn't render its own "Pay" button — you own that button in your own UI, and trigger submission through a `SuperCheckoutController`:

```swift
import SwiftUI
import SuperCheckoutSDK

struct PaymentScreen: View {
    let checkoutSessionToken: String

    @StateObject private var checkoutController = SuperCheckoutController()

    var body: some View {
        VStack {
            SuperCheckoutView(
                checkoutSessionToken: checkoutSessionToken,
                amount: 10000,           // gross amount, in minor units (e.g. 10000 = £100.00)
                currency: "GBP",
                environment: .test,
                merchantIdentifier: "merchant.com.yourcompany.yourapp",
                controller: checkoutController,
                onResult: { result in
                    switch result {
                    case .success:
                        print("Time to call /proceed endpoint.")
                    case .failure(let message):
                        print("Payment failed: \(message)")
                    }
                }
            )

            Button("Pay £100.00") {
                checkoutController.submit(amount: 10000)
            }
        }
    }
}
```

> **`onResult`'s `.success` only means the card was attached to the checkout session — not that the payment has executed.**. You're still responsible for calling `/proceed` yourself to actually execute the payment, which is what may return a 3D Secure challenge. See [Proceeding the payment](#proceeding-the-payment) below.

### Triggering submission — `SuperCheckoutController`

`SuperCheckoutController.submit(amount:)` tells `SuperCheckoutView` to submit whatever card details are currently entered. The `amount` you pass to `submit(amount:)` doesn't have to match the `amount` `SuperCheckoutView` was initialized with — for example, if the checkout amount changes after the view was created (a promo code, a tip, an updated basket), call `submit(amount:)` with the new amount rather than recreating `SuperCheckoutView`. Whatever amount you submit with is also what you must pass to `/proceed` afterwards.

## Environments

```swift
public enum SuperCheckoutEnvironment {
    case test
    case production
}
```

| Case | Super Payments API | Adyen environment |
|---|---|---|
| `.test` | `api.test.superpayments.com` | sandbox | 
| `.production` | `api.superpayments.com` | live |

## Error reporting

`onResult` only tells you about the outcome of a payment *attempt*. Plenty of failures never get that far — the checkout session failing to load, a 3D Secure challenge failing to render — and those previously just rendered an error message on screen with no way for your app to know.

`SuperCheckout.onError` is a single global hook that fires for **every** problem the SDK hits. The SDK does not bundle Sentry, Crashlytics, or any other reporting dependency; forward the diagnostics wherever you already send yours.

Set it once, before presenting any checkout UI — `application(_:didFinishLaunchingWithOptions:)` or your `App.init()`:

```swift
import Sentry
import SuperCheckoutSDK

SuperCheckout.onError = { diagnostic in
    SentrySDK.capture(message: diagnostic.message) { scope in
        scope.setTag(value: diagnostic.operation, key: "super_checkout.operation")
        scope.setContext(value: diagnostic.metadata, key: "super_checkout")
    }
}
```

Leave it unset and the SDK reports nothing — there is no default behaviour and no network traffic beyond the payment calls themselves.

### What a diagnostic contains

```swift
public struct SuperCheckoutDiagnostic {
    public let severity: Severity            // .warning or .error
    public let operation: String             // e.g. "payment.submitCard"
    public let message: String               // redacted, human-readable
    public let metadata: [String: String]    // statusCode, errorDomain, errorCode
}
```

`operation` is a stable string identifying where in the flow the problem came from — tag or group on it:

| `operation` | Fires when |
|---|---|
| `session.invalidToken` | The `checkoutSessionToken` isn't a decodable JWT |
| `session.unsupportedProvider` | The session has no Adyen-backed card capability |
| `session.loadFailed` | Fetching the checkout session failed |
| `payment.cardComponent` | Adyen's card component reported a failure |
| `payment.applePayComponent` | Adyen's Apple Pay component reported a failure |
| `payment.submitCard` | Submitting new card details failed |
| `payment.submitApplePay` | Submitting an Apple Pay token failed |
| `payment.submitSavedCard` | Charging a saved card failed |
| `upsell.invalidToken` | `SuperUpsellCheckout` got an undecodable token |
| `upsell.trigger` | An upsell charge failed, including "no saved card on the session" |
| `threeDS.decode` | The `nativeNextAction` passed to `ThreeDSRedirectView` couldn't be decoded |
| `threeDS.webView` | The 3DS wrapper document failed to load |
| `threeDS.bridge` | The 3DS page never completed the bridge handshake — the challenge is stuck and will never report a result |

### Two things to know

**The handler is called on whatever thread hit the problem.** No main-thread guarantee — `threeDS.webView` arrives on a WebKit callback, `upsell.trigger` on a background executor. Hop yourself if your code needs it. It also runs inline with the payment flow, so keep the handler cheap.

```swift
SuperCheckout.onError = { diagnostic in
    SentrySDK.capture(message: diagnostic.message) { scope in
        scope.setTag(value: diagnostic.operation, key: "super_checkout.operation")
        scope.setContext(value: diagnostic.metadata, key: "super_checkout")
    }
}
```

Neither `message` nor `metadata` ever contains card data, Apple Pay tokens, or the checkout session token.

## Handling 3D Secure

Present it (e.g. via `.fullScreenCover`) whenever `/proceed` endpoint returns a `nativeNextAction`:

```swift
import SwiftUI
import SuperCheckoutSDK

struct ThreeDSScreen: View {
    let nativeNextAction: String
    let onDismiss: () -> Void

    var body: some View {
        ThreeDSRedirectView(
            nativeNextAction: nativeNextAction,
            environment: .staging,
            onRedirect: { result in
                // result.url: where the challenge redirected to
                // result.isFailure: whether the challenge failed
                onDismiss()
            },
            onCancel: {
                // The view has a built-in close (X) button that calls this.
                onDismiss()
            }
        )
    }
}
```

- `onRedirect(_ result: ThreeDSRedirectResult)` fires once the challenge completes, with `result.url` (where the flow redirected to) and `result.isFailure`. After this, check the payment's final status via your backend — the redirect itself doesn't tell you definitively that the payment succeeded. There is no need to use the `url` because the View is going to be closed automatically.
- `onCancel()` fires if the customer taps the view's built-in close button; dismiss your presentation in response.
- Pass the **same `environment`** you used for `SuperCheckoutView` (or at least the same tier — test/staging/production) — it determines which Super Payments host the bridge expects redirects to land back on.

## Upsell — charging a saved card off-session

`SuperUpsellCheckout` silently charges a customer's already-saved card — a post-purchase order bump, anything that shouldn't show checkout UI at all. Unlike `SuperCheckoutView`, it isn't a `View`: there's no card form, no Apple Pay button, nothing to render — just an async call.

### Prerequisites

1. The customer must already have a saved card from a previous pur., and when calling `/proceed` for it, include `customer.savePaymentMethodOptions.futureUsage: "OFF_SESSION"`.
2. Your backend must mint a **new** checkout session locked to that saved payment method, using `existingPaymentMethodId` instead of `savePaymentMethod`:

Locking the session this way means only that saved card can be used to fund it — there's no payment method to pick, which is why `SuperUpsellCheckout` doesn't render anything.

### Triggering the charge

```swift
import SuperCheckoutSDK

let upsellCheckout = SuperUpsellCheckout(
    checkoutSessionToken: checkoutSessionToken, // from the locked session above
    currency: "GBP",
    environment: .staging
)

let result = await upsellCheckout.trigger(amount: 2000) // £20.00

switch result {
case .success:
    print("Time to call /proceed endpoint.")
case .failure(let message):
    print("Upsell charge failed: \(message)")
}
```

`trigger(amount:)` fetches the session, finds the saved card it's locked to, and submits the payment — the same `SAVED_PAYMENT_METHOD` funding method a saved-card payment on `SuperCheckoutView` uses. If the session has no saved card attached (e.g. it wasn't created with `existingPaymentMethodId`), it fails with a clear error instead of hanging.

`.success` here means exactly what it means for `SuperCheckoutView`: the charge has been submitted, but **you still need to call `/proceed`** yourself to execute it and find out whether a 3D Secure challenge is required — handle that the same way, via [`ThreeDSRedirectView`](#handling-3d-secure).
