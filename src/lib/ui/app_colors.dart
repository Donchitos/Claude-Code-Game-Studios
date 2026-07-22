import 'package:flutter/material.dart';

/// Shared color constants from Art Bible §4 (Color System) — the palette is
/// fixed and audited for WCAG AA contrast (accessibility-requirements.md
/// §"Text legibility", 2026-07-13/14 audit). Do not introduce ad-hoc hex
/// values in screen code; add new roles here if a screen needs one.
abstract final class AppColors {
  static const creamIvory = Color(0xFFFFFDF0);
  static const mintBreeze = Color(0xFFA8E6CF);
  static const peachGlow = Color(0xFFFFCBA4);
  static const petalPink = Color(0xFFFFB5C8);
  static const lavenderSoft = Color(0xFFC5A3E0);
  static const honeyGold = Color(0xFFFFD060);
  static const cloudWhite = Color(0xFFFFFFFF);

  /// Warm dark brown — the only text role safe on every palette background
  /// at AA 4.5:1 (audit 2026-07-13). Also used for button labels — on-color
  /// (white) text failed contrast on all 7 backgrounds and was retired
  /// (Art Bible §"Text Colors" correction, 2026-07-13).
  static const primaryText = Color(0xFF3D2B1F);

  /// Darkened 2026-07-14 from the original `#9B7060` (worst-case 1.99:1) —
  /// passes AA normal-text 4.5:1 on all 7 backgrounds now.
  static const secondaryText = Color(0xFF553826);

  /// Darkened 2026-07-14 from the original `#C0A898` (worst-case 1.04:1) —
  /// passes AA large-text/UI-component 3:1 on all 7 backgrounds now.
  static const disabledText = Color(0xFF644A3C);

  /// Parent-zone tone — `design/gdd/main-navigation-shell.md:184` ("Navy
  /// `#2C3E50`"), reaffirmed by `design/gdd/parent-dashboard-ui.md:134` as
  /// the tone Parent Dashboard UI inherits directly. Added here
  /// (main-navigation-shell Story 003) rather than left file-local, since
  /// at least 2 more upcoming screens already cite this exact value.
  static const parentNavy = Color.fromARGB(0xFF, 0x2C, 0x3E, 0x50);
}
