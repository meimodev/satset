# FlowServe Hospitality Management — Design System

> **System:** Heritage Hospitality  
> **Motto:** Quiet Luxury — the digital equivalent of a five-star concierge  
> **Target:** Discerning clientele who value heritage, precision, and understated elegance  
> **Mode:** Light  
> **Generated:** 2026-04-30

---

## 1. Brand Identity

Heritage Hospitality is anchored in **Minimalism** + **Tactile** design. The interface is sophisticated and clean, avoiding flashy trends in favour of timeless editorial layouts. High-density information is packed without sacrificing breathability. The emotional response: effortless service.

**Flutter implication:** Prefer `ThemeData(useMaterial3: true)` with a custom `ColorScheme` and `TextTheme`. Avoid heavy animations — use 100ms `Curves.easeOut` for transitions.

---

## 2. Color System

### 2.1 Semantic Roles (Material 3 `ColorScheme` mapping)

| Dart Token                 | Hex       | M3 Role              | Usage                                      |
| -------------------------- | --------- | -------------------- | ------------------------------------------ |
| `primary`                  | `#322214` | `ColorScheme.primary` | Deepest brown — primary button bg, links   |
| `onPrimary`                | `#FFFFFF` | `onPrimary`           | Text/icon on primary                       |
| `primaryContainer`         | `#4A3728` | `primaryContainer`    | Tonal highlight for primary, active states |
| `onPrimaryContainer`       | `#BBA08C` | `onPrimaryContainer`  | Text/icon on primary container             |
| `secondary`                | `#6A5C4D` | `secondary`           | Secondary button fill, filters, icons      |
| `onSecondary`              | `#FFFFFF` | `onSecondary`         | Text/icon on secondary                     |
| `secondaryContainer`       | `#EFDDC9` | `secondaryContainer`  | Subtle backgrounds, chip fills             |
| `onSecondaryContainer`     | `#6E6051` | `onSecondaryContainer`| Text on secondary container                |
| `tertiary`                 | `#2F2317` | `tertiary`            | Accent elements, status indicators         |
| `onTertiary`               | `#FFFFFF` | `onTertiary`          | Text/icon on tertiary                      |
| `tertiaryContainer`        | `#46392B` | `tertiaryContainer`   | Status chip background                     |
| `onTertiaryContainer`      | `#B5A290` | `onTertiaryContainer` | Text on tertiary container                 |
| `error`                    | `#BA1A1A` | `error`               | Delete actions, error text                 |
| `onError`                  | `#FFFFFF` | `onError`             | Text/icon on error                         |
| `errorContainer`           | `#FFDAD6` | `errorContainer`      | Error snackbar background                  |
| `onErrorContainer`         | `#93000A` | `onErrorContainer`    | Text on error container                    |

### 2.2 Surface Hierarchy (7 levels of tonal depth)

| Dart Token               | Hex       | Usage                                 |
| ------------------------ | --------- | ------------------------------------- |
| `surfaceLowest`          | `#FFFFFF` | Highest contrast card (hero cards)    |
| `surface`                | `#FBF9F4` | Page background (Soft Cream)          |
| `surfaceLow`             | `#F5F3EE` | Secondary sheets, bottom nav          |
| `surfaceContainer`       | `#F0EEE9` | Elevated cards, dialogs               |
| `surfaceContainerHigh`   | `#EAE8E3` | Higher-elevation cards                |
| `surfaceContainerHighest`| `#E4E2DD` | Highest-elevation cards               |
| `surfaceDim`             | `#DBDAD5` | Disabled/inset surfaces               |

### 2.3 On-Surface Text Tokens

| Dart Token               | Hex       | Usage                         |
| ------------------------ | --------- | ----------------------------- |
| `onSurface`              | `#1B1C19` | Primary body text             |
| `onSurfaceVariant`       | `#4E453E` | Secondary body text, captions |
| `onBackground`           | `#1B1C19` | Text on `surface` background  |
| `outline`                | `#80756D` | Borders, dividers             |
| `outlineVariant`         | `#D2C4BB` | Subtle borders                |
| `surfaceTint`            | `#705A49` | Surface tint overlay          |

### 2.4 Fixed / Inverse

| Dart Token               | Hex       | Usage                          |
| ------------------------ | --------- | ------------------------------ |
| `primaryFixed`           | `#FBDDC7` | Fixed primary, never adapts    |
| `primaryFixedDim`        | `#DEC1AC` | Dimmed fixed primary           |
| `onPrimaryFixed`         | `#28180B` | Text on fixed primary          |
| `onPrimaryFixedVariant`  | `#574333` | Variant text on fixed primary  |
| `secondaryFixed`         | `#F2DFCC` | Fixed secondary                |
| `secondaryFixedDim`      | `#D6C4B1` | Dimmed fixed secondary         |
| `onSecondaryFixed`       | `#231A0E` | Text on fixed secondary        |
| `onSecondaryFixedVariant`| `#514537` | Variant text on fixed secondary|
| `tertiaryFixed`          | `#F4DFCB` | Fixed tertiary                 |
| `tertiaryFixedDim`       | `#D7C3B0` | Dimmed fixed tertiary          |
| `onTertiaryFixed`        | `#241A0E` | Text on fixed tertiary         |
| `onTertiaryFixedVariant` | `#524436` | Variant text on fixed tertiary |
| `inverseSurface`         | `#30312E` | Inverse surface (dark mode)    |
| `inverseOnSurface`       | `#F2F1EC` | Text on inverse surface        |
| `inversePrimary`         | `#DEC1AC` | Inverse primary                |

### 2.5 Override / Brand Accent

| Dart Token       | Hex       | Usage                            |
| ---------------- | --------- | -------------------------------- |
| `primaryOverride`  | `#4A3728` | Rich Brown — brand anchor        |
| `secondaryOverride`| `#A39382` | Warm Taupe — borders, outlines   |
| `tertiaryOverride` | `#D9C5B2` | Muted Cream/Champagne — fills    |
| `neutralOverride`  | `#F9F7F2` | Soft Cream — paper base          |

---

## 3. Typography Scale

**Fonts:** Noto Serif (headlines — editorial), Be Vietnam Pro (body/labels — functional data)

### Flutter `TextTheme` Mapping

| Style             | Font             | Size  | Weight | Height | Letter Spacing | Usage                         |
| ----------------- | ---------------- | ----- | ------ | ------ | -------------- | ----------------------------- |
| `displayLarge`    | Noto Serif       | 48px  | w600   | 1.1    | -0.02em        | Hero headlines, landing pages |
| `headlineLarge`   | Noto Serif       | 32px  | w500   | 1.2    | 0              | Section titles                |
| `headlineMedium`  | Noto Serif       | 24px  | w500   | 1.3    | 0              | Card titles, dialog headings  |
| `bodyLarge`       | Be Vietnam Pro   | 18px  | w400   | 1.6    | 0              | Long-form content             |
| `bodyMedium`      | Be Vietnam Pro   | 16px  | w400   | 1.5    | 0              | Primary body, list items      |
| `bodySmall`       | Be Vietnam Pro   | 14px  | w400   | 1.5    | 0              | Captions, metadata            |
| `labelLarge`      | Be Vietnam Pro   | 12px  | w600   | 1.0    | 0.1em          | Section headers (ALL-CAPS)    |
| `labelMedium`     | Be Vietnam Pro   | 12px  | w500   | 1.0    | 0              | Tags, badges, navigation      |

### Font loading in Flutter

```dart
// pubspec.yaml
fonts:
  - family: NotoSerif
    fonts:
      - asset: fonts/NotoSerif-Medium.ttf      // weight 500
      - asset: fonts/NotoSerif-SemiBold.ttf    // weight 600
  - family: BeVietnamPro
    fonts:
      - asset: fonts/BeVietnamPro-Regular.ttf  // weight 400
      - asset: fonts/BeVietnamPro-Medium.ttf   // weight 500
      - asset: fonts/BeVietnamPro-SemiBold.ttf // weight 600
```

---

## 4. Spacing Scale (8pt baseline grid)

All values in logical pixels (`px`). The base unit is **4px**.

| Token              | Value | Flutter `EdgeInsets` helper           |
| ------------------ | ----- | ------------------------------------- |
| `unit`             | 4px   | `const EdgeInsets.all(4)`             |
| `xs`               | 4px   | `symmetric(horizontal: 4)`            |
| `sm`               | 8px   | `symmetric(horizontal: 8)` / `all(8)` |
| `gutter`           | 12px  | Gutters between grid columns          |
| `md`               | 16px  | Default card padding, list spacing    |
| `lg`               | 24px  | Section gaps, outer margins           |
| `containerMargin`  | 24px  | Screen horizontal margins             |
| `xl`               | 40px  | Landing-page hero margins             |

---

## 5. Shape & Roundness

| Token             | Value | Flutter `BorderRadius`    | Usage                                  |
| ----------------- | ----- | ------------------------- | -------------------------------------- |
| Default (sm)      | 4px   | `BorderRadius.circular(4)`  | Buttons, inputs, badges                |
| Medium (md)       | 6px   | `BorderRadius.circular(6)`  | Small cards                            |
| Large (lg)        | 8px   | `BorderRadius.circular(8)`  | Room cards, experience modules         |
| Extra Large (xl)  | 12px  | `BorderRadius.circular(12)` | Modal bottomsheets, dialogs            |

> **Rule:** Avoid fully-pill shapes (`BorderRadius.circular(999)`). Keep edges precise like high-end stationery.

---

## 6. Elevation & Depth

Depth is communicated through **tonal layers**, not heavy shadows.

- **Base:** Soft Cream `#FBF9F4` is the bottom layer.
- **Card surface:** White `#FFFFFF` or Taupe `#F0ECE3` (see Surface Hierarchy §2.2).
- **Borders:** 0.5–1px in Taupe `#A39382` define boundaries with zero visual bulk.
- **Ambient shadows:** Only when necessary. Use `Color(0x264A3728)` — 15% opacity Rich Brown.

```dart
// Standard card shadow
BoxShadow(
  color: const Color(0x264A3728), // Rich Brown 15%
  blurRadius: 16,
  offset: const Offset(0, 4),
  spreadRadius: -4,
)

// Elevated card (dialog / bottomsheet)
BoxShadow(
  color: const Color(0x1A4A3728), // Rich Brown 10%
  blurRadius: 24,
  offset: const Offset(0, 8),
  spreadRadius: -6,
)
```

---

## 7. Component Specifications

### 7.1 Buttons

| Variant     | Background    | Foreground | Border              | Radius | Height |
| ----------- | ------------- | ---------- | ------------------- | ------ | ------ |
| Primary     | `#4A3728`     | `#FFFFFF`  | none                | 4px    | 48px   |
| Secondary   | `transparent` | `#4A3728`  | 1px `#A39382`       | 4px    | 48px   |
| Tertiary    | `transparent` | `#4A3728`  | none                | 4px    | 48px   |

```dart
// Flutter: Primary button
FilledButton(
  style: FilledButton.styleFrom(
    backgroundColor: const Color(0xFF4A3728),
    foregroundColor: const Color(0xFFFFFFFF),
    minimumSize: const Size(0, 48),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(4),
    ),
  ),
  onPressed: () {},
  child: const Text('Book Now'),
)

// Flutter: Secondary / Outlined
OutlinedButton(
  style: OutlinedButton.styleFrom(
    foregroundColor: const Color(0xFF4A3728),
    side: const BorderSide(color: Color(0xFFA39382)),
    minimumSize: const Size(0, 48),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(4),
    ),
  ),
  onPressed: () {},
  child: const Text('Cancel'),
)
```

Hover/selection transitions: 100ms `Curves.easeOut`.  
**Touch target minimum:** 48×48px (gloved hands).

### 7.2 Input Fields

```dart
// Flutter: Minimalist bottom-border input
TextField(
  style: const TextStyle(fontFamily: 'BeVietnamPro', fontSize: 16, height: 1.5),
  decoration: InputDecoration(
    labelText: 'Guest Name',
    labelStyle: const TextStyle(
      fontFamily: 'BeVietnamPro', fontSize: 12, fontWeight: FontWeight.w600,
      letterSpacing: 0.1, // label-caps on focus
    ),
    enabledBorder: const UnderlineInputBorder(
      borderSide: BorderSide(color: Color(0xFFA39382), width: 1),
    ),
    focusedBorder: const UnderlineInputBorder(
      borderSide: BorderSide(color: Color(0xFF4A3728), width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(vertical: 12),
  ),
)
```

- Bottom-only border, Taupe `#A39382` by default, Rich Brown `#4A3728` on focus (2px).
- Internal vertical padding: 12px.

### 7.3 Cards

```dart
// Flutter: High-density card
Container(
  decoration: BoxDecoration(
    color: const Color(0xFFFFFFFF),       // surface-lowest or FBF9F4
    border: Border.all(color: const Color(0xFFA39382), width: 1), // Taupe
    borderRadius: BorderRadius.circular(4),
    // NO shadow — tonal layering only
  ),
  padding: const EdgeInsets.all(12),      // compact internal padding
  child: ... // Be Vietnam Pro data
)
```

- **Zero shadow** (except landing-page hero cards).
- 1px Taupe border.
- Internal padding: 12px (compact).
- Content uses Be Vietnam Pro for data density.

### 7.4 Chips / Badges

```dart
// Flutter: Status chip
Chip(
  label: const Text('Confirmed', style: TextStyle(
    fontFamily: 'BeVietnamPro', fontSize: 12, fontWeight: FontWeight.w500,
  )),
  backgroundColor: const Color(0xFF46392B),        // tertiary container
  labelStyle: const TextStyle(color: Color(0xFFB5A290)), // on-tertiary-container
  side: BorderSide.none,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
)
```

- Rectangular with 2px corner radius.
- **Tertiary fill** (`#46392B`) + Primary text (`#B5A290`).
- Examples: "Confirmed", "Premium", "Pending", "VIP".

### 7.5 Lists (Divided Style)

```dart
// Flutter: Divided list row
ListTile(
  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
  minVerticalPadding: 6,
  title: Text('John Doe', style: bodyMedium),
  subtitle: Text('Room 304 — Check-in 2PM', style: bodySmall),
  leading: Icon(Icons.person_outline, color: const Color(0xFF4A3728), size: 20),
  // Divider at bottom via ListView.separated
)
// Separator:
const Divider(color: Color(0xFFA39382), height: 1, thickness: 0.5)
```

- Each row separated by a 0.5–1px Taupe hairline.
- Vertical density: 12px padding between items.
- Leading icons: 20px, 1pt stroke, Primary Rich Brown `#4A3728`.

### 7.6 Date Pickers (Hospitality)

```dart
// Flutter: Use showDatePicker with custom header
showDatePicker(
  context: context,
  builder: (context, child) {
    return Theme(
      data: Theme.of(context).copyWith(
        datePickerTheme: DatePickerThemeData(
          headerForegroundColor: const Color(0xFFFFFFFF),
          headerBackgroundColor: const Color(0xFF4A3728),
          // Noto Serif headline in header
          headerHeadlineStyle: const TextStyle(
            fontFamily: 'NotoSerif', fontSize: 32, fontWeight: FontWeight.w500,
          ),
        ),
      ),
      child: child!,
    );
  },
)
```

- Month/year header uses Noto Serif headline (`headlineLarge`).
- Header background: Rich Brown `#4A3728` with white text.

### 7.7 Amenity Icons

- 1pt stroke width.
- 20–24px size.
- Color: Primary Rich Brown `#4A3728`.
- Prefer `Icons.outlined` variants or custom `IconData` with `weight: 100`.

```dart
Icon(Icons.wifi_outlined, color: const Color(0xFF4A3728), size: 20, weight: 100)
```

---

## 8. Layout Grid

| Platform | Columns | Gutters | Outer Margin        |
| -------- | ------- | ------- | ------------------- |
| Mobile   | 4       | 12px    | 24px (`containerMargin`) |
| Tablet   | 8       | 12px    | 24px                |
| Desktop  | 12      | 12px    | 40px (`xl`)         |

- **Baseline rhythm:** 8pt (all component heights should round to multiples of 8).
- **Internal density:** Padding inside components uses `sm` (8px) or `md` (16px).
- **External margins:** Landing/hero screens use `xl` (40px) for editorial feel.

```dart
// Flutter: Mobile layout padding
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 24), // container-margin
  child: Column(
    children: [
      SizedBox(height: 16), // md
      // ... content with 8/16px internal padding
    ],
  ),
)
```

---

## 9. Full `ThemeData` Boilerplate

```dart
import 'package:flutter/material.dart';

ThemeData heritageTheme() {
  const primary = Color(0xFF322214);
  const primaryContainer = Color(0xFF4A3728);
  const secondary = Color(0xFF6A5C4D);
  const secondaryContainer = Color(0xFFEFDDC9);
  const tertiary = Color(0xFF2F2317);
  const tertiaryContainer = Color(0xFF46392B);
  const error = Color(0xFFBA1A1A);

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: primary,
      onPrimary: Color(0xFFFFFFFF),
      primaryContainer: primaryContainer,
      onPrimaryContainer: Color(0xFFBBA08C),
      secondary: secondary,
      onSecondary: Color(0xFFFFFFFF),
      secondaryContainer: secondaryContainer,
      onSecondaryContainer: Color(0xFF6E6051),
      tertiary: tertiary,
      onTertiary: Color(0xFFFFFFFF),
      tertiaryContainer: tertiaryContainer,
      onTertiaryContainer: Color(0xFFB5A290),
      error: error,
      onError: Color(0xFFFFFFFF),
      errorContainer: Color(0xFFFFDAD6),
      onErrorContainer: Color(0xFF93000A),
      surface: Color(0xFFFBF9F4),
      onSurface: Color(0xFF1B1C19),
      onSurfaceVariant: Color(0xFF4E453E),
      outline: Color(0xFF80756D),
      outlineVariant: Color(0xFFD2C4BB),
      surfaceTint: Color(0xFF705A49),
      inverseSurface: Color(0xFF30312E),
      inversePrimary: Color(0xFFDEC1AC),
    ),
    scaffoldBackgroundColor: const Color(0xFFFBF9F4),
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontFamily: 'NotoSerif', fontSize: 48, fontWeight: FontWeight.w600, height: 1.1, letterSpacing: -0.02),
      headlineLarge: TextStyle(fontFamily: 'NotoSerif', fontSize: 32, fontWeight: FontWeight.w500, height: 1.2),
      headlineMedium: TextStyle(fontFamily: 'NotoSerif', fontSize: 24, fontWeight: FontWeight.w500, height: 1.3),
      bodyLarge: TextStyle(fontFamily: 'BeVietnamPro', fontSize: 18, fontWeight: FontWeight.w400, height: 1.6),
      bodyMedium: TextStyle(fontFamily: 'BeVietnamPro', fontSize: 16, fontWeight: FontWeight.w400, height: 1.5),
      bodySmall: TextStyle(fontFamily: 'BeVietnamPro', fontSize: 14, fontWeight: FontWeight.w400, height: 1.5),
      labelLarge: TextStyle(fontFamily: 'BeVietnamPro', fontSize: 12, fontWeight: FontWeight.w600, height: 1.0, letterSpacing: 0.1),
      labelMedium: TextStyle(fontFamily: 'BeVietnamPro', fontSize: 12, fontWeight: FontWeight.w500, height: 1.0),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFFA39382),
      thickness: 0.5,
      space: 12,
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFFFFFFFF),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xFFA39382), width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      margin: EdgeInsets.zero,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF4A3728),
        foregroundColor: const Color(0xFFFFFFFF),
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF4A3728),
        side: const BorderSide(color: Color(0xFFA39382)),
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: false,
      border: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFA39382))),
      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFA39382))),
      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF4A3728), width: 2)),
      labelStyle: TextStyle(fontFamily: 'BeVietnamPro', fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.1),
      contentPadding: EdgeInsets.symmetric(vertical: 12),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFF46392B),
      labelStyle: const TextStyle(fontFamily: 'BeVietnamPro', fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFFB5A290)),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    ),
    datePickerTheme: DatePickerThemeData(
      headerForegroundColor: const Color(0xFFFFFFFF),
      headerBackgroundColor: const Color(0xFF4A3728),
      headerHeadlineStyle: const TextStyle(fontFamily: 'NotoSerif', fontSize: 32, fontWeight: FontWeight.w500),
    ),
  );
}
```

---

## 10. CSS Custom Properties (Tailwind / Web reference)

```css
:root {
  /* Surface */
  --color-surface-lowest: #ffffff;
  --color-surface: #fbf9f4;
  --color-surface-low: #f5f3ee;
  --color-surface-container: #f0eee9;
  --color-surface-container-high: #eae8e3;
  --color-surface-container-highest: #e4e2dd;
  --color-surface-dim: #dbdad5;

  /* Primary */
  --color-primary: #322214;
  --color-on-primary: #ffffff;
  --color-primary-container: #4a3728;
  --color-on-primary-container: #bba08c;

  /* Secondary */
  --color-secondary: #6a5c4d;
  --color-on-secondary: #ffffff;
  --color-secondary-container: #efddc9;
  --color-on-secondary-container: #6e6051;

  /* Tertiary */
  --color-tertiary: #2f2317;
  --color-on-tertiary: #ffffff;
  --color-tertiary-container: #46392b;
  --color-on-tertiary-container: #b5a290;

  /* Error */
  --color-error: #ba1a1a;
  --color-on-error: #ffffff;
  --color-error-container: #ffdad6;
  --color-on-error-container: #93000a;

  /* Text */
  --color-on-surface: #1b1c19;
  --color-on-surface-variant: #4e453e;
  --color-outline: #80756d;
  --color-outline-variant: #d2c4bb;

  /* Spacing */
  --space-xs: 4px;
  --space-sm: 8px;
  --space-gutter: 12px;
  --space-md: 16px;
  --space-lg: 24px;
  --space-container-margin: 24px;
  --space-xl: 40px;

  /* Radius */
  --radius-sm: 4px;
  --radius-md: 6px;
  --radius-lg: 8px;
  --radius-xl: 12px;

  /* Typography */
  --font-serif: "Noto Serif", serif;
  --font-sans: "Be Vietnam Pro", sans-serif;
}
```

---

## 11. Key Rules (Quick Reference)

| Rule                              | Value                                      |
| --------------------------------- | ------------------------------------------ |
| **Color mode**                    | Light only                                 |
| **Headline font**                 | Noto Serif (editorial)                     |
| **Body / UI font**                | Be Vietnam Pro (functional data)           |
| **Corner radius**                 | 4px default, 8px for large cards           |
| **Button height**                 | 48px (touch target minimum)                |
| **Card shadow**                   | Zero (use tonal layers + 1px Taupe border) |
| **Border color**                  | `#A39382` (Taupe), 0.5–1px                 |
| **Ambient shadow** (if needed)    | Rich Brown 15% opacity, blur 16, offset 4  |
| **Baseline grid**                 | 8pt                                        |
| **Mobile columns**                | 4, gutter 12px, margin 24px                |
| **Transitions**                   | 100ms ease-out                             |
| **Icons**                         | 1pt stroke, 20–24px, Rich Brown            |

---

## 12. Screen Inventory (Stitch Project)

| Screen                              | ID                                   | Dimensions | Type   |
| ----------------------------------- | ------------------------------------ | ---------- | ------ |
| Zone Map — Vibrant Light            | `88ca8aeded2a40c4be7aba97d2c1fdf8` | 780×2730   | Mobile |
| Admin — Heritage High Density       | `97f2d0da3a3b44d18d853c6683b255e9` | 780×1996   | Mobile |
| Tickets — Heritage High Density     | `bf3eceb732df49bfb77e5cbc84e95dff` | 780×1768   | Mobile |
| Product Matrix — Heritage High Density | `2ab4766a360945eca220319dd7817453` | 780×1768   | Mobile |
| Design System                       | `assets/30f84b7006c94132bddf733376950d5f` | 960×540    | Asset  |

---

*This document is the single source of truth for the FlowServe Heritage Hospitality design language. All UI decisions should reference the tokens and component specs defined here.*
