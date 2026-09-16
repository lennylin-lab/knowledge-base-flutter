import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import 'operations_repository.dart';

/// Operations repository wired to the app-wide API client (rebuilt when the
/// base URL changes); override this in tests (provider-guidelines spec).
final operationsRepositoryProvider = Provider<OperationsRepository>(
  (ref) => OperationsRepository(ref.watch(apiClientProvider)),
);
