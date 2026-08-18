import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../sos/domain/entities/emergency_type.dart';
import '../../../sos/presentation/providers/sos_state_notifier.dart';

class DetailedSosButton extends StatelessWidget {
  final SosStateNotifier notifier;

  const DetailedSosButton({super.key, required this.notifier});

  void _openDetailedSosSheet(BuildContext context) {
    EmergencyType selectedCategory = notifier.selectedEmergencyType;
    String severity = 'Serious'; // Low, Serious, Critical
    int people = notifier.peopleCount;
    int injured = notifier.injuredCount;

    // Voice Note State
    bool isRecordingVoice = false;
    bool hasRecordedVoice = false;
    bool isPlayingVoice = false;
    int voiceDurationSeconds = 0;
    Timer? voiceTimer;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                top: 16,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: AppColors.lightSurface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Handle Bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.lightBorder,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.assignment_late_rounded,
                                color: AppColors.statusTransmitting, size: 22),
                            SizedBox(width: 8),
                            Text(
                              'DETAILED SOS',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                                color: AppColors.textDarkPrimary,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textDarkSecondary),
                          onPressed: () {
                            voiceTimer?.cancel();
                            Navigator.pop(modalCtx);
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // 1. Emergency Type (Required)
                    const Text(
                      '1. EMERGENCY TYPE (REQUIRED)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: AppColors.textDarkMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: EmergencyType.values.map((type) {
                        final isSelected = selectedCategory == type;
                        return ChoiceChip(
                          avatar: Icon(
                            type.icon,
                            size: 16,
                            color: isSelected ? Colors.white : type.color,
                          ),
                          label: Text(
                            type.displayName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white : AppColors.textDarkPrimary,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: type.color,
                          backgroundColor: AppColors.lightSurfaceElevated,
                          side: BorderSide(
                            color: isSelected ? type.color : AppColors.lightBorder,
                          ),
                          onSelected: (val) {
                            if (val) setModalState(() => selectedCategory = type);
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 16),

                    // 2. Severity Level (Required: Low, Serious, Critical)
                    const Text(
                      '2. SEVERITY LEVEL (REQUIRED)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: AppColors.textDarkMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildSeverityOption('Low', Colors.blue, severity == 'Low', () {
                          setModalState(() => severity = 'Low');
                        }),
                        const SizedBox(width: 8),
                        _buildSeverityOption('Serious', AppColors.statusTransmitting, severity == 'Serious', () {
                          setModalState(() => severity = 'Serious');
                        }),
                        const SizedBox(width: 8),
                        _buildSeverityOption('Critical', AppColors.emergencyRed, severity == 'Critical', () {
                          setModalState(() => severity = 'Critical');
                        }),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // 3. Optional Voice Note (Optional)
                    const Text(
                      '3. OPTIONAL VOICE NOTE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: AppColors.textDarkMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.lightSurfaceElevated,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.lightBorder),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              isRecordingVoice
                                  ? Icons.stop_circle_rounded
                                  : (hasRecordedVoice ? Icons.play_arrow_rounded : Icons.mic_rounded),
                              color: isRecordingVoice
                                  ? AppColors.emergencyRed
                                  : AppColors.primaryIndigo,
                              size: 28,
                            ),
                            onPressed: () {
                              setModalState(() {
                                if (isRecordingVoice) {
                                  // Stop recording
                                  isRecordingVoice = false;
                                  hasRecordedVoice = true;
                                  voiceTimer?.cancel();
                                } else if (hasRecordedVoice) {
                                  // Play recording
                                  isPlayingVoice = !isPlayingVoice;
                                } else {
                                  // Start recording
                                  isRecordingVoice = true;
                                  voiceDurationSeconds = 0;
                                  voiceTimer = Timer.periodic(const Duration(seconds: 1), (t) {
                                    setModalState(() {
                                      voiceDurationSeconds++;
                                    });
                                  });
                                }
                              });
                            },
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isRecordingVoice
                                      ? 'Recording... (${voiceDurationSeconds}s)'
                                      : (hasRecordedVoice
                                          ? 'Voice note attached (${voiceDurationSeconds}s)'
                                          : 'Tap to record voice message (Optional)'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isRecordingVoice
                                        ? AppColors.emergencyRed
                                        : AppColors.textDarkPrimary,
                                  ),
                                ),
                                const Text(
                                  'SOS sends immediately without waiting for voice upload',
                                  style: TextStyle(fontSize: 10, color: AppColors.textDarkMuted),
                                ),
                              ],
                            ),
                          ),
                          if (hasRecordedVoice)
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.textDarkMuted),
                              onPressed: () {
                                setModalState(() {
                                  hasRecordedVoice = false;
                                  voiceDurationSeconds = 0;
                                });
                              },
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 4. Casualties (Optional)
                    Row(
                      children: [
                        Expanded(
                          child: _buildStepper('AFFECTED', people, () {
                            if (people > 1) {
                              setModalState(() {
                                people--;
                                if (injured > people) injured = people;
                              });
                            }
                          }, () {
                            setModalState(() => people++);
                          }),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildStepper('INJURED', injured, () {
                            if (injured > 0) setModalState(() => injured--);
                          }, () {
                            if (injured < people) setModalState(() => injured++);
                          }, isRed: true),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Dispatch Action Button (Fast submission)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: const Text('SEND DETAILED SOS'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.statusTransmitting,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        voiceTimer?.cancel();
                        Navigator.pop(modalCtx);
                        notifier.dispatchDetailedSos(
                          type: selectedCategory,
                          people: people,
                          injured: injured,
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSeverityOption(String label, Color color, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color : AppColors.lightSurfaceElevated,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? Colors.transparent : AppColors.lightBorder),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: isSelected ? Colors.white : AppColors.textDarkSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepper(String label, int value, VoidCallback onDec, VoidCallback onInc, {bool isRed = false}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.lightSurfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: isRed ? AppColors.emergencyRed : AppColors.textDarkMuted,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline_rounded, size: 20),
                color: isRed ? AppColors.emergencyRed : AppColors.primaryIndigo,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: onDec,
              ),
              Text(
                '$value',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: isRed ? AppColors.emergencyRed : AppColors.textDarkPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                color: isRed ? AppColors.emergencyRed : AppColors.primaryIndigo,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: onInc,
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openDetailedSosSheet(context),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.statusTransmittingLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.tune_rounded,
                    color: AppColors.statusTransmitting,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DETAILED SOS',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                          color: AppColors.textDarkPrimary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Add emergency type & optional voice note',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textDarkSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: AppColors.textDarkMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
