import 'package:web/web.dart' as web;

import 'visit_memory.dart';

/// `localStorage`, reached directly.
///
/// Every call is guarded because touching `localStorage` at all — not just
/// writing to it — throws a `SecurityError` when a browser is set to block
/// site data, and Safari's private mode has historically thrown on write once
/// the quota is reached. A counter is never worth a blank page, so both sides
/// fail quiet: an unreadable store means this browser is counted again, which
/// is the harmless direction to be wrong in.
class PlatformVisitMemory implements VisitMemory {
  static const _key = 'portal_pw_last_visit_day';

  @override
  String? read() {
    try {
      return web.window.localStorage.getItem(_key);
    } catch (_) {
      return null;
    }
  }

  @override
  void write(String day) {
    try {
      web.window.localStorage.setItem(_key, day);
    } catch (_) {
      // Nothing to do and nothing worth saying.
    }
  }
}
