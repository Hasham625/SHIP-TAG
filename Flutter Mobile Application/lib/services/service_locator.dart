import 'package:get_it/get_it.dart';
import '../repositories/implementations/index.dart';
import './database_service.dart';

final getIt = GetIt.instance;

void setupServiceLocator({bool useMocks = true}) {
  // Register DatabaseService as singleton
  if (!getIt.isRegistered<DatabaseService>()) {
    getIt.registerSingleton<DatabaseService>(DatabaseService());
  }

  if (useMocks) {
    // mock implementations
    getIt.registerSingleton<AuthRepository>(
      MockAuthRepository(),
    );
    getIt.registerSingleton<DataRepository>(
      MockDataRepository(),
    );
  } else {
    // real implementations
    getIt.registerSingleton<AuthRepository>(
      DjangoAuthRepository(),
    );
    getIt.registerSingleton<DataRepository>(
      DjangoDataRepository(),
    );
  }
}
