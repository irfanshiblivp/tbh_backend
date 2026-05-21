bool checkGoogleMapsLoaded() {
  // On native platforms (iOS, Android), Google Maps uses native SDKs.
  // We assume the native SDK is available, so we return true.
  return true;
}
