import 'package:flutter/material.dart';
import '../../../bloc/carbon_calculator/carbon_calculator_cubit.dart';

class VehicleTypeSelector extends StatelessWidget {
  const VehicleTypeSelector({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final VehicleType selected;
  final ValueChanged<VehicleType> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: VehicleType.values.map((type) {
        final isActive = type == selected;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: type == VehicleType.values.last ? 0 : 8,
            ),
            child: GestureDetector(
              onTap: () => onSelected(type),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF43A047)
                      : const Color(0xFFF1F8E9),
                  borderRadius: BorderRadius.circular(12),
                  border: isActive
                      ? null
                      : Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  type.label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isActive ? Colors.white : Colors.black54,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
