import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'app_database.db');
    return await openDatabase(
      path,
      version: 4, // Incrementamos la versión
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE reminders(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            description TEXT,
            date TEXT,
            time TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE chat_messages(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            role TEXT,
            content TEXT,
            timestamp INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE projects(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            description TEXT,
            status TEXT,
            dueDate TEXT,
            createdAt INTEGER
          )
        ''');
        
        await db.execute('''
          CREATE TABLE tasks(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            projectId INTEGER,
            title TEXT,
            description TEXT,
            status TEXT,
            dueDate TEXT,
            FOREIGN KEY (projectId) REFERENCES projects(id)
          )
        ''');
        await db.execute('''
          CREATE TABLE quick_notes(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            content TEXT,
            color INTEGER,
            positionX REAL,
            positionY REAL,
            createdAt INTEGER
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 4) {
          await db.execute('''
            CREATE TABLE quick_notes(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              content TEXT,
              color INTEGER,
              positionX REAL,
              positionY REAL,
              createdAt INTEGER
            )
          ''');
        }
      },
    );
  }

  Future<int> insertReminder(Map<String, dynamic> reminder) async {
    final db = await database;
    return await db.insert('reminders', reminder);
  }

  Future<List<Map<String, dynamic>>> getReminders() async {
    final db = await database;
    return await db.query('reminders');
  }

  Future<int> deleteReminder(int id) async {
    final db = await database;
    return await db.delete(
      'reminders',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Nuevos métodos para chat_messages
  Future<int> insertChatMessage(Map<String, dynamic> message) async {
    final db = await database;
    return await db.insert('chat_messages', message);
  }

  Future<List<Map<String, dynamic>>> getChatMessages() async {
    final db = await database;
    return await db.query('chat_messages', orderBy: 'timestamp ASC');
  }

  Future<int> deleteAllChatMessages() async {
    final db = await database;
    return await db.delete('chat_messages');
  }

  // Métodos para proyectos
  Future<int> insertProject(Map<String, dynamic> project) async {
    final db = await database;
    return await db.insert('projects', project);
  }

  Future<List<Map<String, dynamic>>> getProjects() async {
    final db = await database;
    return await db.query('projects', orderBy: 'createdAt DESC');
  }

  Future<int> updateProject(Map<String, dynamic> project) async {
    final db = await database;
    return await db.update(
      'projects',
      project,
      where: 'id = ?',
      whereArgs: [project['id']],
    );
  }

  Future<int> deleteProject(int id) async {
    final db = await database;
    await db.delete('tasks', where: 'projectId = ?', whereArgs: [id]);
    return await db.delete('projects', where: 'id = ?', whereArgs: [id]);
  }

  // Métodos para tareas
  Future<int> insertTask(Map<String, dynamic> task) async {
    final db = await database;
    return await db.insert('tasks', task);
  }

  Future<List<Map<String, dynamic>>> getTasksForProject(int projectId) async {
    final db = await database;
    return await db
        .query('tasks', where: 'projectId = ?', whereArgs: [projectId]);
  }

  Future<int> updateTask(Map<String, dynamic> task) async {
    final db = await database;
    return await db.update(
      'tasks',
      task,
      where: 'id = ?',
      whereArgs: [task['id']],
    );
  }

  Future<int> deleteTask(int id) async {
    final db = await database;
    return await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  // Métodos para notas rápidas
  Future<int> insertQuickNote(Map<String, dynamic> note) async {
    final db = await database;
    return await db.insert('quick_notes', note);
  }

  Future<List<Map<String, dynamic>>> getQuickNotes() async {
    final db = await database;
    return await db.query('quick_notes', orderBy: 'createdAt DESC');
  }

  Future<int> updateQuickNote(Map<String, dynamic> note) async {
    final db = await database;
    return await db.update(
      'quick_notes',
      note,
      where: 'id = ?',
      whereArgs: [note['id']],
    );
  }

  Future<int> deleteQuickNote(int id) async {
    final db = await database;
    return await db.delete('quick_notes', where: 'id = ?', whereArgs: [id]);
  }
}
