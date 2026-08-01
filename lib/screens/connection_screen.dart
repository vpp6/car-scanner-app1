import 'dart:async';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../models/device.dart';
import '../services/obd/obd_models.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  bool _finding = false;
  final List<ObdAdapter> _found = [];
  StreamSubscription<ObdAdapter>? _scanSub;
  ObdAdapter? _connecting;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    if (Theme.of(context).platform == TargetPlatform.android) {
      await Permission.location.request();
      await Permission.bluetoothScan.request();
      await Permission.bluetoothConnect.request();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('الاتصال بالجهاز')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(
                    Icons.bluetooth_searching,
                    size: 56,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'وحدة OBD-II (ELM327)',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'اتصال بلوتوث حقيقي بقارئ الفحص - يجب تركيب القارئ في منفذ OBD-II بالسيارة',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (state.status == DeviceStatus.connecting ||
                      _connecting != null)
                    const Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'جاري الاتصال وتهيئة وحدة ELM327...',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    )
                  else ...[
                    const SizedBox(height: 4),
                    OutlinedButton.icon(
                      onPressed: _finding ? null : _startScan,
                      icon: _finding
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.search),
                      label: Text(
                          _finding ? 'جاري البحث عن الأجهزة...' : 'مسح الأجهزة المتاحة'),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (state.error.isNotEmpty) ...[
            const SizedBox(height: 12),
            Card(
              color: AppColors.danger.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: AppColors.danger),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  state.error,
                  style: const TextStyle(color: AppColors.danger),
                ),
              ),
            ),
          ],
          if (_found.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'الأجهزة المكتشفة:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            ..._found.map(_deviceTile),
          ],
          const SizedBox(height: 20),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ملاحظات مهمة للاختبار الميداني:',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '• شغّل السيارة أو ضع المفتاح على وضع الإشعال قبل المسح.\n'
                    '• قارئ ELM327 يتصل عبر البلوتوث فقط (لا USB/WiFi).\n'
                    '• على الآيفون يجب أن يكون القارئ من نوع BLE (بلوتوث 4.0/5.0).\n'
                    '• إن لم يظهر الجهاز، تحقق من إضاءة القارئ وقربه من الهاتف.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.7,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startScan() async {
    await _requestPermissions();
    if (!mounted) return;
    setState(() {
      _finding = true;
      _found.clear();
    });
    final state = context.read<AppState>();
    _scanSub?.cancel();
    _scanSub = state.scanDevices().listen(
      (adapter) {
        if (!mounted) return;
        setState(() {
          if (!_found.any((a) => a.id == adapter.id)) {
            _found.add(adapter);
          }
        });
      },
      onError: (e) {
        if (!mounted) return;
        setState(() => _finding = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في البحث: $e')),
        );
      },
      onDone: () {
        if (!mounted) return;
        setState(() => _finding = false);
      },
    );
    await Future<void>.delayed(const Duration(seconds: 12));
  }

  Widget _deviceTile(ObdAdapter adapter) {
    final isMock = adapter.type == ObdTransportType.mock;
    final typeLabel = switch (adapter.type) {
      ObdTransportType.ble => 'بلوتوث BLE',
      ObdTransportType.classic => 'بلوتوث كلاسيكي',
      ObdTransportType.mock => 'محاكاة (تجريبي)',
    };
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: AppColors.surfaceLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ListTile(
        onTap: _connecting == null
            ? () => _connect(adapter)
            : null,
        leading: Icon(
          isMock ? Icons.science_outlined : Icons.bluetooth,
          color: isMock ? AppColors.textHint : AppColors.primary,
        ),
        title: Text(
          adapter.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          '$typeLabel  •  الإشارة: ${adapter.rssi} dBm',
          style: const TextStyle(fontSize: 12, color: AppColors.textHint),
        ),
        trailing: _connecting?.id == adapter.id
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.chevron_left, color: AppColors.textHint),
      ),
    );
  }

  Future<void> _connect(ObdAdapter adapter) async {
    setState(() => _connecting = adapter);
    final state = context.read<AppState>();
    final navigator = Navigator.of(context);
    final ok = await state.connectToAdapter(adapter);
    if (!mounted) return;
    setState(() => _connecting = null);
    if (ok) {
      navigator.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل الاتصال: ${state.error}')),
      );
    }
  }
}
