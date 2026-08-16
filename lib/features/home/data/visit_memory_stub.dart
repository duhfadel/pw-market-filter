import 'visit_memory.dart';

/// The non-browser implementation, which is to say the one the tests run
/// against. It forgets everything when the process ends, and that is fine:
/// this app only ever ships to a browser.
class PlatformVisitMemory implements VisitMemory {
  String? _day;

  @override
  String? read() => _day;

  @override
  void write(String day) => _day = day;
}
