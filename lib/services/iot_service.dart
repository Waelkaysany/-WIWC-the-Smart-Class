import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Service for communicating with the ESP32 IoT unit over local WiFi HTTP.
///
/// The ESP32 exposes two endpoints:
///   GET /data     → returns full sensor + device JSON
///   GET /control  → controls a device
///     ?device=light_1|light_2|window_left|window_right|door
///     &state=on|off
///     &brightness=0.0-1.0  (lights only)
class IotService {
  final String ipAddress;

  IotService({required this.ipAddress});

  String get _baseUrl => 'http://$ipAddress';

  // ── Read all sensor data from ESP32 ──────────────────────────────────────

  /// Fetches sensor + device status from the ESP32.
  /// Returns a Map with keys: temp, hum, light, fire, studentsPresent,
  ///   lastUser, lastUID, devices { light_1, light_2, window_left, window_right, door }
  Future<Map<String, dynamic>> fetchData() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/data'))
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Bad status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('ESP32 connection error: $e');
    }
  }

  // ── Send a control command to a specific device ───────────────────────────

  /// Sends a control command to the ESP32.
  ///
  /// [deviceId]  — one of: light_1, light_2, window_left, window_right, door
  /// [isOn]      — true = turn on / open | false = turn off / close
  /// [brightness]— optional 0.0–1.0 for lights
  ///
  /// Returns true if the command was accepted by the ESP32.
  Future<bool> sendCommand(
    String deviceId, {
    required bool isOn,
    double? brightness,
  }) async {
    try {
      // Build query parameters using the ESP32's expected format
      final params = <String, String>{
        'device': deviceId,
        'state': isOn ? 'on' : 'off',
      };
      if (brightness != null) {
        params['brightness'] = brightness.toStringAsFixed(2);
      }

      final uri =
          Uri.parse('$_baseUrl/control').replace(queryParameters: params);
      final response =
          await http.get(uri).timeout(const Duration(seconds: 4));

      return response.statusCode == 200;
    } catch (e) {
      // Log but don't crash — the app can keep working offline
      debugPrint('IoT command error [$deviceId]: $e');
      return false;
    }
  }

  // ── Convenience helpers ───────────────────────────────────────────────────

  Future<bool> toggleLight(String id, bool isOn, {double brightness = 1.0}) =>
      sendCommand(id, isOn: isOn, brightness: brightness);

  Future<bool> toggleWindow(bool open) =>
      sendCommand('window_left', isOn: open);

  Future<bool> toggleDoor(bool open) =>
      sendCommand('door', isOn: open);
}
