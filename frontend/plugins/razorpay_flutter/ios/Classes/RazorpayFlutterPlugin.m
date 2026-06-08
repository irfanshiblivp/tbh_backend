#import "RazorpayFlutterPlugin.h"
#import "razorpay_flutter-Swift.h"

@implementation RazorpayFlutterPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftRazorpayFlutterPlugin registerWithRegistrar:registrar];
}
@end
