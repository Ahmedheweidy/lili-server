import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../services/history_service.dart';
import '../theme/app_theme.dart';

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
  final _urlController = TextEditingController();
  bool _loading = false;

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
    v.addEventListener('play',   function(){ send('play'); });
    v.addEventListener('pause',  function(){ send('pause'); });
    v.addEventListener('seeked', function(){ send('seek'); });
  }
  setInterval(function(){ bind(vid()); }, 1500);
  bind(vid());
  window.__liliApply = function(action, time){
    var v = vid(); if(!v) return;
    window.__liliApplying = true;
    try{
      if (typeof time === 'number' && time >= 0 && Math.abs(v.currentTime - time) > 1.0)
        v.currentTime = time;
      if (action === 'play') { var p = v.play(); if(p && p.catch) p.catch(function(){}); }
      else if (action === 'pause') { v.pause(); }
    }catch(e){}
    setTimeout(function(){ window.__liliApplying = false; }, 800);
  };
})();
''';

  @override
  void initState() {
    super.initState();
    _urlController.text = widget.url;
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

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
      source: "if(window.__liliApply){window.__liliApply('$action',$time);}",
    );
  }

  void _navigate(String input) {
    final text = input.trim();
    if (text.isEmpty) return;
    final String url;
    if (text.startsWith('http://') || text.startsWith('https://')) {
      url = text;
    } else {
      url = 'https://www.google.com/search?q=${Uri.encodeComponent(text)}';
    }
    _controller?.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Browser nav bar ──────────────────────────────
        Container(
          color: AppTheme.nightSurface,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Row(
            children: [
              _NavBtn(
                icon: Icons.arrow_back_ios_new,
                onTap: () async {
                  if (await _controller?.canGoBack() ?? false) _controller?.goBack();
                },
              ),
              _NavBtn(
                icon: _loading ? Icons.close : Icons.refresh,
                onTap: () => _loading ? _controller?.stopLoading() : _controller?.reload(),
              ),
              Expanded(
                child: Container(
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: TextField(
                    controller: _urlController,
                    style: const TextStyle(color: AppTheme.warmWhite, fontSize: 12),
                    decoration: const InputDecoration(
                      hintText: 'ابحث أو اكتب رابط...',
                      hintStyle: TextStyle(color: AppTheme.dimWhite, fontSize: 12),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                      filled: false,
                    ),
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.go,
                    onSubmitted: _navigate,
                  ),
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),

        // ── Loading indicator ─────────────────────────────
        if (_loading)
          LinearProgressIndicator(
            minHeight: 2,
            backgroundColor: AppTheme.cardBg,
            color: AppTheme.rosePink,
          ),

        // ── WebView ───────────────────────────────────────
        Expanded(
          child: InAppWebView(
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
                    case 'play':  widget.onPlay(time);  break;
                    case 'pause': widget.onPause(time); break;
                    case 'seek':  widget.onSeek(time);  break;
                  }
                },
              );
            },
            onLoadStart: (_, __) => setState(() => _loading = true),
            onLoadStop: (controller, url) async {
              final urlStr = url?.toString() ?? '';
              final title  = await controller.getTitle() ?? '';
              setState(() {
                _loading = false;
                if (urlStr.isNotEmpty) _urlController.text = urlStr;
              });
              HistoryService.add(urlStr, title);
              await controller.evaluateJavascript(source: _injectJs);
            },
            onLoadError: (_, __, ___, ____) => setState(() => _loading = false),
          ),
        ),
      ],
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Icon(icon, color: AppTheme.softLavender, size: 18),
      ),
    );
  }
}
