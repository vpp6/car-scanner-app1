import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/vehicle.dart';
import '../services/mock_data.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';

class VehicleSelectScreen extends StatefulWidget {
  const VehicleSelectScreen({super.key});

  @override
  State<VehicleSelectScreen> createState() => _VehicleSelectScreenState();
}

class _VehicleSelectScreenState extends State<VehicleSelectScreen> {
  VehicleMake? _make;
  String? _model;
  String? _year;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('اختيار المركبة')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _stepBadge(1, 'الماركة'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: MockData.supportedMakes.map((make) {
              final selected = _make?.name == make.name;
              return ChoiceChip(
                label: Text(make.name),
                selected: selected,
                onSelected: (_) => setState(() {
                  _make = make;
                  _model = null;
                  _year = null;
                }),
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: selected ? Colors.black : AppColors.textPrimary,
                ),
              );
            }).toList(),
          ),
          if (_make != null) ...[
            const SizedBox(height: 24),
            _stepBadge(2, 'الطراز'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _make!.models.map((model) {
                final selected = _model == model;
                return ChoiceChip(
                  label: Text(model),
                  selected: selected,
                  onSelected: (_) => setState(() {
                    _model = model;
                    _year = null;
                  }),
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: selected ? Colors.black : AppColors.textPrimary,
                  ),
                );
              }).toList(),
            ),
          ],
          if (_model != null) ...[
            const SizedBox(height: 24),
            _stepBadge(3, 'سنة الصنع'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(12, (i) => (2026 - i).toString()).map(
                (year) {
                  final selected = _year == year;
                  return ChoiceChip(
                    label: Text(year),
                    selected: selected,
                    onSelected: (_) => setState(() => _year = year),
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: selected ? Colors.black : AppColors.textPrimary,
                    ),
                  );
                },
              ).toList(),
            ),
          ],
          if (_make != null && _model != null && _year != null) ...[
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _saveVehicle,
              icon: const Icon(Icons.check),
              label: const Text('تأكيد المركبة'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _stepBadge(int number, String label) {
    return Row(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: AppColors.primary,
          child: Text(
            '$number',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Future<void> _saveVehicle() async {
    final state = context.read<AppState>();
    final navigator = Navigator.of(context);
    await state.setVehicle(
      Vehicle(
        vin: MockData.vehicle.vin,
        make: _make!.name,
        model: _model!,
        year: int.parse(_year!),
        engine: MockData.vehicle.engine,
        fuel: MockData.vehicle.fuel,
        odometer: MockData.vehicle.odometer,
        plate: MockData.vehicle.plate,
      ),
    );
    if (!mounted) return;
    navigator.pop();
  }
}
