import 'package:get_it/get_it.dart';

import '../../features/home/data/ao_vivo_repository.dart';
import '../../features/home/ui/ao_vivo_view_model.dart';
import '../../features/home/data/novidade_repository.dart';
import '../../features/home/ui/novidades_view_model.dart';
import '../../features/home/data/visit_repository.dart';
import '../../features/registros/ui/registros_view_model.dart';
import '../../features/registros/data/registro_repository.dart';
import '../../features/home/ui/visit_counter_view_model.dart';
import '../../features/search/ui/search_view_model.dart';
import '../../market/index_repository.dart';
import '../../market/versoes_repository.dart';

final getIt = GetIt.instance;

/// Registered by hand. A handful of services do not justify the codegen an
/// `injectable` setup would bring along.
///
/// **Two marketplaces, two named instances — never two unnamed ones.** GetIt
/// resolves an unnamed `get<T>()` to whichever registration of that type was
/// made last if more than one exists, so a second bare
/// `registerLazySingleton<IndexRepository>()` would silently shadow the
/// first instead of erroring. Keying the second registration by
/// [IndexRepository.pw126] — the same string `IndexRepository.server` and
/// `core/rotas.dart`'s own `pw126` already use — means `getIt<IndexRepository>()`
/// keeps meaning "the 1.8.7 one" exactly as it always has, and every call site
/// written before the 1.2.6 home existed keeps compiling and behaving
/// unchanged. The alternative the brief offered — one factory taking a
/// version parameter — would still need two named entry points to read
/// through, since nothing here builds all its dependencies at a single call
/// site the way `main.dart`'s routing does; naming the two registrations
/// directly is the shorter path to the same place.
void configureDependencies() {
  getIt
    ..registerLazySingleton<IndexRepository>(
      () => IndexRepository(null, IndexRepository.pw187),
    )
    ..registerLazySingleton<IndexRepository>(
      () => IndexRepository(null, IndexRepository.pw126),
      instanceName: IndexRepository.pw126,
    )
    ..registerLazySingleton<VersoesRepository>(VersoesRepository.new)
    ..registerLazySingleton<VisitRepository>(VisitRepository.new)
    ..registerLazySingleton<RegistroRepository>(RegistroRepository.new)
    ..registerLazySingleton<AoVivoRepository>(AoVivoRepository.new)
    ..registerLazySingleton<NovidadeRepository>(NovidadeRepository.new)
    ..registerFactory<SearchViewModel>(
      () => SearchViewModel(getIt<IndexRepository>()),
    )
    ..registerFactory<SearchViewModel>(
      () => SearchViewModel(
        getIt<IndexRepository>(instanceName: IndexRepository.pw126),
      ),
      instanceName: IndexRepository.pw126,
    )
    ..registerFactory<RegistrosViewModel>(
      () => RegistrosViewModel(getIt<RegistroRepository>()),
    )
    ..registerFactory<NovidadesViewModel>(
      () => NovidadesViewModel(getIt<NovidadeRepository>()),
    )
    ..registerFactory<AoVivoViewModel>(
      () => AoVivoViewModel(getIt<AoVivoRepository>()),
    )
    ..registerFactory<VisitCounterViewModel>(
      () => VisitCounterViewModel(getIt<VisitRepository>()),
    );
}
