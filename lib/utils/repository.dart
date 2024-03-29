import 'dart:developer';
import 'dart:math' as math;

import 'package:sqflite/sqflite.dart';

import '../models/record.dart';

class Connection {
  Connection._(this.version, this.onCreate, this.onUpdate);

  static late final _instance;

  factory Connection(version, onCreate, onUpdate) {
    _instance = Connection._(version, onCreate, onUpdate);
    return _instance;
  }

  final int version;
  final Function(Database, int) onCreate;
  final Function(Database, int, int) onUpdate;

  Future<Database>? _db;

  Future<Database> get db async {
    if (_db == null) {
      final path = await getDatabasesPath();
      _db = openDatabase(
        "$path/root",
        version: version,
        onCreate: onCreate,
        onUpgrade: onUpgrade,
      );
    }
    return _db!;
  }
}

abstract class Repository {
  Repository({
    required this.table,
    required this.version,
    required this.onCreate,
    required this.onUpdate,
  });

  final String table;
  final int version;
  final Function(Database, int) onCreate;
  final Function(Database, int, int) onUpdate;
  late Connection connection = Connection(version, onCreate, onUpdate);

  Future<int> count({
    Map<String, dynamic>? conditions,
  }) async {
    final db = await connection.db;

    // 组装查询条件
    String? where;
    List<dynamic>? whereArgs;
    if (conditions != null && conditions.isNotEmpty) {
      where = conditions.keys.map((key) => '$key like ?').join(' and ');
      whereArgs = conditions.values.map((value) => '%$value%').toList(growable: false);
    }

    // 执行查询
    final result = await db.query(
      table,
      columns: ['count(*) as count'],
      where: where,
      whereArgs: whereArgs,
    );
    return result[0]['count'] as int;
  }

  Future<List<Map<String, dynamic>>> findAll({
    int? current,
    int? size,
    Map<String, Condition>? conditions,
    List<String>? orders,
  }) async {
    final db = await connection.db;

    // 组装查询条件
    String? where;
    List<dynamic>? whereArgs;
    if (conditions != null && conditions.isNotEmpty) {
      where = conditions.entries.map((entry) {
        final key = entry.key;
        final value = entry.value;
        switch (value.operator) {
          case Operator.EQ:
            return '$key = ?';
          case Operator.LIKE:
            return '$key like ?';
          case Operator.NE:
            return '$key != ?';
          case Operator.GT:
            return '$key > ?';
          case Operator.LT:
            return '$key < ?';
          case Operator.GE:
            return '$key >= ?';
          case Operator.LE:
            return '$key <= ?';
          case Operator.IN:
            assert(value.keyword is List);
            final slots = List.filled(value.keyword.length, '?').join(',');
            return '$key IN ($slots)';
        }
      }).join(' and ');

      whereArgs = conditions.values
          .map((value) {
            switch (value.operator) {
              case Operator.LIKE:
                return '%${value.keyword}%';
              case Operator.IN:
                assert(value.keyword is List);
                return value.keyword;
              default:
                return value.keyword;
            }
          })
          .expand((element) => element is List ? element : [element])
          .toList(growable: false);
    }

    // 按字段排序
    String? orderBy;
    if (orders != null && orders.isNotEmpty) {
      orderBy = orders.join(',');
    }

    // 执行查询
    return await db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      limit: size != null ? math.max(0, size) : size,
      offset: current != null && size != null ? math.max(0, (current - 1) * size) : current,
      orderBy: orderBy,
    );
  }

  Future<Map<String, dynamic>?> findFirst({Map<String, Condition>? conditions, List<String>? orders}) async {
    final all = await findAll(current: 0, size: 1, conditions: conditions, orders: orders);
    return all.isNotEmpty ? all.first : null;
  }

  Future<Map<String, dynamic>?> getById(int id) async {
    final db = await connection.db;
    final result = await db.query(
      table,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return result.isNotEmpty ? result[0] : null;
  }

  Future<void> add(Map<String, dynamic> entity) async {
    entity.remove('id');
    final db = await connection.db;
    log('$entity');
    db.insert(table, entity);
  }

  Future<void> updateById(Map<String, dynamic> entity) async {
    final data = Map.of(entity);

    if (!data.containsKey('id')) {
      throw Exception("更新数据时没有传入 id");
    }

    final id = data['id'];
    data.remove('id');

    final db = await connection.db;
    db.update(table, data, where: "id = ?", whereArgs: [id]);
  }

  Future<void> removeById(int id) async {
    final db = await connection.db;
    db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> removeByIds(List<int> ids) async {
    final db = await connection.db;
    db.delete(
      table,
      where: 'id in (${ids.map((_) => '?').join(',')})',
      whereArgs: ids,
    );
  }
}

class Condition {
  final dynamic keyword;
  final Operator operator;

  Condition(
    this.keyword, [
    this.operator = Operator.EQ,
  ]);
}

enum Operator { EQ, NE, GT, LT, GE, LE, LIKE, IN }
