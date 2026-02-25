import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class TimerNotificationService {
  static final TimerNotificationService _instance = TimerNotificationService._internal();
  factory TimerNotificationService() => _instance;
  TimerNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  Timer? _updateTimer;
  int _currentSeconds = 0;
  bool _isRunning = false;

  static const String _channelId = 'bowel_timer_channel';
  static const String _channelName = '排便计时器';
  static const String _channelDescription = '显示排便计时器状态';
  static const int _notificationId = 1001;

  Future<void> initialize() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    _isInitialized = true;
  }

  void _onNotificationResponse(NotificationResponse response) {
    if (response.actionId == 'stop_timer') {
      stopTimer();
    }
  }

  Future<void> startTimer() async {
    await initialize();
    _currentSeconds = 0;
    _isRunning = true;

    await _showNotification();

    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isRunning) {
        _currentSeconds++;
        _updateNotification();
      }
    });
  }

  Future<void> stopTimer() async {
    _isRunning = false;
    _updateTimer?.cancel();
    await _cancelNotification();
  }

  Future<void> _showNotification() async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      showWhen: false,
      playSound: false,
      enableVibration: false,
      actions: [
        AndroidNotificationAction(
          'stop_timer',
          '停止计时',
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: false,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      _notificationId,
      '排便计时中',
      _formatTime(_currentSeconds),
      details,
    );
  }

  Future<void> _updateNotification() async {
    if (!_isRunning) return;

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      showWhen: false,
      playSound: false,
      enableVibration: false,
      onlyAlertOnce: true,
      actions: [
        AndroidNotificationAction(
          'stop_timer',
          '停止计时',
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: false,
      presentBadge: false,
      presentSound: false,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      _notificationId,
      '排便计时中',
      _formatTime(_currentSeconds),
      details,
    );
  }

  Future<void> _cancelNotification() async {
    await _notifications.cancel(_notificationId);
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  int get currentSeconds => _currentSeconds;
  bool get isRunning => _isRunning;
}
