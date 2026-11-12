import 'browser_memory.dart';

/// The non-browser implementation, which is to say the one the tests run
/// against. It forgets everything when the process ends, and that is fine:
/// this app only ever ships to a browser.
class PlatformBrowserMemory implements BrowserMemory {
  /// Takes the key so the two builds have one shape, and ignores it: a field
  /// per instance already separates one store from another here.
  PlatformBrowserMemory(String key);

  String? _valor;

  @override
  String? read() => _valor;

  @override
  void write(String value) => _valor = value;
}
