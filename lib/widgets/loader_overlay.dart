

import 'dart:ui';

import 'package:easyexpire/core/constant/app_assets.dart';
import 'package:flutter/material.dart';

class LoaderOverlay extends StatefulWidget {
  final bool isSignedIn;
  const LoaderOverlay(
      {super.key,
        required this.isSignedIn,
      }
      );

  @override
  State<LoaderOverlay> createState() => _LoaderOverlayState();
}

class _LoaderOverlayState extends State<LoaderOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ping;

  @override
  void initState() {
    super.initState();
    _ping = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _ping.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Positioned.fill(
      child: Material(
        color: Colors.transparent,
        child: BackdropFilter(
          // backdrop-blur-md
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            color: Colors.black.withOpacity(0.4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Ping ring + logo box
                SizedBox(
                  width: 96,
                  height: 96,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Ping ring
                      AnimatedBuilder(
                        animation: _ping,
                        builder: (_, __) => Transform.scale(
                          scale: 1.0 + _ping.value * 0.4,
                          child: Opacity(
                            opacity: (1 - _ping.value).clamp(0.0, 1.0),
                            child: Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: cs.primary.withOpacity(0.2),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Logo box
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(
                            color: cs.outlineVariant.withOpacity(0.3),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.asset(
                          AppAssets.appLogo,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height:24),

                // "Signing in..."
                Text(widget.isSignedIn?
                'Signing in...':'Loading ...',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}