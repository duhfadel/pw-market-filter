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

final getIt = GetIt.instance;

/// Registered by hand. A handful of services do not justify the codegen an
/// `injectable` setup would bring along.
void configureDependencies() {
  getIt
    ..registerLazySingleton<IndexRepository>(IndexRepository.new)
    ..registerLazySingleton<VisitRepository>(VisitRepository.new)
    ..registerLazySingleton<RegistroRepository>(RegistroRepository.new)
    ..registerLazySingleton<AoVivoRepository>(AoVivoRepository.new)
    ..registerLazySingleton<NovidadeRepository>(NovidadeRepository.new)
    ..registerFactory<SearchViewModel>(
      () => SearchViewModel(getIt<IndexRepository>()),
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
