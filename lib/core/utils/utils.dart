class Utils {
  String getAppVersion() {
    const String version = String.fromEnvironment('APP_VERSION', defaultValue: '0.0.0');
    return version;
  }
}
