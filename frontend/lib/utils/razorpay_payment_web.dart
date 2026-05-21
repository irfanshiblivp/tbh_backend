import 'dart:js' as js;

void openRazorpayWebCheckout({
  required Map<String, dynamic> options,
  required Function(Map<String, dynamic>) onSuccess,
  required Function() onCancel,
}) {
  try {
    final jsOptions = {
      'key': options['key'],
      'amount': options['amount'],
      'name': options['name'],
      'order_id': options['order_id'],
      'description': options['description'],
      'prefill': {
        'contact': options['prefill']?['contact'] ?? '',
        'email': options['prefill']?['email'] ?? '',
      },
      'theme': {
        'color': options['theme']?['color'] ?? '#FFB000'
      },
      'handler': js.allowInterop((response) {
        final Map<String, dynamic> successData = {
          'razorpay_payment_id': response['razorpay_payment_id'],
          'razorpay_order_id': response['razorpay_order_id'],
          'razorpay_signature': response['razorpay_signature'],
        };
        onSuccess(successData);
      }),
      'modal': {
        'ondismiss': js.allowInterop(() {
          onCancel();
        })
      }
    };

    final rzp = js.JsObject(js.context['Razorpay'], [js.JsObject.jsify(jsOptions)]);
    rzp.callMethod('open');
  } catch (e) {
    // Falls back gracefully
    print("Error launching Razorpay Web Checkout: $e");
  }
}
