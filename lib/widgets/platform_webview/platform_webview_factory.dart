import 'platform_webview.dart';
import 'platform_webview_mobile.dart'
    if (dart.library.html) 'platform_webview_web.dart';

/// Factory to create platform-specific webview
PlatformWebView createPlatformWebView({required String url, String? title}) {
  return PlatformWebViewMobile(url: url, title: title);
}
