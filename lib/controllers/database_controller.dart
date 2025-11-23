import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:path/path.dart";
import "package:path_provider/path_provider.dart";
import "package:sqflite_common_ffi/sqflite_ffi.dart";

class DatabaseController extends AsyncNotifier<Database> {
  @override
  Future<Database> build() async {
    databaseFactory = databaseFactoryFfi;
    return databaseFactoryFfi.openDatabase(
      join((await getApplicationSupportDirectory()).path, "database.db"),
    );
  }

  static final provider = AsyncNotifierProvider<DatabaseController, Database>(
    DatabaseController.new,
  );
}
