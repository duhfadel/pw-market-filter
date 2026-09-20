import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/ao_vivo_repository.dart';
import '../domain/canal_ao_vivo.dart';

/// Who is live, for the strip on the front page.
///
/// Emits an empty list for every failure, so the strip simply is not there.
/// Nothing about this feature is worth an error message: it is a courtesy to
/// the people streaming, and a courtesy that shouts when it breaks is worse
/// than one that stays quiet.
class AoVivoViewModel extends Cubit<List<CanalAoVivo>> {
  AoVivoViewModel(this._repository) : super(const []);

  final AoVivoRepository _repository;

  Future<void> load() async {
    final canais = await _repository.load();
    if (isClosed) return;
    emit(aoVivoAgora(canais, DateTime.now().toUtc()));
  }
}
