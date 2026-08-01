import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/dtc.dart';
import '../services/scan_service.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/app_icon.dart';
import '../widgets/section_title.dart';
import '../widgets/side_menu_button.dart';
import 'vehicle_select_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  bool _scanning = false;
  double _progress = 0;
  StreamSubscription<double>? _progressSub;

  @override
  void dispose() {
    _progressSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        leading: const SideMenuButton(),
        title: const Text('فحص الأنظمة'),
        actions: [
          if (state.codes.isNotEmpty)
            IconButton(
              tooltip: 'مسح الأكواد',
              onPressed: () => _confirmClear(state),
              icon: const Icon(Icons.delete_sweep, color: AppColors.danger),
            ),
          IconButton(
            tooltip: 'تحديث',
            onPressed: () => state.refreshSystems(),
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _scanHeader(context, state),
          Expanded(
            child: _scanning
                ? _scanningView()
                : state.vehicle == null
                    ? _emptyState()
                    : state.codes.isNotEmpty
                        ? _codesView(state)
                        : _systemsView(state),
          ),
        ],
      ),
    );
  }

  Widget _scanHeader(BuildContext context, AppState state) {
    final vehicle = state.vehicle;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vehicle == null
                      ? 'لم يتم اختيار مركبة'
                      : '${vehicle.make} ${vehicle.model} ${vehicle.year}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'دعم أكثر من 200 موديل',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          if (state.vehicle != null)
            FilledButton.icon(
              onPressed: _scanning ? null : _startScan,
              icon: _scanning
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Icon(Icons.play_arrow, color: Colors.black),
              label: Text(_scanning ? 'جارٍ الفحص...' : 'فحص شامل'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 48),
                padding: const EdgeInsets.symmetric(horizontal: 18),
              ),
            ),
        ],
      ),
    );
  }

  Widget _scanningView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 140,
              height: 140,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: _progress,
                    strokeWidth: 10,
                    strokeCap: StrokeCap.round,
                  ),
                  Center(
                    child: Text(
                      '${(_progress * 100).round()}%',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'جاري فحص جميع الأنظمة عبر CAN FD...',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.directions_car, size: 64, color: AppColors.textHint),
          const SizedBox(height: 16),
          const Text(
            'اختر مركبة لبدء الفحص',
            style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    const VehicleSelectScreen(),
              ),
            ),
            child: const Text('اختيار مركبة'),
          ),
        ],
      ),
    );
  }

  Widget _systemsView(AppState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(title: 'الأنظمة المتاحة (${state.systems.length})'),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: state.systems.length,
            itemBuilder: (context, index) {
              final system = state.systems[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: Icon(
                    iconFor(system.icon),
                    color: system.supported
                        ? AppColors.primary
                        : AppColors.textHint,
                  ),
                  title: Text(
                    system.name,
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                  trailing: system.supported
                      ? const Icon(
                          Icons.check_circle,
                          color: AppColors.success,
                          size: 20,
                        )
                      : const Icon(
                          Icons.help_outline,
                          color: AppColors.textHint,
                          size: 20,
                        ),
                  onTap: () => _readCodes(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _codesView(AppState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(
            children: [
              const Icon(Icons.warning_amber, color: AppColors.danger),
              const SizedBox(width: 8),
              Text(
                '${state.totalDtcCount} كود أخطاء مُسجّل',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.danger,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              for (final entry in state.codes.entries) ...[
                SectionTitle(title: entry.key),
                for (final code in entry.value)
                  _dtcCard(code),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _dtcCard(DtcCode code) {
    final severityColor = switch (code.severity) {
      DtcSeverity.low => AppColors.success,
      DtcSeverity.medium => AppColors.warning,
      DtcSeverity.high => AppColors.secondary,
      DtcSeverity.critical => AppColors.danger,
    };
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 10,
          height: 54,
          decoration: BoxDecoration(
            color: severityColor,
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        title: Row(
          children: [
            Text(
              code.code,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: severityColor,
              ),
            ),
            const SizedBox(width: 8),
            if (code.frozen)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'مجمّد',
                  style: TextStyle(fontSize: 10, color: AppColors.textHint),
                ),
              ),
          ],
        ),
        subtitle: Text(
          code.description,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        trailing: IconButton(
          onPressed: () => _showDtcDetail(code),
          icon: const Icon(Icons.info_outline, color: AppColors.textHint),
        ),
      ),
    );
  }

  void _showDtcDetail(DtcCode code) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              code.code,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              code.description,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            _detailRow('النظام', code.system),
            _detailRow('الخطورة', code.severityLabel),
            _detailRow('مرات الظهور', '${code.occurrences}'),
            _detailRow('حالة البيانات', code.frozen ? 'مجمّدة' : 'مباشرة'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showCodingPrompt();
                },
                icon: const Icon(Icons.auto_fix_high),
                label: const Text('مقترحات الإصلاح'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  void _showCodingPrompt() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('يُفضّل فحص المستشعرات قبل التوصية بحلول الإصلاح'),
      ),
    );
  }

  Future<void> _startScan() async {
    setState(() {
      _scanning = true;
      _progress = 0;
    });
    _progressSub = scanProgress().listen((value) {
      if (mounted) setState(() => _progress = value);
    });
    await Future<void>.delayed(const Duration(seconds: 4));
    if (!mounted) return;
    setState(() => _scanning = false);
    await context.read<AppState>().readCodes();
  }

  Future<void> _readCodes() async {
    setState(() => _scanning = true);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _scanning = false);
    await context.read<AppState>().readCodes();
  }

  Future<void> _confirmClear(AppState state) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('مسح الأكواد؟'),
        content: const Text('سيتم حذف جميع الأكواد المخزنة من الجهاز.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.black,
            ),
            child: const Text('مسح الأكواد'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await state.clearCodes();
    }
  }
}
