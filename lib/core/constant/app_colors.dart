import 'package:flutter/material.dart';

abstract class AppColors {
  AppColors._();

  // --- Core Palette from Lumina Inventory Design ---
  // Primary: #1A1C1E (Darkest color, used for backgrounds, bold text, active elements)
  static const Color primary = Color(0xff1A1C1E);

  // Secondary: #F0FDF4 (Very light green-ish, could be subtle background or accent)
  static const Color secondary = Color(0xffF0FDF4);

  // Tertiary: #201B17 (Dark brownish-grey, often for secondary dark elements, some text)
  static const Color tertiary = Color(0xff201B17);

  // Neutral: #F9FAFB (Very light grey, ideal for scaffold backgrounds, card borders, etc.)
  static const Color neutral = Color(0xffF9FAFB);


  // --- General & Derived Colors (aligned with the design) ---

  // Basic Whites & Blacks
  static const Color white = Color(0xffffffff);
  static const Color black = Color(0xff000000); // Explicit black if needed

  // Scaffold & Surface Colors
  static const Color scaffoldBackground = neutral; // Main app background
  static const Color cardBackground = white; // Background for cards (like the form container)
  static const Color inputFillColor = neutral; // Color for filled text fields (e.g., search bar)

  // Text Colors
  static const Color headlineTextColor = primary; // For prominent headlines (e.g., "Add New Product")
  static const Color bodyTextColor = Color(0xFF4F4F4F); // A dark grey from the primary palette in the image (e.g., for body text)
  static const Color labelTextColor = Color(0xFF6B6B6B); // Lighter grey for labels and descriptions (e.g., "Log inventory items quickly.")
  static const Color hintTextColor = Color(0xFF9E9E9E); // Even lighter grey for hint text in fields
  static const Color whiteTextColor = white; // Text on dark backgrounds (e.g., primary buttons)

  // Border & Divider Colors
  static const Color borderColor = Color(0xFFE0E0E0); // Subtle light grey for borders (matches card/input borders)
  static const Color dividerColor = Color(0xFFE5E5E5); // Slightly lighter for dividers (like "OR ENTER MANUALLY")

  // Button-specific Colors
  static const Color buttonPrimaryBackground = primary; // Background for main action buttons
  static const Color buttonPrimaryText = white; // Text on main action buttons
  static const Color buttonSecondaryBackground = Color(0xFFF0F0F0); // Light grey for secondary buttons
  static const Color buttonInvertedBackground = Color(0xFF4F4F4F); // Dark grey for 'inverted' buttons
  static const Color buttonOutlineBorder = Color(0xFFB0B0B0); // Border color for outlined buttons

  // Bottom Navigation Bar Colors (based on the provided image of the bottom nav)
  static const Color bottomNavBarBackground = white; // Background of the entire bar
  static const Color bottomNavActiveIconBackground = primary; // Background behind the active icon
  static const Color bottomNavActiveIcon = white; // Color of the active icon
  static const Color bottomNavInactiveIcon = bodyTextColor; // Color of inactive icons
  static const Color bottomNavLabel = labelTextColor; // Color of bottom nav labels

  // Status Colors (Keeping existing as they are semantic and not defined in the new palette image)
  static const Color goodColor = Color(0xFF83CC61); // Green for good status
  static const Color mediumColor = Color(0xFFF5D97E); // Yellow for medium status
  static const Color toxicColor = Color(0xFFE70000); // Red for toxic/bad status

// --- NEW STATUS COLORS (for badges and progress bar) ---
  // Error/Expired Status (red)
  static const Color errorContainerBackground = Color(0xFFFEE8E6); // Light red container for "Expired"
  static const Color onErrorContainerText = Color(0xFFD32F2F); // Darker red text for "Expired"
  static const Color errorProgressBarFill = Color(0xFFE70000); // Bright red for progress bar (toxicColor)

  // Warning/Expiring Soon Status (orange/yellow)
  static const Color warningContainerBackground = Color(0xFFFFF3E0); // Light orange container for "Expiring Soon"
  static const Color onWarningContainerText = Color(0xFFE65100); // Darker orange text for "Expiring Soon"
  static const Color warningProgressBarFill = Color(0xFFE65100); // Orange for progress bar (mediumColor variant)

  // Good/Safe Status (green)
  static const Color goodContainerBackground = Color(0xFFE8F5E9); // Light green container for "Good"
  static const Color onGoodContainerText = Color(0xFF388E3C); // Darker green text for "Good"
  static const Color goodProgressBarFill = Color(0xFF388E3C); // Green for progress bar (goodColor variant)


  static const Color progressBarTrack = Color(0xFFE0E0E0); // Light grey for the progress bar background track

// --- NEW: Notification specific colors ---
  static const Color notificationBorderUrgent = onErrorContainerText; // Red from error (D32F2F)
  static const Color notificationBorderGeneral = primary; // Black/dark for general
  static const Color notificationCardBackground = cardBackground; // White
  static const Color notificationReadDot = Color(0xFF1976D2); // A subtle blue dot for unread status (example)

  static const Color notificationActionPrimaryBg = primary;
  static const Color notificationActionPrimaryText = white;
  static const Color notificationActionSecondaryBorder = borderColor;
  static const Color notificationActionSecondaryText = bodyTextColor;


  // Light Mode Palette (Lumina Inventory)
  static const Color lightPrimary = Color(0xff1A1C1E);
  static const Color lightSecondary = Color(0xffF0FDF4);
  static const Color lightTertiary = Color(0xff201B17);
  static const Color lightNeutral = Color(0xffF9FAFB);

  // Dark Mode Palette (Lumina Dark)
  static const Color darkPrimary = Color(0xff7DD3FC);
  static const Color darkSecondary = Color(0xff94A3B8);
  static const Color darkTertiary = Color(0xffFEBC60);
  static const Color darkNeutral = Color(0xff121212);

// --- Old Colors from previous design (commented out for reference/removal) ---
// static const primaryColor= Color(0xff1A1C1E); // Replaced by 'primary'
// static const typeColor= Color(0xffFEFDED); // This was a light yellowish, removed as it doesn't fit the new palette. 'secondary' is a light greenish.
// static const scaffoldColor= Color(0xffDCF2F1); // Replaced by 'scaffoldBackground' (neutral)
// static const bottomNavColor= Color(0xff3c78e1); // Replaced by more specific bottomNav* colors, this was a distinct blue.
// static const textColor= Color(0xff365486); // Replaced by 'headlineTextColor', 'bodyTextColor', 'labelTextColor'
// static const whiteColor= Color(0xffffffff); // Replaced by 'white'
// static const textGreyColor= Color(0xffB3B3B3); // Replaced by more specific grey text colors
// static const borderColor= Color(0xbbd3d3d3); // Replaced by 'borderColor' with opaque value
}