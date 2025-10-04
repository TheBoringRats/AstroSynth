import 'package:flutter/material.dart';

/// Abstract interface for cross-platform web content display
abstract class PlatformWebView extends StatefulWidget {
  final String url;
  final String? title;

  const PlatformWebView({Key? key, required this.url, this.title})
    : super(key: key);
}
