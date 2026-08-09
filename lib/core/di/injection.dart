import 'package:get_it/get_it.dart';

import '../../features/search/ui/search_view_model.dart';
import '../../market/index_repository.dart';

final getIt = GetIt.instance;

/// Registered by hand. Three services do not justify the codegen an
/// `injectable` setup would bring along.
void configureDependencies() {
  getIt
    ..registerLazySingleton<IndexRepository>(IndexRepository.new)
    ..registerFactory<SearchViewModel>(
      () => SearchViewModel(getIt<IndexRepository>()),
    );
}
