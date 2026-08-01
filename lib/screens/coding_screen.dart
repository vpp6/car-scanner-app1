import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/coding.dart';
import '../services/coding_service.dart';
import '../services/mock_data.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/side_menu_button.dart';

class CodingScreen extends StatefulWidget {
  const CodingScreen({super.key});

  @override
  State<CodingScreen> createState() => _CodingScreenState();
}

class _CodingScreenState extends State<CodingScreen> {
  final _service = MockCodingService();
  StreamSubscription<CodingState>? _sub;
  CodingState _state = CodingState.idle;
  CodingModule? _active;

  @override
  void initState() {
    super.initState();
    _sub = _service.codingStream().listen((state) {
      if (mounted) setState(() => _state = state);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        leading: const SideMenuButton(),
        title: const Text('البرمجة والتكويد'),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.warning),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.warning, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'وحدة ELM327 لا تدعم البرمجة والتكويد الفعلي — هذه واجهة توضيحية فقط. البرمجة تتطلب جهاز فحص متخصصاً.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.warning,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF12343B), Color(0xFF0B2026)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cloud_download, color: AppColors.primary, size: 40),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'برمجة الوحدات عبر الإنترنت',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          state.isConnected
                              ? 'اتصال بالجهاز جاهز • يتطلب اتصال إنترنت'
                              : 'اتصل بالجهاز لبدء البرمجة',
                          style: TextStyle(
                            fontSize: 12,
                            color: state.isConnected
                                ? AppColors.success
                                : AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 24, 20, 8),
            child: Text(
              'البرمجيات المتاحة لمركبتك',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          for (final module in MockData.codingModules)
            _moduleCard(context, module),
        ],
      ),
    );
  }

  Widget _moduleCard(BuildContext context, CodingModule module) {
    final busy = _state != CodingState.idle && _active == module;
    final done = _state == CodingState.done && _active == module;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: module.offline
                        ? AppColors.surfaceLight
                        : AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    module.offline ? 'أوفلاين' : 'أونلاين',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: module.offline
                          ? AppColors.textSecondary
                          : AppColors.primary,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${module.version} • ${module.size}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              module.name,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              module.description,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 14),
            if (done)
              Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.success),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'تمت البرمجة بنجاح',
                      style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _state = CodingState.idle),
                    child: const Text('تم'),
                  ),
                ],
              )
            else if (busy)
              _progressRow(_state)
            else
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: context
                          .read<AppState>()
                          .isConnected
                      ? () => _startCoding(module)
                      : () => _requireConnection(context),
                      icon: const Icon(Icons.download, color: Colors.black),
                      label: Text(
                        done ? 'إعادة البرمجة' : 'تحديث البرمجة',
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _progressRow(CodingState state) {
    final (label, progress) = switch (state) {
      CodingState.downloading => ('جارٍ التحميل من الإنترنت...', 0.3),
      CodingState.writing => ('جارٍ الكتابة على الوحدة...', 0.65),
      CodingState.verifying => ('جارٍ التحقق من البيانات...', 0.9),
      _ => ('...', 0.0),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(value: progress),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.secondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Future<void> _startCoding(CodingModule module) async {
    setState(() {
      _active = module;
      _state = CodingState.downloading;
    });
    await _service.startCoding(module);
  }

  void _requireConnection(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('قم بالاتصال بالجهاز أولاً')),
    );
  }
}
