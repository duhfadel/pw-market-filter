import 'package:get_it/get_it.dart';

import '../../features/home/data/visit_repository.dart';
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
    ..registerFactory<SearchViewModel>(
      () => SearchViewModel(getIt<IndexRepository>()),
    )
    ..registerFactory<VisitCounterViewModel>(
      () => VisitCounterViewModel(getIt<VisitRepository>()),
    );
}
