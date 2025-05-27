// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:notificacoes_locais/home_page.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

final StreamController<NotificationResponse> selectNotificationStream =
    StreamController<NotificationResponse>.broadcast();

const String portName = 'notification_send_port';

class ReceivedNotification {
  ReceivedNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.payload,
    this.data,
  });

  final int id;
  final String? title;
  final String? body;
  final String? payload;
  final Map<String, dynamic>? data;
}

String? selectedNotificationPayload;

/// A notification action which triggers a url launch event
const String urlLaunchActionId = 'id_1';

/// A notification action which triggers a App navigation event
const String navigationActionId = 'id_3';

/// Defines a iOS/MacOS notification category for text input actions.
const String darwinNotificationCategoryText = 'textCategory';

/// Defines a iOS/MacOS notification category for plain actions.
const String darwinNotificationCategoryPlain = 'plainCategory';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  print(
    'notification(${notificationResponse.id}) action tapped: '
    '${notificationResponse.actionId} with'
    ' payload: ${notificationResponse.payload}',
  );
  if (notificationResponse.input?.isNotEmpty ?? false) {
    print(
      'notification action tapped with input: ${notificationResponse.input}',
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Inicialize apenas uma vez

  await _configureLocalTimeZone();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  final List<DarwinNotificationCategory> darwinNotificationCategories =
      <DarwinNotificationCategory>[
        DarwinNotificationCategory(
          darwinNotificationCategoryText,
          actions: <DarwinNotificationAction>[
            DarwinNotificationAction.text(
              'text_1',
              'Action 1',
              buttonTitle: 'Send',
              placeholder: 'Placeholder',
            ),
          ],
        ),
        DarwinNotificationCategory(
          darwinNotificationCategoryPlain,
          actions: <DarwinNotificationAction>[
            DarwinNotificationAction.plain('id_1', 'Action 1'),
            DarwinNotificationAction.plain(
              'id_2',
              'Action 2 (destructive)',
              options: <DarwinNotificationActionOption>{
                DarwinNotificationActionOption.destructive,
              },
            ),
            DarwinNotificationAction.plain(
              navigationActionId,
              'Action 3 (foreground)',
              options: <DarwinNotificationActionOption>{
                DarwinNotificationActionOption.foreground,
              },
            ),
            DarwinNotificationAction.plain(
              'id_4',
              'Action 4 (auth required)',
              options: <DarwinNotificationActionOption>{
                DarwinNotificationActionOption.authenticationRequired,
              },
            ),
          ],
          options: <DarwinNotificationCategoryOption>{
            DarwinNotificationCategoryOption.hiddenPreviewShowTitle,
          },
        ),
      ];

  final DarwinInitializationSettings initializationSettingsDarwin =
      DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
        notificationCategories: darwinNotificationCategories,
      );

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsDarwin,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: selectNotificationStream.add,
    onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
  );

  runApp(MainApp());
}

Future<void> _configureLocalTimeZone() async {
  tz.initializeTimeZones();
  final String timeZoneName = await FlutterTimezone.getLocalTimezone();
  print('Timezone from FlutterTimezone: $timeZoneName');
  try {
    tz.setLocalLocation(tz.getLocation(timeZoneName));
    print('tz.local successfully set to: ${tz.local.name}');
  } catch (e) {
    print('Error setting local location with timezone "$timeZoneName": $e');
    print('Falling back to UTC for timezone.');
    tz.setLocalLocation(tz.getLocation('Etc/UTC')); // Fallback seguro
  }
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {

  bool? _notificationsEnabled = false;
  int numeroPendentes = 0;
  int id = 0; // Variável para o ID da notificação com ações
  int _mainScheduledNotificationIdCounter = 100; // ID base para agendamentos de main.dart

  TextEditingController titulo = TextEditingController();
  TextEditingController descricao = TextEditingController();

  @override
  void initState() {
    super.initState();
    _isAndroidPermissionGranted();
    _requestPermissions();
    _checarPermissao();
    _pendingNotifications();
    _requestExactAlarmPermission(); // Solicitar permissão para alarmes exatos
    
  }

  Future<void> _checarPermissao() async {
    _notificationsEnabled =
        await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.areNotificationsEnabled();
  }

  Future<void> _isAndroidPermissionGranted() async {
    if (Platform.isAndroid) {
      final bool granted =
          await flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.areNotificationsEnabled() ??
          false;

      setState(() {
        _notificationsEnabled = granted;
      });
    }
  }

  Future<void> _requestPermissions() async {
    if (Platform.isIOS) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } else if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      final bool? grantedNotificationPermission =
          await androidImplementation?.requestNotificationsPermission();
      setState(() {
        _notificationsEnabled = grantedNotificationPermission ?? false;
      });
    }
  }

  Future _pendingNotifications() async {
    final List<PendingNotificationRequest> pendingNotification = await flutterLocalNotificationsPlugin.pendingNotificationRequests();
    numeroPendentes = pendingNotification.length;

  }

  Future<void> _requestExactAlarmPermission() async {
    if (Platform.isAndroid) {
      final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      // A permissão SCHEDULE_EXACT_ALARM é necessária para Android 12 (SDK 31) e superior.
      // A permissão USE_EXACT_ALARM é uma permissão de tempo de execução para Android 13 (SDK 33) e superior.
      // permission_handler lida com isso através de Permission.scheduleExactAlarm.
      if (androidInfo.version.sdkInt >= 31) { // SDK_INT for S is 31
        var status = await Permission.scheduleExactAlarm.request();
        if (status.isGranted) {
          print('Permissão para alarmes exatos concedida.');
        } else if (status.isDenied) {
          print('Permissão para alarmes exatos negada.');
        } else if (status.isPermanentlyDenied) {
          print('Permissão para alarmes exatos permanentemente negada. Abra as configurações do aplicativo para conceder.');
          await openAppSettings();
        }
      }
    }
  }

  void notificar() {
    if (titulo.text.isNotEmpty && descricao.text.isNotEmpty) {
      showNotification(titulo.text, descricao.text);
    } else {
      showNotification("irado", "conteudo irado");
    }
  }

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }

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

  Future<void> showNotificationWithActions() async {
    const AndroidNotificationDetails
    androidNotificationDetails = AndroidNotificationDetails(
      'your channel id',
      'your channel name',
      channelDescription: 'your channel description',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          urlLaunchActionId,
          'Action 1',
          icon: DrawableResourceAndroidBitmap('food'),
          contextual: true,
        ),
        AndroidNotificationAction(
          'id_2',
          'Action 2',
          titleColor: Color.fromARGB(255, 255, 0, 0),
          icon: DrawableResourceAndroidBitmap('secondary_icon'),
        ),
        AndroidNotificationAction(
          navigationActionId,
          'Action 3',
          icon: DrawableResourceAndroidBitmap('secondary_icon'),
          showsUserInterface: true,
          // By default, Android plugin will dismiss the notification when the
          // user tapped on a action (this mimics the behavior on iOS).
          cancelNotification: false,
        ),
      ],
    );

    const DarwinNotificationDetails iosNotificationDetails =
        DarwinNotificationDetails(
          categoryIdentifier: darwinNotificationCategoryPlain,
        );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
    );
    await flutterLocalNotificationsPlugin.show(
      id++,
      'plain title',
      'plain body',
      notificationDetails,
      payload: 'item z',
    );
  }
}