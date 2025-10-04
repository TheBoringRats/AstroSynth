// Cross-platform stub for planet_detail_screen.dart
// This file conditionally exports web or mobile implementation

export 'planet_detail_screen_stub.dart'
    if (dart.library.html) 'planet_detail_screen_web.dart'
    if (dart.library.io) 'planet_detail_screen_mobile.dart';
