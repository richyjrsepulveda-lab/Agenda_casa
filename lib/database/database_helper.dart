import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/models.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('agenda.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3, // Incrementar versión
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categorias (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        intervaloNotificacion INTEGER NOT NULL,
        tipoIntervalo INTEGER NOT NULL,
        color TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE marcas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        descripcion TEXT,
        fechaHora INTEGER NOT NULL,
        categoriaId INTEGER,
        intervaloNotificacionPersonalizado INTEGER,
        tipoIntervaloPersonalizado INTEGER,
        finalizada INTEGER NOT NULL DEFAULT 0,
        fechaCreacion INTEGER NOT NULL,
        FOREIGN KEY (categoriaId) REFERENCES categorias (id) ON DELETE SET NULL
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Migrar tabla categorias
      await db.execute('ALTER TABLE categorias ADD COLUMN tipoIntervalo INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE categorias RENAME COLUMN intervaloNotificacionMinutos TO intervaloNotificacion');
      
      // Migrar tabla marcas
      await db.execute('ALTER TABLE marcas ADD COLUMN tipoIntervaloPersonalizado INTEGER');
      await db.execute('ALTER TABLE marcas RENAME COLUMN intervaloNotificacionMinutosPersonalizado TO intervaloNotificacionPersonalizado');
    }
    if (oldVersion < 3) {
      // Cambiar de estado a finalizada
      await db.execute('ALTER TABLE marcas ADD COLUMN finalizada INTEGER DEFAULT 0');
      // Migrar datos: estado=1 (vencida) -> finalizada=1
      await db.execute('UPDATE marcas SET finalizada = CASE WHEN estado = 1 THEN 1 ELSE 0 END');
    }
  }

  // CATEGORÍAS
  Future<int> insertCategoria(Categoria categoria) async {
    final db = await database;
    return await db.insert('categorias', categoria.toMap());
  }

  Future<List<Categoria>> getCategorias() async {
    final db = await database;
    final maps = await db.query('categorias', orderBy: 'nombre ASC');
    return maps.map((map) => Categoria.fromMap(map)).toList();
  }

  Future<Categoria?> getCategoria(int id) async {
    final db = await database;
    final maps = await db.query(
      'categorias',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Categoria.fromMap(maps.first);
  }

  Future<int> updateCategoria(Categoria categoria) async {
    final db = await database;
    return await db.update(
      'categorias',
      categoria.toMap(),
      where: 'id = ?',
      whereArgs: [categoria.id],
    );
  }

  Future<int> deleteCategoria(int id) async {
    final db = await database;
    return await db.delete(
      'categorias',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // MARCAS
  Future<int> insertMarca(Marca marca) async {
    final db = await database;
    return await db.insert('marcas', marca.toMap());
  }

  Future<List<Marca>> getMarcas() async {
    final db = await database;
    final maps = await db.query('marcas', orderBy: 'fechaHora ASC');
    return maps.map((map) => Marca.fromMap(map)).toList();
  }

  Future<List<Marca>> getMarcasPorFecha(DateTime fecha) async {
    final db = await database;
    final inicioDelDia = DateTime(fecha.year, fecha.month, fecha.day);
    final finDelDia = inicioDelDia.add(const Duration(days: 1));
    
    final maps = await db.query(
      'marcas',
      where: 'fechaHora >= ? AND fechaHora < ?',
      whereArgs: [
        inicioDelDia.millisecondsSinceEpoch,
        finDelDia.millisecondsSinceEpoch,
      ],
      orderBy: 'fechaHora ASC',
    );
    return maps.map((map) => Marca.fromMap(map)).toList();
  }

  Future<Marca?> getMarca(int id) async {
    final db = await database;
    final maps = await db.query(
      'marcas',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Marca.fromMap(maps.first);
  }

  Future<int> updateMarca(Marca marca) async {
    final db = await database;
    return await db.update(
      'marcas',
      marca.toMap(),
      where: 'id = ?',
      whereArgs: [marca.id],
    );
  }

  Future<int> deleteMarca(int id) async {
    final db = await database;
    return await db.delete(
      'marcas',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Map<DateTime, int>> getContadorMarcasPorDia() async {
    final db = await database;
    final maps = await db.query('marcas');
    
    final Map<DateTime, int> contador = {};
    for (var map in maps) {
      final marca = Marca.fromMap(map);
      final fecha = DateTime(
        marca.fechaHora.year,
        marca.fechaHora.month,
        marca.fechaHora.day,
      );
      contador[fecha] = (contador[fecha] ?? 0) + 1;
    }
    return contador;
  }

  Future close() async {
    final db = await database;
    db.close();
  }
}