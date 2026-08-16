import 'visit_memory_stub.dart'
    if (dart.library.js_interop) 'visit_memory_web.dart'
    as platform;

/// Where a browser remembers that it has already been counted today.
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
abstract class VisitMemory {
  /// `null` when this browser has not been counted, or when storage is
  /// unreadable — private browsing can refuse it outright.
  String? read();

  void write(String day);

  factory VisitMemory.platform() = platform.PlatformVisitMemory;
}
