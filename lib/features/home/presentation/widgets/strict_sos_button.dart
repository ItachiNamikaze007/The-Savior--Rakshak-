import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';

class StrictSosButton extends StatefulWidget {
  final bool isDispatching;
  final bool hasActiveSos;
  final VoidCallback onTrigger;

  const StrictSosButton({
    super.key,
    required this.isDispatching,
    required this.hasActiveSos,
    required this.onTrigger,
  });

  @override
  State<StrictSosButton> createState() => _StrictSosButtonState();
}

class _StrictSosButtonState extends State<StrictSosButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _holdController;
  bool _isHolding = false;

  @override
  void initState() {
    super.initState();
    _holdController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _holdController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        HapticFeedback.heavyImpact();
        widget.onTrigger();
        _resetHold();
      }
    });
  }

  @override
  void dispose() {
    _holdController.dispose();
    super.dispose();
  }

  void _onHoldStart() {
    if (widget.isDispatching || widget.hasActiveSos) return;
    setState(() => _isHolding = true);
    HapticFeedback.mediumImpact();
    _holdController.forward();
  }

  void _onHoldEnd() {
    if (_isHolding) {
      _resetHold();
    }
  }

  void _resetHold() {
    setState(() => _isHolding = false);
    _holdController.reset();
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.isDispatching || widget.hasActiveSos;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.emergencyRedLight,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.emergencyRed.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.emergencyRed.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Label & Subtitle
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.emergencyRed,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.flash_on_rounded, size: 16, color: Colors.white),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'STRICT SOS',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        color: AppColors.emergencyRed,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'HOLD TO SEND (3s)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDarkSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Central Hold-to-Activate Button (Visually Dominant)
          GestureDetector(
            onTapDown: (_) => _onHoldStart(),
            onTapUp: (_) => _onHoldEnd(),
            onTapCancel: () => _onHoldEnd(),
            child: AnimatedBuilder(
              animation: _holdController,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer Circular Progress Track (3s Hold Ring)
                    SizedBox(
                      width: 156,
                      height: 156,
                      child: CircularProgressIndicator(
                        value: _holdController.value,
                        strokeWidth: 7,
                        backgroundColor: Colors.black.withOpacity(0.06),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.emergencyRed,
                        ),
                      ),
                    ),

                    // Main Big Red Button
                    Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: isDisabled
                              ? [Colors.grey.shade400, Colors.grey.shade500]
                              : [AppColors.emergencyRed, AppColors.emergencyRedDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: isDisabled
                            ? null
                            : [
                                BoxShadow(
                                  color: AppColors.emergencyRed.withOpacity(0.45),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (widget.isDispatching) ...[
                              const SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'TRANSMITTING',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ] else if (widget.hasActiveSos) ...[
                              const Icon(Icons.radio_button_checked_rounded, color: Colors.white, size: 32),
                              const SizedBox(height: 4),
                              const Text(
                                'ACTIVE BEACON',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ] else ...[
                              const Icon(Icons.emergency_share_rounded, color: Colors.white, size: 42),
                              const SizedBox(height: 4),
                              Text(
                                _isHolding
                                    ? '${((1.0 - _holdController.value) * 3).ceil()}s'
                                    : 'HOLD SOS',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Footnote instruction
          Text(
            widget.hasActiveSos
                ? 'Distress beacon is live. HQ response team notified.'
                : (_isHolding
                    ? 'Transmitting emergency beacon in 3 seconds...'
                    : 'Press and hold for 3 seconds to send instant emergency alert'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _isHolding ? AppColors.emergencyRed : AppColors.textDarkMuted,
            ),
          ),
        ],
      ),
    );
  }
}
