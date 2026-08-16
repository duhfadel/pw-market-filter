import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/visit_repository.dart';

/// The visit count, or `null` while it is unknown.
///
/// `null` covers both "still loading" and "could not be reached", and that is
/// on purpose: the footer draws nothing in either case. A spinner for a number
/// nobody is waiting on would be noise, and an error message about a counter
/// would be worse than the missing counter.
class VisitCounterViewModel extends Cubit<int?> {
  VisitCounterViewModel(this._repository) : super(null);

  final VisitRepository _repository;

  Future<void> load() async {
    final total = await _repository.register();
    if (!isClosed) emit(total);
  }
}
