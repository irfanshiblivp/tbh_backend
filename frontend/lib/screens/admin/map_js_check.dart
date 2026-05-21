import 'map_js_check_stub.dart'
    if (dart.library.js) 'map_js_check_web.dart';

bool isGoogleMapsJsLoaded() {
  return checkGoogleMapsLoaded();
}
