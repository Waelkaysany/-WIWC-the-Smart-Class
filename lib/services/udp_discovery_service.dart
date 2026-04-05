import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Listens for UDP broadcast packets from the ESP32.
///
/// The ESP32 sends: "WIWC_ESP32:{ip_address}"  every 3 seconds on port 4210.
/// When received, [onDiscovered] is called with the IP address string.
class UdpDiscoveryService {
  static const int _port = 4210;
  static const String _prefix = 'WIWC_ESP32:';

  RawDatagramSocket? _socket;
  Timer? _timeoutTimer;
  bool _isRunning = false;

  /// Start listening. Calls [onDiscovered] when an ESP32 is found.
  /// Calls [onTimeout] after [timeoutSeconds] if nothing is found.
  Future<void> startListening({
    required void Function(String ipAddress) onDiscovered,
    void Function()? onTimeout,
    int timeoutSeconds = 15,
  }) async {
    if (_isRunning) return;
    _isRunning = true;

    try {
      // Bind to all interfaces on the discovery port
      _socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        _port,
        reusePort: true,
      );

      debugPrint('[Discovery] Listening for ESP32 on UDP port $_port ...');

      _socket!.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final datagram = _socket!.receive();
          if (datagram == null) return;

          final message = String.fromCharCodes(datagram.data).trim();
          debugPrint('[Discovery] Received: $message');

          if (message.startsWith(_prefix)) {
            final ip = message.substring(_prefix.length).trim();
            if (ip.isNotEmpty) {
              _timeoutTimer?.cancel();
              stopListening();
              onDiscovered(ip);
            }
          }
        }
      });

      // Timeout if nothing is found
      if (onTimeout != null) {
        _timeoutTimer = Timer(Duration(seconds: timeoutSeconds), () {
          stopListening();
          onTimeout();
        });
      }
    } catch (e) {
      debugPrint('[Discovery] Error binding UDP: $e');
      _isRunning = false;
    }
  }

  /// Stop listening and release the socket.
  void stopListening() {
    _timeoutTimer?.cancel();
    _socket?.close();
    _socket = null;
    _isRunning = false;
  }

  bool get isRunning => _isRunning;
}
