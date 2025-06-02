// ignore_for_file: avoid_print

import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:notificacoes_locais/main.dart'
    show flutterLocalNotificationsPlugin;
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    show
        PendingNotificationRequest,
        ActiveNotification,
        // AndroidNotificationDetails,
        // NotificationDetails,
        // AndroidScheduleMode,
        // DarwinNotificationDetails,
        Person,
        DrawableResourceAndroidIcon,
        ContentUriAndroidIcon,
        MessagingStyleInformation,
        Message,
        AndroidFlutterLocalNotificationsPlugin;
        // Importance,
        // Priority; // Importa apenas os tipos necessários
import 'package:notificacoes_locais/noti_service.dart';
// import 'package:timezone/timezone.dart' as tz;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // int _scheduledNotificationIdCounter = 1; // Para IDs únicos ao agendar

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                NotificationService().showNotification(
                  "irado",
                  "conteudo irado",
                );
              },
              child: Text("Notificação normal"),
            ),
            ElevatedButton(
              onPressed: () async {
                await NotificationService().zonedScheduleNotification();
              },
              child: Text("Notificação agendada"),
            ),
            ElevatedButton(
              onPressed: _checkPendingNotificationRequests,
              child: Text("Ver notifs pendentes"),
            ),
            ElevatedButton(
              onPressed: _getActiveNotifications,
              child: Text("Pegar notifs ativas"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _checkPendingNotificationRequests() async {
    final List<PendingNotificationRequest> pendingNotificationRequests =
        await flutterLocalNotificationsPlugin.pendingNotificationRequests();
    return showDialog<void>(
      context: context,
      builder:
          (BuildContext context) => AlertDialog(
            content: Text(
              '${pendingNotificationRequests.length} pending notification '
              'requests',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  Future<void> _getActiveNotifications() async {
    final Widget activeNotificationsDialogContent =
        await _getActiveNotificationsDialogContent();
    await showDialog<void>(
      context: context,
      builder:
          (BuildContext context) => AlertDialog(
            content: activeNotificationsDialogContent,
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  Future<Widget> _getActiveNotificationsDialogContent() async {
    if (Platform.isAndroid) {
      final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      if (androidInfo.version.sdkInt < 23) {
        return const Text(
          '"getActiveNotifications" is available only for Android 6.0 or newer',
        );
      }
    } else if (Platform.isIOS) {
      final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      final IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      final List<String> fullVersion = iosInfo.systemVersion.split('.');
      if (fullVersion.isNotEmpty) {
        final int? version = int.tryParse(fullVersion[0]);
        if (version != null && version < 10) {
          return const Text(
            '"getActiveNotifications" is available only for iOS 10.0 or newer',
          );
        }
      }
    }

    try {
      final List<ActiveNotification>? activeNotifications =
          await flutterLocalNotificationsPlugin.getActiveNotifications();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text(
            'Active Notifications',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const Divider(color: Colors.black),
          if (activeNotifications!.isEmpty)
            const Text('No active notifications'),
          if (activeNotifications.isNotEmpty)
            for (final ActiveNotification activeNotification
                in activeNotifications)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'id: ${activeNotification.id}\n'
                    'channelId: ${activeNotification.channelId}\n'
                    'groupKey: ${activeNotification.groupKey}\n'
                    'tag: ${activeNotification.tag}\n'
                    'title: ${activeNotification.title}\n'
                    'body: ${activeNotification.body}',
                  ),
                  if (Platform.isAndroid &&
                      activeNotification.id != null) ...<Widget>[
                    Text('bigText: ${activeNotification.bigText}'),
                    TextButton(
                      child: const Text('Get messaging style'),
                      onPressed: () {
                        _getActiveNotificationMessagingStyle(
                          activeNotification.id!,
                          activeNotification.tag,
                        );
                      },
                    ),
                  ],
                  const Divider(color: Colors.black),
                ],
              ),
        ],
      );
    } on PlatformException catch (error) {
      return Text(
        'Error calling "getActiveNotifications"\n'
        'code: ${error.code}\n'
        'message: ${error.message}',
      );
    }
  }

  Future<void> _getActiveNotificationMessagingStyle(int id, String? tag) async {
    Widget dialogContent;
    try {
      final MessagingStyleInformation? messagingStyle =
          await flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()!
              .getActiveNotificationMessagingStyle(id, tag: tag);
      if (messagingStyle == null) {
        dialogContent = const Text('No messaging style');
      } else {
        dialogContent = SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'person: ${_formatPerson(messagingStyle.person)}\n'
                'conversationTitle: ${messagingStyle.conversationTitle}\n'
                'groupConversation: ${messagingStyle.groupConversation}',
              ),
              const Divider(color: Colors.black),
              if (messagingStyle.messages == null) const Text('No messages'),
              if (messagingStyle.messages != null)
                for (final Message msg in messagingStyle.messages!)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'text: ${msg.text}\n'
                        'timestamp: ${msg.timestamp}\n'
                        'person: ${_formatPerson(msg.person)}',
                      ),
                      const Divider(color: Colors.black),
                    ],
                  ),
            ],
          ),
        );
      }
    } on PlatformException catch (error) {
      dialogContent = Text(
        'Error calling "getActiveNotificationMessagingStyle"\n'
        'code: ${error.code}\n'
        'message: ${error.message}',
      );
    }

    await showDialog<void>(
      context: context,
      builder:
          (BuildContext context) => AlertDialog(
            title: const Text('Messaging style'),
            content: dialogContent,
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  String _formatPerson(Person? person) {
    if (person == null) {
      return 'null';
    }

    final List<String> attrs = <String>[];
    if (person.name != null) {
      attrs.add('name: "${person.name}"');
    }
    if (person.uri != null) {
      attrs.add('uri: "${person.uri}"');
    }
    if (person.key != null) {
      attrs.add('key: "${person.key}"');
    }
    if (person.important) {
      attrs.add('important: true');
    }
    if (person.bot) {
      attrs.add('bot: true');
    }
    if (person.icon != null) {
      attrs.add('icon: ${_formatAndroidIcon(person.icon)}');
    }
    return 'Person(${attrs.join(', ')})';
  }

  String _formatAndroidIcon(Object? icon) {
    if (icon == null) {
      return 'null';
    }
    if (icon is DrawableResourceAndroidIcon) {
      return 'DrawableResourceAndroidIcon("${icon.data}")';
    } else if (icon is ContentUriAndroidIcon) {
      return 'ContentUriAndroidIcon("${icon.data}")';
    } else {
      return 'AndroidIcon()';
    }
  }
}
