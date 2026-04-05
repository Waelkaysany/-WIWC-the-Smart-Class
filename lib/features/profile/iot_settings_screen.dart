import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../../state/providers.dart';
import '../../services/udp_discovery_service.dart';
import '../../main.dart';

/// Shows the IoT connection state and auto-discovers the ESP32.
/// The teacher never needs to type an IP address.
class IotSettingsScreen extends ConsumerStatefulWidget {
  const IotSettingsScreen({super.key});

  @override
  ConsumerState<IotSettingsScreen> createState() => _IotSettingsScreenState();
}

class _IotSettingsScreenState extends ConsumerState<IotSettingsScreen> {
  final UdpDiscoveryService _discovery = UdpDiscoveryService();
  late final TextEditingController _ipController;

  String _status      = 'idle';   // idle | searching | found | timeout | testing
  String _statusText  = 'Tap "Auto-Detect" to find your ESP32 on the network.';
  String? _testResult;

  @override
  void initState() {
    super.initState();
    // Initialize with current IP from provider
    _ipController = TextEditingController(text: ref.read(iotIpProvider));
  }

  @override
  void dispose() {
    _discovery.stopListening();
    _ipController.dispose();
    super.dispose();
  }

  // ── Auto-discover the ESP32 IP via UDP broadcast ──────────────────────────

  Future<void> _startDiscovery() async {
    setState(() {
      _status    = 'searching';
      _statusText = 'Scanning for ESP32 on your network…';
      _testResult = null;
    });

    await _discovery.startListening(
      onDiscovered: (ip) {
        // Update the global IP provider — all HTTP requests now go to this IP
        ref.read(iotIpProvider.notifier).state = ip;
        prefs.setString('iot_ip', ip); // Persist across app restarts

        if (mounted) {
          setState(() {
            _status    = 'found';
            _statusText = '✅ ESP32 found at $ip — connecting…';
            _ipController.text = ip;
          });
        }

        // Auto-test immediately
        _testConnection();
      },
      onTimeout: () {
        if (mounted) {
          setState(() {
            _status    = 'timeout';
            _statusText = '⚠️ Could not find ESP32.\n'
                'Make sure your phone and ESP32 are on the same WiFi network.';
          });
        }
      },
    );
  }

  // ── Test the current IP by fetching /data ────────────────────────────────

  Future<void> _testConnection() async {
    setState(() {
      _status    = 'testing';
      _testResult = null;
    });

    try {
      final iotService = ref.read(iotServiceProvider);
      final data       = await iotService.fetchData();

      final temp = data['temp'];
      final hum  = data['hum'];

      setState(() {
        _status    = 'found';
        _testResult = 'Connected! Temp: ${temp}°C, Humidity: ${hum}%';
      });
    } catch (e) {
      debugPrint('Test failed: $e');
      setState(() {
        _status     = 'timeout';
        _testResult = 'Connection failed — check WiFi and ESP32 firmware.';
      });
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final ip = ref.watch(iotIpProvider);

    final bool isSearching = _status == 'searching' || _status == 'testing';
    final bool isConnected = _status == 'found';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'IoT Connectivity',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Status Card ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isConnected
                    ? Colors.green.withValues(alpha: 0.1)
                    : isSearching
                        ? Colors.blue.withValues(alpha: 0.08)
                        : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isConnected
                      ? Colors.green.withValues(alpha: 0.3)
                      : isSearching
                          ? Colors.blue.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                children: [
                  if (isSearching)
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.blue,
                      ),
                    )
                  else
                    Icon(
                      isConnected ? Icons.wifi : Icons.wifi_off,
                      color: isConnected ? Colors.green : Colors.grey,
                      size: 28,
                    ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isConnected
                              ? 'Connected to ESP32'
                              : isSearching
                                  ? 'Searching…'
                                  : 'Not Connected',
                          style: TextStyle(
                            color: isConnected
                                ? Colors.green
                                : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ip.isNotEmpty ? 'IP: $ip' : _statusText,
                          style: TextStyle(
                            color: Colors.blueGrey.shade300,
                            fontSize: 13,
                          ),
                        ),
                        if (_statusText.isNotEmpty && ip.isNotEmpty)
                          Text(
                            _statusText,
                            style: TextStyle(
                              color: Colors.blueGrey.shade400,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Manual IP Configuration ───────────────────────────────────
            const Text(
              'Manual IP Configuration',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ipController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'ESP32 IP Address',
                labelStyle: TextStyle(color: Colors.blueGrey.shade400),
                hintText: 'e.g., 192.168.1.100',
                hintStyle: TextStyle(color: Colors.blueGrey.shade600),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.save, color: Colors.blueAccent),
                  onPressed: () {
                    final ip = _ipController.text.trim();
                    if (ip.isNotEmpty) {
                      ref.read(iotIpProvider.notifier).state = ip;
                      prefs.setString('iot_ip', ip);
                      _testConnection();
                    }
                  },
                ),
              ),
              onSubmitted: (value) {
                final ip = value.trim();
                if (ip.isNotEmpty) {
                  ref.read(iotIpProvider.notifier).state = ip;
                  prefs.setString('iot_ip', ip);
                  _testConnection();
                }
              },
            ),

            const SizedBox(height: 24),

            // ── Auto-Detect Button ────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isSearching ? null : _startDiscovery,
                icon: const Icon(Icons.radar),
                label: isSearching
                    ? const Text('Searching for ESP32…')
                    : const Text('Auto-Detect ESP32'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Test Connection Button (shown when IP is known) ───────────
            if (ip.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: isSearching ? null : _testConnection,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Test Connection'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

            // ── Test Result ───────────────────────────────────────────────
            if (_testResult != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _testResult!.startsWith('Connected')
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _testResult!.startsWith('Connected')
                        ? Colors.green.withValues(alpha: 0.3)
                        : Colors.red.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _testResult!.startsWith('Connected')
                          ? Icons.check_circle
                          : Icons.error_outline,
                      color: _testResult!.startsWith('Connected')
                          ? Colors.green
                          : Colors.red,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _testResult!,
                        style: TextStyle(
                          color: _testResult!.startsWith('Connected')
                              ? Colors.green.shade300
                              : Colors.red.shade300,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const Spacer(),

            // ── Info Box ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline,
                      color: Colors.blueAccent, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Make sure your phone is on the same WiFi as the ESP32. '
                      'The ESP32 broadcasts its address every 3 seconds automatically.',
                      style: TextStyle(
                        color: Colors.blueGrey.shade400,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
