import 'package:flutter/material.dart';

/// Design tokens for Trusted Neighbourhood Network — navy/gold/cream, formal and
/// trustworthy (matches the resident-app clickable prototype). Light theme only
/// for now; kept in one place so dark mode can be added without touching screens.
class TnnColors {
  TnnColors._();

  static const ink = Color(0xFF22314A); // primary surface (headers, nav, text)
  static const inkSoft = Color(0xFF4A5A75); // secondary text
  static const paper = Color(0xFFF3F5EE); // app background
  static const card = Color(0xFFFBFAF5); // card surfaces
  static const gold = Color(0xFFD9A02C); // accent / CTA
  static const goldDeep = Color(0xFFB9821A);
  static const brick = Color(0xFFA8503A); // critical
  static const leaf = Color(0xFF4C7A5E); // success / verified
  static const line = Color(0xFFDCD8C9);
  static const lineSoft = Color(0xFFE9E6DA);

  // Status-pill colors (lifecycle states across issues/bookings/verification)
  static const statusNeutralBg = Color(0xFFEFEFE9);
  static const statusNeutralFg = inkSoft;
  static const statusPendingBg = Color(0xFFFFF3DC);
  static const statusPendingFg = goldDeep;
  static const statusSuccessBg = Color(0xFFE8F1EA);
  static const statusSuccessFg = leaf;
  static const statusCriticalBg = Color(0xFFF0CBB6);
  static const statusCriticalFg = brick;
}

class TnnSpacing {
  TnnSpacing._();
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 28.0;
}

class TnnRadius {
  TnnRadius._();
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const pill = 999.0;
}
