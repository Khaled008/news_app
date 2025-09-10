import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ArticleWebView extends StatefulWidget {
  final String url;
  final String? title;

  const ArticleWebView({
    super.key,
    required this.url,
    this.title,
  });

  @override
  State<ArticleWebView> createState() => _ArticleWebViewState();
}

class _ArticleWebViewState extends State<ArticleWebView> {
  late final WebViewController _controller;
  final _state = _WebViewState();

  @override
  void initState() {
    super.initState();
    _state.pageTitle = widget.title ?? 'Article Reader';
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) =>
              _updateState(() => _state.loadingProgress = progress),
          onPageStarted: (_) => _updateState(() => _state.setLoading(true)),
          onPageFinished: (_) => _onPageFinished(),
          onWebResourceError: (error) =>
              _updateState(() => _state.setError(error.description)),
          onNavigationRequest: (request) => _handleNavigation(request),
        ),
      );
    _loadUrl();
  }

  void _updateState(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  void _onPageFinished() {
    _updateState(() => _state.isLoading = false);
    _extractPageTitle();
    if (_state.isReaderMode) _applyReaderMode();
  }

  NavigationDecision _handleNavigation(NavigationRequest request) {
    final isSameDomain =
        Uri.parse(widget.url).host == Uri.parse(request.url).host;
    return NavigationDecision.navigate;
  }

  void _loadUrl() {
    try {
      _controller.loadRequest(Uri.parse(widget.url));
    } catch (e) {
      _updateState(() => _state.setError('Invalid URL: ${widget.url}'));
    }
  }

  Future<void> _extractPageTitle() async {
    try {
      final result =
          await _controller.runJavaScriptReturningResult('document.title');
      final title = result.toString().replaceAll('"', '');
      if (title.isNotEmpty && title != 'null') {
        _updateState(() => _state.pageTitle = title);
      }
    } catch (e) {
      debugPrint('Error extracting title: $e');
    }
  }

  void _toggleReaderMode() {
    _updateState(() => _state.isReaderMode = !_state.isReaderMode);
    _state.isReaderMode ? _applyReaderMode() : _controller.reload();
  }

  void _applyReaderMode() {
    _controller.runJavaScript(_ReaderModeJS.script).catchError((e) {
      debugPrint('Error applying reader mode: $e');
    });
  }

  void _shareArticle() {
    Clipboard.setData(ClipboardData(text: widget.url));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Article link copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _navigate(bool forward) async {
    final canNavigate =
        await (forward ? _controller.canGoForward() : _controller.canGoBack());
    if (canNavigate) {
      forward ? _controller.goForward() : _controller.goBack();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          if (_state.error != null)
            _ErrorView(error: _state.error!, onRetry: _loadUrl)
          else
            WebViewWidget(controller: _controller),
          if (_state.isLoading) _LoadingView(progress: _state.loadingProgress),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title:
          Text(_state.pageTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      centerTitle: true,
      backgroundColor: Colors.orange,
      foregroundColor: Colors.white,
      iconTheme: const IconThemeData(color: Colors.black),
      elevation: 2,
      actions: [
        IconButton(
          icon: Icon(
            _state.isReaderMode ? Icons.article_outlined : Icons.article,
          ),
          onPressed: _toggleReaderMode,
          tooltip: _state.isReaderMode ? 'Exit Reader Mode' : 'Reader Mode',
        ),
        _buildMenu(),
      ],
    );
  }

  PopupMenuButton<_MenuAction> _buildMenu() {
    return PopupMenuButton<_MenuAction>(
      onSelected: (action) {
        switch (action) {
          case _MenuAction.refresh:
            _loadUrl();
            break;
          case _MenuAction.share:
            _shareArticle();
            break;
          case _MenuAction.back:
            _navigate(false);
            break;
          case _MenuAction.forward:
            _navigate(true);
            break;
        }
      },
      itemBuilder: (context) => [
        _buildMenuItem(_MenuAction.refresh, Icons.refresh, 'Refresh'),
        _buildMenuItem(_MenuAction.back, Icons.arrow_back, 'Back'),
        _buildMenuItem(_MenuAction.forward, Icons.arrow_forward, 'Forward'),
        _buildMenuItem(_MenuAction.share, Icons.share, 'Share'),
      ],
    );
  }

  PopupMenuItem<_MenuAction> _buildMenuItem(
      _MenuAction action, IconData icon, String text) {
    return PopupMenuItem(
      value: action,
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.black54),
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Text(text, style: const TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}

// State management class
class _WebViewState {
  bool isLoading = true;
  String? error;
  String pageTitle = '';
  bool isReaderMode = false;
  int loadingProgress = 0;

  void setLoading(bool loading) {
    isLoading = loading;
    error = null;
    loadingProgress = 0;
  }

  void setError(String errorMessage) {
    error = errorMessage;
    isLoading = false;
  }
}

enum _MenuAction { refresh, share, back, forward }

// Error view widget
class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.orange),
            const SizedBox(height: 16),
            Text(error,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.orange)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// Loading view widget
class _LoadingView extends StatelessWidget {
  final int progress;

  const _LoadingView({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LinearProgressIndicator(
          value: progress / 100,
          backgroundColor: Colors.grey[300],
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
        ),
        const Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.orange),
                SizedBox(height: 16),
                Text('Loading article...',
                    style: TextStyle(fontSize: 16, color: Colors.grey)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Reader mode JavaScript
class _ReaderModeJS {
  static const String script = '''
    // Remove existing reader mode styles
    var existingStyles = document.getElementById('reader-mode-styles');
    if (existingStyles) existingStyles.remove();
    
    // Create and inject reader mode styles
    var readerStyles = document.createElement('style');
    readerStyles.id = 'reader-mode-styles';
    readerStyles.textContent = `
      /* Hide distracting elements */
      nav, header, footer, aside, .sidebar, .menu, .navigation,
      .advertisement, .ads, .ad, .banner, .popup, .modal,
      .social-share, .share-buttons, .comments, .comment-section,
      .related-articles, .recommendations, .newsletter-signup,
      [class*="ad-"], [id*="ad-"], [class*="advertisement"],
      [class*="banner"], [class*="popup"], [class*="modal"],
      [class*="share"], [class*="social"], [class*="sidebar"] {
        display: none !important;
      }
      
      /* Reset and improve body */
      body {
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif !important;
        line-height: 1.6 !important;
        font-size: 18px !important;
        color: #333 !important;
        background-color: #fff !important;
        margin: 0 !important;
        padding: 20px !important;
        max-width: 100% !important;
      }
      
      /* Container for content */
      body > *, article, .article, .post, .entry, .content,
      .article-content, .post-content, .entry-content,
      .story, .story-body, .article-body, main {
        max-width: 100% !important;
        margin: 0 auto !important;
        padding: 0 20px !important;
        background: transparent !important;
        border: none !important;
        box-shadow: none !important;
      }
      
      /* Typography improvements */
      h1, h2, h3, h4, h5, h6 {
        color: #222 !important;
        line-height: 1.3 !important;
        margin: 1.5em 0 0.5em 0 !important;
        font-weight: bold !important;
      }
      
      h1 { font-size: 2em !important; }
      h2 { font-size: 1.5em !important; }
      h3 { font-size: 1.3em !important; }
      
      p {
        margin: 1em 0 !important;
        line-height: 1.7 !important;
        font-size: 18px !important;
        color: #333 !important;
      }
      
      /* Improve images */
      img {
        max-width: 100% !important;
        height: auto !important;
        border-radius: 8px !important;
        margin: 1.5em 0 !important;
        display: block !important;
      }
      
      /* Improve links */
      a {
        color: #007AFF !important;
        text-decoration: none !important;
      }
      
      a:hover {
        text-decoration: underline !important;
      }
      
      /* Lists */
      ul, ol {
        margin: 1em 0 !important;
        padding-left: 2em !important;
      }
      
      li {
        margin: 0.5em 0 !important;
        line-height: 1.6 !important;
      }
      
      /* Blockquotes */
      blockquote {
        border-left: 4px solid #ddd !important;
        margin: 1.5em 0 !important;
        padding: 0.5em 0 0.5em 1em !important;
        font-style: italic !important;
        color: #666 !important;
      }
      
      /* Code blocks */
      pre, code {
        background-color: #f5f5f5 !important;
        padding: 0.2em 0.4em !important;
        border-radius: 3px !important;
        font-family: 'Monaco', 'Consolas', monospace !important;
      }
      
      pre {
        padding: 1em !important;
        overflow-x: auto !important;
        margin: 1em 0 !important;
      }
      
      /* Remove fixed positioning */
      * {
        position: static !important;
        z-index: auto !important;
      }
      
      /* Hide video overlays */
      .video-overlay, .video-controls, .play-button {
        display: none !important;
      }
    `;
    
    document.head.appendChild(readerStyles);
    
    // Scroll to main content
    setTimeout(function() {
      var content = document.querySelector('article, .article-content, .post-content, .entry-content, .content, main, .story-body');
      if (content) content.scrollIntoView({behavior: 'smooth', block: 'start'});
    }, 100);
    
    // Remove overlays
    var overlays = document.querySelectorAll('.overlay, .modal, .popup, [style*="fixed"], [style*="sticky"]');
    overlays.forEach(function(overlay) {
      overlay.style.display = 'none';
    });
  ''';
}
