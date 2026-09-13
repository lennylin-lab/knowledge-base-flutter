import 'package:web/web.dart' as web;

/// Updates the HTML document title — the browser tab / history entry label.
void setBrowserTabTitle(String title) {
  web.document.title = title;
}
