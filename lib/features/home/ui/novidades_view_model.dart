import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/novidade_repository.dart';
import '../domain/novidade.dart';

/// The announcements, for the front page.
class NovidadesViewModel extends Cubit<List<Novidade>> {
  NovidadesViewModel(this._repository) : super(const []);

  final NovidadeRepository _repository;

  Future<void> load() async {
    final novidades = await _repository.load();
    if (isClosed) return;
    emit(novidades);
  }
}
