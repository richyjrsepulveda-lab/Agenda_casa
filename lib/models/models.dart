import 'package:flutter/material.dart';

enum TipoIntervalo { minutos, horas, dias }

class Categoria {
  final int? id;
  final String nombre;
  final int intervaloNotificacion; // Cantidad (ej: 30, 2, 1)
  final TipoIntervalo tipoIntervalo; // minutos, horas o días
  final String color; // Formato: "0xFFRRGGBB"

  Categoria({
    this.id,
    required this.nombre,
    required this.intervaloNotificacion,
    this.tipoIntervalo = TipoIntervalo.minutos,
    required this.color,
  });

  // Convierte a minutos para cálculos internos
  int get intervaloEnMinutos {
    switch (tipoIntervalo) {
      case TipoIntervalo.minutos:
        return intervaloNotificacion;
      case TipoIntervalo.horas:
        return intervaloNotificacion * 60;
      case TipoIntervalo.dias:
        return intervaloNotificacion * 24 * 60;
    }
  }

  Color get colorObj => Color(int.parse(color));

  String get intervaloTexto {
    if (intervaloNotificacion == 0) return 'Sin notificaciones';
    final tipo = tipoIntervalo == TipoIntervalo.minutos ? 'min' :
                 tipoIntervalo == TipoIntervalo.horas ? 'h' : 'd';
    return 'Cada $intervaloNotificacion$tipo';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'intervaloNotificacion': intervaloNotificacion,
      'tipoIntervalo': tipoIntervalo.index,
      'color': color,
    };
  }

  factory Categoria.fromMap(Map<String, dynamic> map) {
    return Categoria(
      id: map['id'],
      nombre: map['nombre'],
      intervaloNotificacion: map['intervaloNotificacion'],
      tipoIntervalo: TipoIntervalo.values[map['tipoIntervalo'] ?? 0],
      color: map['color'],
    );
  }

  Categoria copyWith({
    int? id,
    String? nombre,
    int? intervaloNotificacion,
    TipoIntervalo? tipoIntervalo,
    String? color,
  }) {
    return Categoria(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      intervaloNotificacion: intervaloNotificacion ?? this.intervaloNotificacion,
      tipoIntervalo: tipoIntervalo ?? this.tipoIntervalo,
      color: color ?? this.color,
    );
  }
}

class Marca {
  final int? id;
  final String nombre;
  final String? descripcion;
  final DateTime fechaHora;
  final int? categoriaId;
  final int? intervaloNotificacionPersonalizado; // En minutos
  final TipoIntervalo? tipoIntervaloPersonalizado;
  final bool finalizada;
  final DateTime fechaCreacion;

  Marca({
    this.id,
    required this.nombre,
    this.descripcion,
    required this.fechaHora,
    this.categoriaId,
    this.intervaloNotificacionPersonalizado,
    this.tipoIntervaloPersonalizado,
    this.finalizada = false,
    DateTime? fechaCreacion,
  }) : fechaCreacion = fechaCreacion ?? DateTime.now();

  // Calcula el color del borde según proximidad
  Color getBorderColor() {
    final ahora = DateTime.now();
    final diferencia = fechaHora.difference(ahora);
    
    if (diferencia.inDays <= 1) {
      return Colors.red;
    } else if (diferencia.inDays <= 4) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  // Obtiene el intervalo efectivo en minutos (personalizado o de categoría)
  int getIntervaloNotificacion(Categoria? categoria) {
    if (intervaloNotificacionPersonalizado != null && tipoIntervaloPersonalizado != null) {
      switch (tipoIntervaloPersonalizado!) {
        case TipoIntervalo.minutos:
          return intervaloNotificacionPersonalizado!;
        case TipoIntervalo.horas:
          return intervaloNotificacionPersonalizado! * 60;
        case TipoIntervalo.dias:
          return intervaloNotificacionPersonalizado! * 24 * 60;
      }
    }
    return categoria?.intervaloEnMinutos ?? 0;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'fechaHora': fechaHora.millisecondsSinceEpoch,
      'categoriaId': categoriaId,
      'intervaloNotificacionPersonalizado': intervaloNotificacionPersonalizado,
      'tipoIntervaloPersonalizado': tipoIntervaloPersonalizado?.index,
      'finalizada': finalizada ? 1 : 0,
      'fechaCreacion': fechaCreacion.millisecondsSinceEpoch,
    };
  }

  factory Marca.fromMap(Map<String, dynamic> map) {
    return Marca(
      id: map['id'],
      nombre: map['nombre'],
      descripcion: map['descripcion'],
      fechaHora: DateTime.fromMillisecondsSinceEpoch(map['fechaHora']),
      categoriaId: map['categoriaId'],
      intervaloNotificacionPersonalizado: map['intervaloNotificacionPersonalizado'],
      tipoIntervaloPersonalizado: map['tipoIntervaloPersonalizado'] != null 
          ? TipoIntervalo.values[map['tipoIntervaloPersonalizado']] 
          : null,
      finalizada: map['finalizada'] == 1,
      fechaCreacion: DateTime.fromMillisecondsSinceEpoch(map['fechaCreacion']),
    );
  }

  Marca copyWith({
    int? id,
    String? nombre,
    String? descripcion,
    DateTime? fechaHora,
    int? categoriaId,
    int? intervaloNotificacionPersonalizado,
    TipoIntervalo? tipoIntervaloPersonalizado,
    bool? finalizada,
    DateTime? fechaCreacion,
  }) {
    return Marca(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      fechaHora: fechaHora ?? this.fechaHora,
      categoriaId: categoriaId ?? this.categoriaId,
      intervaloNotificacionPersonalizado: intervaloNotificacionPersonalizado ?? this.intervaloNotificacionPersonalizado,
      tipoIntervaloPersonalizado: tipoIntervaloPersonalizado ?? this.tipoIntervaloPersonalizado,
      finalizada: finalizada ?? this.finalizada,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
    );
  }
}