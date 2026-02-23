// @module: database_service
// @type: service
// @layer: frontend
// @depends: [sqflite, path, path_provider]
// @exports: [DatabaseService]
// @tables:
//   - local_users: 本地用户信息
//   - bowel_records: 排便记录
//   - chat_sessions: AI对话会话
//   - chat_messages: AI对话消息
//   - settings: 应用设置
// @brief: SQLite数据库服务，管理本地数据存储
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseService {
  static Database? _database;
  static const int _databaseVersion = 1;
  static const String _databaseName = 'intestine_assistant.db';

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE local_users (
        id TEXT PRIMARY KEY,
        nickname TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE bowel_records (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        record_date TEXT NOT NULL,
        record_time TEXT,
        duration_minutes INTEGER,
        stool_type INTEGER,
        color TEXT,
        smell_level INTEGER,
        feeling TEXT,
        symptoms TEXT,
        notes TEXT,
        is_no_bowel INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_bowel_records_date ON bowel_records(record_date)
    ''');

    await db.execute('''
      CREATE INDEX idx_bowel_records_user ON bowel_records(user_id)
    ''');

    await db.execute('''
      CREATE TABLE chat_sessions (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        title TEXT,
        system_prompt TEXT,
        thinking_intensity TEXT DEFAULT 'medium',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE chat_messages (
        id TEXT PRIMARY KEY,
        conversation_id TEXT NOT NULL,
        role TEXT NOT NULL,
        content TEXT NOT NULL,
        thinking_content TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (conversation_id) REFERENCES chat_sessions(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_chat_messages_conversation ON chat_messages(conversation_id)
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Future migrations
    }
  }

  static Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  static Future<void> resetDatabase() async {
    final db = await database;
    await db.delete('chat_messages');
    await db.delete('chat_sessions');
    await db.delete('bowel_records');
    await db.delete('local_users');
    await db.delete('settings');
  }
}
