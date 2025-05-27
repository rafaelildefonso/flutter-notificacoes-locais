import 'dart:async';

import 'package:notificacoes_locais/main.dart' show flutterLocalNotificationsPlugin;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final StreamController<NotificationResponse> selectNotificationStream =
    StreamController<NotificationResponse>.broadcast();

class NotificationService {

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

  Future<void> zonedScheduleNotifications(String titulo, String conteudo) async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      titulo,
      conteudo,
      tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5)),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'your channel id',
          'your channel name',
          channelDescription: 'your channel descriptions',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }
}