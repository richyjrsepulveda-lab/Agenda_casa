import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import '../models/models.dart';
import '../services/notification_service.dart';

class AppProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final NotificationService _notifications = NotificationService.instance;

  List<Categoria> _categorias = [];
  List<Marca> _marcas = [];
  Map<DateTime, int> _contadorMarcasPorDia = {};
  bool _isDarkMode = false;

  List<Categoria> get categorias => _categorias;
  List<Marca> get marcas => _marcas;
  Map<DateTime, int> get contadorMarcasPorDia => _contadorMarcasPorDia;
  bool get isDarkMode => _isDarkMode;

  AppProvider() {
    _loadTheme();
    loadData();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('darkMode') ?? false;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', _isDarkMode);
    notifyListeners();
  }

  Future<void> loadData() async {
    _categorias = await _db.getCategorias();
    _marcas = await _db.getMarcas();
    _contadorMarcasPorDia = await _db.getContadorMarcasPorDia();
    notifyListeners();
  }

  // CATEGORÍAS
  Future<void> addCategoria(Categoria categoria) async {
    await _db.insertCategoria(categoria);
    await loadData();
  }

  Future<void> updateCategoria(Categoria categoria) async {
    await _db.updateCategoria(categoria);
    await loadData();
    
    // Reprograma las notificaciones de marcas afectadas que NO estén finalizadas
    final marcasAfectadas = _marcas.where(
      (m) => m.categoriaId == categoria.id && 
             m.intervaloNotificacionPersonalizado == null &&
             !m.finalizada
    );
    
    for (var marca in marcasAfectadas) {
      await _reprogramarNotificaciones(marca);
    }
  }

  Future<void> deleteCategoria(int id) async {
    await _db.deleteCategoria(id);
    await loadData();
  }

  // MARCAS
  Future<void> addMarca(Marca marca) async {
    final id = await _db.insertMarca(marca);
    await loadData();
    
    final marcaGuardada = await _db.getMarca(id);
    if (marcaGuardada != null && !marcaGuardada.finalizada) {
      await _reprogramarNotificaciones(marcaGuardada);
      await _notifications.notifyMarcaCreated(marcaGuardada);
    }
  }

  Future<void> updateMarca(Marca marca) async {
    // Actualizar UI optimistamente
    final index = _marcas.indexWhere((m) => m.id == marca.id);
    if (index != -1) {
      _marcas[index] = marca;
    }
    notifyListeners();
    
    await _db.updateMarca(marca);
    
    // Si se finaliza, cancelar notificaciones
    if (marca.finalizada) {
      _notifications.cancelNotificationsForMarca(marca.id!);
      _notifications.notifyMarcaFinished(marca);
    } else {
      // Si no está finalizada, reprogramar notificaciones
      await _reprogramarNotificaciones(marca);
      _notifications.notifyMarcaUpdated(marca);
    }
    
    await loadData();
  }

  Future<void> deleteMarca(int id) async {
    final marca = await _db.getMarca(id);
    if (marca != null) {
      // Primero actualizar UI optimistamente
      _marcas.removeWhere((m) => m.id == id);
      notifyListeners();
      
      // Luego hacer las operaciones en background
      await _db.deleteMarca(id);
      _notifications.cancelNotificationsForMarca(id);
      _notifications.notifyMarcaDeleted(marca.nombre);
      
      // Recargar para sincronizar
      await loadData();
    }
  }

  Future<void> finalizarMarca(int id) async {
    final marca = await _db.getMarca(id);
    if (marca != null) {
      final marcaFinalizada = marca.copyWith(finalizada: true);
      await updateMarca(marcaFinalizada);
    }
  }

  Future<void> _reprogramarNotificaciones(Marca marca) async {
    Categoria? categoria;
    if (marca.categoriaId != null) {
      categoria = await _db.getCategoria(marca.categoriaId!);
    }
    
    final intervalo = marca.getIntervaloNotificacion(categoria);
    
    if (intervalo > 0) {
      await _notifications.schedulePeriodicNotifications(
        marca: marca,
        intervaloMinutos: intervalo,
        categoriaNombre: categoria?.nombre,
      );
    }
  }

  Categoria? getCategoriaById(int? id) {
    if (id == null) return null;
    try {
      return _categorias.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<List<Marca>> getMarcasDelDia(DateTime fecha) async {
    return await _db.getMarcasPorFecha(fecha);
  }
}