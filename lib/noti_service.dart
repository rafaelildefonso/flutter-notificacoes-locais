// ignore_for_file: avoid_print

import 'dart:async';

import 'package:notificacoes_locais/main.dart'
    show flutterLocalNotificationsPlugin;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final StreamController<NotificationResponse> selectNotificationStream =
    StreamController<NotificationResponse>.broadcast();

class NotificationService {
  int _scheduledNotificationIdCounter = 1; // Para IDs únicos ao agendar

  Future<void> showNotification(String titulo, String conteudo) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          'your channel id',
          'your channel name',
          channelDescription: 'your channel description',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
        );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidNotificationDetails,
      iOS: DarwinNotificationDetails(),
    );
    print("Tentando exibir notificação...");
    try {
      await flutterLocalNotificationsPlugin.show(
        0,
        titulo,
        conteudo,
        platformChannelSpecifics,
        payload: 'item x',
      );
      print("Notificação enviada com sucesso!");
    } catch (e) {
      print("Erro ao enviar notificação: $e");
    }
  }

  Future<void> zonedScheduleNotification() async {
    print("agendando notificação...");
    final tz.TZDateTime scheduledTime = tz.TZDateTime.now(
      tz.local,
    ).add(const Duration(seconds: 15));
    // It's good practice to use a specific channel ID for scheduled notifications
    // or ensure 'your channel id' is created with high importance.
    const String channelId = 'scheduled_notification_channel';
    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        _scheduledNotificationIdCounter++, // Usar um ID único
        'irado agendado',
        'corpo irado agendado',
        scheduledTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            channelId, // Use a consistent or specific channel ID
            'Notificações Agendadas',
            channelDescription: 'Canal para notificações agendadas.',
            importance: Importance.max, // Crucial for visibility
            priority: Priority.high, // Crucial for visibility
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      print(
        "logged.dart: flutterLocalNotificationsPlugin.zonedSchedule CONCLUÍDO com sucesso.",
      );
      print(
        "logged.dart: Notificação agendada para ${scheduledTime.toIso8601String()} no fuso ${tz.local.name}",
      );
    } catch (e, s) {
      print('LOGGED_PAGE: ERRO DETALHADO ao agendar notificação: $e');
      print('LOGGED_PAGE: StackTrace do ERRO: $s');
    }
  }
}
