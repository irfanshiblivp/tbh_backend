import 'dart:js' as js;

bool checkGoogleMapsLoaded() {
  try {
    if (js.context['google'] == null) return false;
    if (js.context['google']['maps'] == null) return false;
    return true;
  } catch (e) {
    return false;
  }
}
