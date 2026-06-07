import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../theme/app_theme.dart';

/// Teleparty-style sync: loads a streaming website in a WebView where each
/// person logs into their own account. Injected JavaScript hooks the page's
/// <video> element so play/pause/seek are broadcast and applied on both
/// sides — the video itself plays through the site's official player.
class WebSyncWidget extends StatefulWidget {
  final String url;
  final double? pendingPlay;
  final double? pendingPause;
  final double? pendingSeek;
  final void Function(double) onPlay;
  final void Function(double) onPause;
  final void Function(double) onSeek;
  final VoidCallback onClearPendingPlay;
  final VoidCallback onClearPendingPause;
  final VoidCallback onClearPendingSeek;

  const WebSyncWidget({
    super.key,
    required this.url,
    required this.onPlay,
    required this.onPause,
    required this.onSeek,
    required this.onClearPendingPlay,
    required this.onClearPendingPause,
    required this.onClearPendingSeek,
    this.pendingPlay,
    this.pendingPause,
    this.pendingSeek,
  });

  @override
  State<WebSyncWidget> createState() => _WebSyncWidgetState();
}

class _WebSyncWidgetState extends State<WebSyncWidget> {
  InAppWebViewController? _controller;

  static const String _injectJs = '''
(function(){
  if (window.__liliInit) return;
  window.__liliInit = true;
  window.__liliApplying = false;
  function vid(){ return document.querySelector('video'); }
  function send(action){
    if (window.__liliApplying) return;
    var v = vid(); if(!v) return;
    try {
      window.flutter_inappwebview.callHandler('liliSync', {action: action, time: v.currentTime});
    } catch(e){}
  }
  function bind(v){
    if(!v || v.__liliBound) return;
    v.__liliBound = true;
    v.addEventListener('play', function(){ send('play'); });
    v.addEventListener('pause', function(){ send('pause'); });
    v.addEventListener('seeked', function(){ send('seek'); });
  }
  function scan(){ bind(vid()); }
  setInterval(scan, 1500);
  scan();
  window.__liliApply = function(action, time){
    var v = vid(); if(!v) return;
    window.__liliApplying = true;
    try{
      if (typeof time === 'number' && time >= 0 && Math.abs(v.currentTime - time) > 1.0) {
        v.currentTime = time;
      }
      if (action === 'play') { var p = v.play(); if (p && p.catch) p.catch(function(){}); }
      else if (action === 'pause') { v.pause(); }
    }catch(e){}
    setTimeout(function(){ window.__liliApplying = false; }, 800);
  };
})();
''';

  @override
  void didUpdateWidget(WebSyncWidget old) {
    super.didUpdateWidget(old);
    if (widget.pendingPlay != null && old.pendingPlay == null) {
      _apply('play', widget.pendingPlay!);
      widget.onClearPendingPlay();
    }
    if (widget.pendingPause != null && old.pendingPause == null) {
      _apply('pause', widget.pendingPause!);
      widget.onClearPendingPause();
    }
    if (widget.pendingSeek != null && old.pendingSeek == null) {
      _apply('seek', widget.pendingSeek!);
      widget.onClearPendingSeek();
    }
  }

  void _apply(String action, double time) {
    _controller?.evaluateJavascript(
      source: "if(window.__liliApply){window.__liliApply('$action', $time);}",
    );
  }

  @override
  Widget build(BuildContext context) {
    return InAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(widget.url)),
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        mediaPlaybackRequiresUserGesture: false,
        allowsInlineMediaPlayback: true,
        useHybridComposition: true,
      ),
      onWebViewCreated: (controller) {
        _controller = controller;
        controller.addJavaScriptHandler(
          handlerName: 'liliSync',
          callback: (args) {
            if (args.isEmpty) return;
            final data = args.first;
            if (data is! Map) return;
            final action = data['action'] as String?;
            final time = (data['time'] as num?)?.toDouble() ?? 0;
            switch (action) {
              case 'play':
                widget.onPlay(time);
                break;
              case 'pause':
                widget.onPause(time);
                break;
              case 'seek':
                widget.onSeek(time);
                break;
            }
          },
        );
      },
      onLoadStop: (controller, url) async {
        await controller.evaluateJavascript(source: _injectJs);
      },
    );
  }
}
