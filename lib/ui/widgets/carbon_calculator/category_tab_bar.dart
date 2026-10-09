import 'package:flutter/material.dart';
import '../../../bloc/carbon_calculator/carbon_calculator_cubit.dart';

class CategoryTabBar extends StatelessWidget {
  const CategoryTabBar({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final CarbonCategory selected;
  final ValueChanged<CarbonCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => onSelected(CarbonCategory.listrik),
            child: _TabItem(
              icon: Icons.home_outlined,
              label: 'Listrik Rumah',
              isActive: selected == CarbonCategory.listrik,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: () => onSelected(CarbonCategory.kendaraan),
            child: _TabItem(
              icon: Icons.directions_bike,
              label: 'Kendaraan',
              isActive: selected == CarbonCategory.kendaraan,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: () => onSelected(CarbonCategory.gas),
            child: _TabItem(
              icon: Icons.local_fire_department_outlined,
              label: 'Gas/Lainnya',
              isActive: selected == CarbonCategory.gas,
            ),
          ),
        ),
      ],
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.icon,
    required this.label,
    required this.isActive,
  });

  final IconData icon;
  final String label;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF43A047) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isActive ? null : Border.all(color: Colors.grey.shade200),
        boxShadow: [
          if (isActive)
            BoxShadow(
              color: const Color(0xFF43A047).withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isActive ? Colors.white : Colors.black54),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.white : Colors.black54,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
