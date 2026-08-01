import 'dart:async';

import 'package:flutter/material.dart';

import '../models/oscilloscope.dart';
import '../services/oscilloscope_service.dart';
import '../theme/app_colors.dart';
import '../widgets/side_menu_button.dart';

class OscilloscopeScreen extends StatefulWidget {
  const OscilloscopeScreen({super.key});

  @override
  State<OscilloscopeScreen> createState() => _OscilloscopeScreenState();
}

class _OscilloscopeScreenState extends State<OscilloscopeScreen> {
  final _service = MockOscilloscopeService();
  StreamSubscription<List<ScopeChannel>>? _sub;
  List<ScopeChannel> _channels = const [];
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _sub = _service.channels().listen((channels) {
      if (mounted) setState(() => _channels = channels);
    });
    _start();
  }

  Future<void> _start() async {
    await _service.start();
    if (mounted) setState(() => _running = true);
  }

  Future<void> _toggle() async {
    if (_running) {
      await _service.stop();
      setState(() => _running = false);
    } else {
      await _start();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _service.stop();
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const SideMenuButton(),
        title: const Text('الأوسيلوسكوب'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: _channelLegend(),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
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
                    'وحدة ELM327 لا تحتوي على أوسيلوسكوب فعلي — هذه موجات توضيحية محاكاة. الأوسيلوسكوب الحقيقي يتطلب جهازاً بمداخل إشارة تناظرية.',
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
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _ScopeGrid(channels: _channels),
            ),
          ),
          _controls(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _channelLegend() {
    const colors = [
      AppColors.ch1,
      AppColors.ch2,
      AppColors.ch3,
      AppColors.ch4,
    ];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(4, (i) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: colors[i],
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }

  Widget _controls() {
    final ch = _channels.isNotEmpty ? _channels.first : null;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: _controlButton(
                  label: 'بدء/إيقاف',
                  icon: _running ? Icons.stop : Icons.play_arrow,
                  color: _running ? AppColors.danger : AppColors.success,
                  onTap: _toggle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _controlButton(
                  label: ch != null
                      ? 'جهد ${ch.voltageScale.toStringAsFixed(0)}V/div'
                      : 'الجهد',
                  icon: Icons.vertical_align_center,
                  color: AppColors.secondary,
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _controlButton(
                  label: ch != null
                      ? 'زمن ${ch.timeScale.toStringAsFixed(1)}s/div'
                      : 'الزمن',
                  icon: Icons.timeline,
                  color: AppColors.warning,
                  onTap: () {},
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            _running ? 'قياس مباشر بجودة 4 قنوات' : 'متوقف',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textHint,
            ),
          ),
        ),
      ],
    );
  }

  Widget _controlButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScopeGrid extends StatelessWidget {
  final List<ScopeChannel> channels;

  const _ScopeGrid({required this.channels});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF05090A),
          border: Border.all(color: AppColors.border),
        ),
        child: CustomPaint(
          painter: _ScopePainter(channels: channels),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _ScopePainter extends CustomPainter {
  final List<ScopeChannel> channels;

  _ScopePainter({required this.channels});

  static const _colors = [
    AppColors.ch1,
    AppColors.ch2,
    AppColors.ch3,
    AppColors.ch4,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFF16242A)
      ..strokeWidth = 1;
    const step = 36.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final centerLine = Paint()
      ..color = const Color(0xFF2A3A42)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      centerLine,
    );

    for (final channel in channels) {
      if (!channel.enabled || channel.points.isEmpty) continue;
      final color = _colors[channel.index - 1];
      final path = Path();
      final chartWidth = size.width - 8;
      final chartHeight = size.height - 8;
      final vScale = channel.voltageScale;
      for (var i = 0; i < channel.points.length; i++) {
        final p = channel.points[i];
        final x = 4 + (i / (channel.points.length - 1)) * chartWidth;
        final y =
            size.height / 2 - (p.v / vScale) * (chartHeight / 2 / 3);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ScopePainter oldDelegate) {
    return oldDelegate.channels != channels;
  }
}
