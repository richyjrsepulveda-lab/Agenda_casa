import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/models.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._init();
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  NotificationService._init();

  Future<void> initialize() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(settings);
    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _notifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  // Notificación inmediata
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'agenda_channel',
      'Agenda Notifications',
      channelDescription: 'Notificaciones de marcas y eventos',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(id, title, body, details);
  }

  // Programa notificaciones periódicas para una marca
  Future<void> schedulePeriodicNotifications({
    required Marca marca,
    required int intervaloMinutos,
    String? categoriaNombre,
  }) async {
    if (intervaloMinutos <= 0) return;

    await cancelNotificationsForMarca(marca.id!);

    final ahora = DateTime.now();
    final fechaLimite = marca.fechaHora;

    if (fechaLimite.isBefore(ahora)) return;

    // CAMBIO: Solo programar las próximas 10 notificaciones o hasta 7 días
    final maxDias = 7;
    final limiteCalculado = ahora.add(Duration(days: maxDias));
    final fechaMaxima = fechaLimite.isBefore(limiteCalculado) ? fechaLimite : limiteCalculado;
    
    final diferenciaMaxima = fechaMaxima.difference(ahora);
    final cantidadNotificaciones = (diferenciaMaxima.inMinutes / intervaloMinutos).ceil();
    final maxNotificaciones = 10; // Solo las próximas 10

    int notifCount = 0;
    for (int i = 1; i <= cantidadNotificaciones && notifCount < maxNotificaciones; i++) {
      final scheduledTime = ahora.add(Duration(minutes: intervaloMinutos * i));
      
      if (scheduledTime.isAfter(fechaMaxima)) break;

      final notificationId = _getNotificationId(marca.id!, i);
      
      try {
        await _notifications.zonedSchedule(
          notificationId,
          '⏰ ${marca.nombre}',
          marca.descripcion ?? 'Recordatorio de marca',
          tz.TZDateTime.from(scheduledTime, tz.local),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'agenda_periodic',
              'Recordatorios Periódicos',
              channelDescription: 'Notificaciones programadas de tus marcas',
              importance: Importance.high,
              priority: Priority.high,
              playSound: true,
              enableVibration: true,
            ),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        );
        notifCount++;
      } catch (e) {
        // Error programando notificación (silencioso)
      }
    }

    // Notificación final cuando vence
    await _scheduleFinalNotification(marca);
  }

  Future<void> _scheduleFinalNotification(Marca marca) async {
    final ahora = DateTime.now();
    if (marca.fechaHora.isBefore(ahora)) return;
    
    final notificationId = _getNotificationId(marca.id!, 9999);
    
    try {
      await _notifications.zonedSchedule(
        notificationId,
        '✅ ${marca.nombre} - TIEMPO VENCIDO',
        marca.descripcion ?? 'Esta marca ha llegado a su fecha límite',
        tz.TZDateTime.from(marca.fechaHora, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'agenda_final',
            'Marcas Vencidas',
            channelDescription: 'Notificación cuando una marca llega a su tiempo límite',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      // Error programando notificación final (silencioso)
    }
  }

  // Cancela todas las notificaciones de una marca
  Future<void> cancelNotificationsForMarca(int marcaId) async {
    try {
      // Cancelar notificaciones periódicas (hasta 100)
      for (int i = 0; i <= 100; i++) {
        await _notifications.cancel(_getNotificationId(marcaId, i));
      }
      // Cancelar notificación final
      await _notifications.cancel(_getNotificationId(marcaId, 9999));
    } catch (e) {
      // Error cancelando notificaciones (silencioso)
    }
  }

  // Genera un ID único para las notificaciones
  int _getNotificationId(int marcaId, int index) {
    return marcaId * 10000 + index;
  }

  // Notificaciones de eventos CRUD
  Future<void> notifyMarcaCreated(Marca marca) async {
    await showNotification(
      id: marca.id! * 10000,
      title: '✨ Marca creada',
      body: marca.nombre,
    );
  }

  Future<void> notifyMarcaUpdated(Marca marca) async {
    await showNotification(
      id: marca.id! * 10000,
      title: '📝 Marca modificada',
      body: marca.nombre,
    );
  }

  Future<void> notifyMarcaDeleted(String nombre) async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch % 100000,
      title: '🗑️ Marca eliminada',
      body: nombre,
    );
  }

  Future<void> notifyMarcaFinished(Marca marca) async {
    await showNotification(
      id: marca.id! * 10000,
      title: '✅ Marca finalizada',
      body: marca.nombre,
    );
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
  
  // MÉTODO DE PRUEBA: Notificación en 5 segundos
  Future<void> testNotification() async {
    final now = DateTime.now();
    final testTime = now.add(const Duration(seconds: 5));
    
    await _notifications.zonedSchedule(
      99999,
      '🧪 Prueba de Notificación',
      'Si ves esto, las notificaciones funcionan correctamente',
      tz.TZDateTime.from(testTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'test_channel',
          'Pruebas',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}