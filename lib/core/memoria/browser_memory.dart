import 'browser_memory_stub.dart'
    if (dart.library.js_interop) 'browser_memory_web.dart'
    as platform;

/// A guarded corner of `localStorage`, one instance per key.
///
/// This is one interface with two implementations chosen at compile time, the
/// same shape the collector uses to keep `dart:io` out of `lib/collector/`: the
/// web build gets `localStorage`, and the VM build — which in practice means
/// the test suite — gets a field. The conditional import is what allows
/// `VisitRepository` to be tested at all, since `package:web` cannot be loaded
/// outside a browser.
///
/// `shared_preferences` was here first and was removed. On the web build it
/// wrote to neither `localStorage` nor IndexedDB; the failure surfaced as a
/// `MissingPluginException`, which is an `Exception`, which the repository's
/// `catch` swallowed by design — so the counter simply counted every reload
/// and said nothing. Fourteen transitive packages to reach an API the browser
/// already exposes in one line was a bad trade even when it worked.
///
/// **The key is a constructor argument and the class is no longer called
/// `VisitMemory`.** It held one hard-coded key while the visit counter was its
/// only user; the news bar needs to remember which entry a reader has already
/// seen, and a second copy of the same guarded three lines is how two stores
/// drift apart.
abstract class BrowserMemory {
  /// `null` when nothing was stored under this key, or when storage is
  /// unreadable — private browsing can refuse it outright.
  String? read();

  void write(String value);

  factory BrowserMemory.platform(String key) = platform.PlatformBrowserMemory;
}
