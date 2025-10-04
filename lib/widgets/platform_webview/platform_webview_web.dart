import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'platform_webview.dart';

/// Web implementation using iframe
class PlatformWebViewWeb extends PlatformWebView {
  const PlatformWebViewWeb({Key? key, required String url, String? title})
    : super(key: key, url: url, title: title);

  @override
  State<PlatformWebViewWeb> createState() => _PlatformWebViewWebState();
}

class _PlatformWebViewWebState extends State<PlatformWebViewWeb> {
  late String _viewId;

  @override
  void initState() {
    super.initState();
    _viewId = 'webview-${widget.url.hashCode}';

    // Register the iframe view factory
    // ignore: undefined_prefixed_name
    ui_web.platformViewRegistry.registerViewFactory(_viewId, (int viewId) {
      final iframe = html.IFrameElement()
        ..src = widget.url
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..allow =
            'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share'
        ..allowFullscreen = true;

      return iframe;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        HtmlElementView(viewType: _viewId),
        if (widget.title != null)
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.title!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
