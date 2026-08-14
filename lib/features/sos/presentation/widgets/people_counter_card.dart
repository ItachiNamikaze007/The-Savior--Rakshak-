import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';

class PeopleCounterCard extends StatelessWidget {
  final int peopleCount;
  final int injuredCount;
  final VoidCallback onIncrementPeople;
  final VoidCallback onDecrementPeople;
  final ValueChanged<int> onSetPeople;
  final VoidCallback onIncrementInjured;
  final VoidCallback onDecrementInjured;
  final ValueChanged<int> onSetInjured;

  const PeopleCounterCard({
    super.key,
    required this.peopleCount,
    required this.injuredCount,
    required this.onIncrementPeople,
    required this.onDecrementPeople,
    required this.onSetPeople,
    required this.onIncrementInjured,
    required this.onDecrementInjured,
    required this.onSetInjured,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          const Row(
            children: [
              Icon(Icons.groups_rounded, size: 18, color: AppColors.statusStandby),
              SizedBox(width: 8),
              Text(
                'CASUALTY & POPULATION TELEMETRY',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 1. Total People Affected
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.affectedPeople,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Total victims requiring rescue',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),

              // Stepper Controls
              _buildStepper(
                value: peopleCount,
                minValue: 1,
                onDecrement: onDecrementPeople,
                onIncrement: onIncrementPeople,
                highlightColor: AppColors.statusStandby,
              ),
            ],
          ),

          // Quick Selection Chips for Affected
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Quick add: ', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
              _buildQuickAddChip('+1', () => onSetPeople(peopleCount + 1)),
              const SizedBox(width: 6),
              _buildQuickAddChip('+5', () => onSetPeople(peopleCount + 5)),
              const SizedBox(width: 6),
              _buildQuickAddChip('+10', () => onSetPeople(peopleCount + 10)),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 14),

          // 2. Injured Requiring Medical Aid
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Text(
                          AppStrings.injuredPeople,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Critical priority for triage',
                      style: TextStyle(
                        fontSize: 11,
                        color: injuredCount > 0 ? AppColors.disasterMedical : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),

              // Stepper Controls
              _buildStepper(
                value: injuredCount,
                minValue: 0,
                maxValue: peopleCount,
                onDecrement: onDecrementInjured,
                onIncrement: onIncrementInjured,
                highlightColor: AppColors.disasterMedical,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAddChip(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
        ),
      ),
    );
  }

  Widget _buildStepper({
    required int value,
    required int minValue,
    int? maxValue,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
    required Color highlightColor,
  }) {
    final canDecrement = value > minValue;
    final canIncrement = maxValue == null || value < maxValue;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Decrement Button
          IconButton(
            icon: const Icon(Icons.remove, size: 18),
            color: canDecrement ? AppColors.textPrimary : AppColors.textMuted,
            onPressed: canDecrement ? onDecrement : null,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: EdgeInsets.zero,
          ),

          // Count Display
          Container(
            constraints: const BoxConstraints(minWidth: 36),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              value.toString(),
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: value > 0 ? highlightColor : AppColors.textMuted,
                fontFamily: 'monospace',
              ),
            ),
          ),

          // Increment Button
          IconButton(
            icon: const Icon(Icons.add, size: 18),
            color: canIncrement ? AppColors.textPrimary : AppColors.textMuted,
            onPressed: canIncrement ? onIncrement : null,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}
