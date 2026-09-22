import 'package:web/web.dart' as web;

import 'browser_memory.dart';

/// `localStorage`, reached directly.
///
/// Every call is guarded because touching `localStorage` at all — not just
/// writing to it — throws a `SecurityError` when a browser is set to block
/// site data, and Safari's private mode has historically thrown on write once
/// the quota is reached. A counter is never worth a blank page, so both sides
/// fail quiet: an unreadable store means this browser is counted again, which
/// is the harmless direction to be wrong in.
class PlatformBrowserMemory implements BrowserMemory {
  PlatformBrowserMemory(this._key);

  final String _key;

  @override
  String? read() {
    try {
      return web.window.localStorage.getItem(_key);
    } catch (_) {
      return null;
    }
  }

  @override
  void write(String value) {
    try {
      web.window.localStorage.setItem(_key, value);
    } catch (_) {
      // Nothing to do and nothing worth saying.
    }
  }
}
