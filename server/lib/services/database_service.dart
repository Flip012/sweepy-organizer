import 'dart:io';

import 'package:postgres/postgres.dart';

class DatabaseService {
  DatabaseService._();
  static DatabaseService? _instance;
  Pool? _pool;

  static DatabaseService get instance {
    _instance ??= DatabaseService._();
    return _instance!;
  }

  Pool get pool {
    if (_pool == null) throw StateError('Database not initialized');
    return _pool!;
  }

  Future<void> initialize() async {
    final databaseUrl =
        Platform.environment['DATABASE_URL'] ??
        'postgresql://sweepy:sweepy@localhost:5432/sweepy';

    final uri = Uri.parse(databaseUrl);
    final endpoint = Endpoint(
      host: uri.host,
      port: uri.port,
      database: uri.pathSegments.first,
      username: uri.userInfo.split(':').first,
      password: uri.userInfo.split(':').last,
    );

    _pool = Pool.withEndpoints(
      [endpoint],
      settings: PoolSettings(
        maxConnectionCount: 10,
        sslMode: SslMode.disable,
      ),
    );

    // Test connection
    await _pool!.execute('SELECT 1');
  }

  Future<Result> query(
    String sql, {
    Map<String, dynamic>? parameters,
  }) async {
    return pool.execute(Sql.named(sql), parameters: parameters ?? {});
  }

  Future<void> close() async {
    await _pool?.close();
    _pool = null;
  }
}
