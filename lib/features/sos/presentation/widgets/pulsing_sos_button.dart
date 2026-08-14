import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class PulsingSosButton extends StatefulWidget {
  final VoidCallback onPressed;
  final bool isEnabled;

  const PulsingSosButton({
    super.key,
    required this.onPressed,
    this.isEnabled = true,
  });

  @override
  State<PulsingSosButton> createState() => _PulsingSosButtonState();
}

class _PulsingSosButtonState extends State<PulsingSosButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 8.0, end: 24.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double buttonSize = 160.0;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer radar pulse ring 2
              Container(
                width: buttonSize + (_glowAnimation.value * 2.2),
                height: buttonSize + (_glowAnimation.value * 2.2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.emergencyRed.withOpacity(0.06),
                  border: Border.all(
                    color: AppColors.emergencyRed.withOpacity(0.18),
                    width: 1.5,
                  ),
                ),
              ),

              // Outer radar pulse ring 1
              Container(
                width: buttonSize + (_glowAnimation.value * 1.2),
                height: buttonSize + (_glowAnimation.value * 1.2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.emergencyRed.withOpacity(0.12),
                  border: Border.all(
                    color: AppColors.emergencyRed.withOpacity(0.35),
                    width: 2.0,
                  ),
                ),
              ),

              // Main Pulsing Action Trigger Button
              Transform.scale(
                scale: widget.isEnabled ? _scaleAnimation.value : 1.0,
                child: Material(
                  color: Colors.transparent,
                  shape: const CircleBorder(),
                  elevation: 12,
                  shadowColor: AppColors.emergencyRedDark.withOpacity(0.8),
                  child: InkWell(
                    onTap: widget.isEnabled ? widget.onPressed : null,
                    customBorder: const CircleBorder(),
                    splashColor: Colors.white24,
                    child: Container(
                      width: buttonSize,
                      height: buttonSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          center: const Alignment(-0.2, -0.3),
                          radius: 0.9,
                          colors: widget.isEnabled
                              ? [
                                  AppColors.emergencyRedGlow,
                                  AppColors.emergencyRed,
                                  AppColors.emergencyRedDark,
                                ]
                              : [
                                  AppColors.border,
                                  AppColors.surfaceElevated,
                                  AppColors.surface,
                                ],
                        ),
                        boxShadow: widget.isEnabled
                            ? [
                                BoxShadow(
                                  color: AppColors.emergencyRed.withOpacity(0.5),
                                  blurRadius: _glowAnimation.value,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                        border: Border.all(
                          color: widget.isEnabled ? Colors.white.withOpacity(0.6) : AppColors.border,
                          width: 3.0,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.emergency_share_rounded,
                            size: 32,
                            color: widget.isEnabled ? Colors.white : AppColors.textMuted,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'SOS',
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.5,
                              color: widget.isEnabled ? Colors.white : AppColors.textMuted,
                              shadows: widget.isEnabled
                                  ? const [
                                      Shadow(
                                        color: Colors.black45,
                                        blurRadius: 6,
                                        offset: Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'TRANSMIT',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.8,
                              color: widget.isEnabled ? AppColors.textAlert : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
