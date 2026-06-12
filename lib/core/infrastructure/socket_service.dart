import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:assignum/core/infrastructure/auth_session.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  static const String _baseUrl = 'https://assignum-backend.onrender.com';

  io.Socket? _socket;

  final Set<String> _joinedRooms = {};
  final Map<String, void Function(String)> _activityListeners = {};
  final Map<String, void Function(String)> _taskListeners = {};

  // ── Connection ──────────────────────────────────────────────────────────────

  void connect() {
    final token = AuthSession().idToken;
    if (token == null) { debugPrint('[WS] connect() aborted — no token'); return; }
    if (_socket != null && _socket!.connected) { debugPrint('[WS] already connected'); return; }

    // Clean up old socket if disconnected
    if (_socket != null) {
      _socket!.dispose();
      _socket = null;
    }

    debugPrint('[WS] connecting to $_baseUrl ...');

    _socket = io.io(
      _baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .setAuth({'token': token})
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionDelay(3000)
          .setReconnectionAttempts(999)
          .setTimeout(30000)
          .build(),
    );

    _socket!
      ..onConnect((_) {
        debugPrint('[WS] ✅ connected  id=${_socket?.id}');
        _rejoinRooms();
      })
      ..on('reconnect', (_) {
        debugPrint('[WS] 🔄 reconnect event');
        _rejoinRooms();
      })
      ..onDisconnect((r) => debugPrint('[WS] ❌ disconnected  reason=$r'))
      ..onConnectError((e) => debugPrint('[WS] 🔴 connect_error  $e'))
      ..onError((e)        => debugPrint('[WS] 🔴 error  $e'))
      ..on('activity:updated', (data) {
        debugPrint('[WS] 📥 activity:updated  $data');
        final id = (data as Map)['activityId'] as String? ?? '';
        if (id.isEmpty) return;
        for (final h in List.of(_activityListeners.values)) { h(id); }
      })
      ..on('task:updated', (data) {
        debugPrint('[WS] 📥 task:updated  $data');
        final id = (data as Map)['activityId'] as String? ?? '';
        if (id.isEmpty) return;
        for (final h in List.of(_taskListeners.values)) { h(id); }
      })
      ..connect();
  }

  void _rejoinRooms() {
    for (final room in _joinedRooms) {
      debugPrint('[WS] re-joining room $room');
      _socket?.emit('join_activity', {'activityId': room});
    }
  }

  void disconnect() {
    debugPrint('[WS] disconnect()');
    _joinedRooms.clear();
    _socket?.dispose();
    _socket = null;
  }

  // ── Rooms ────────────────────────────────────────────────────────────────────

  void joinActivity(String activityId) {
    debugPrint('[WS] join_activity  $activityId');
    _joinedRooms.add(activityId);
    _socket?.emit('join_activity', {'activityId': activityId});
  }

  void leaveActivity(String activityId) {
    debugPrint('[WS] leave_activity  $activityId');
    _joinedRooms.remove(activityId);
    _socket?.emit('leave_activity', {'activityId': activityId});
  }

  // ── Listeners ─────────────────────────────────────────────────────────────

  void addActivityListener(String key, void Function(String activityId) handler) {
    _activityListeners[key] = handler;
  }

  void addTaskListener(String key, void Function(String activityId) handler) {
    _taskListeners[key] = handler;
  }

  void removeListener(String key) {
    _activityListeners.remove(key);
    _taskListeners.remove(key);
  }
}
