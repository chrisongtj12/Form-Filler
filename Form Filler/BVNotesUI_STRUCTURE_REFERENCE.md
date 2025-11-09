# BV Notes - UI Structure Reference

## Layout Overview

### iPad Layout (Side-by-Side)
```
┌─────────────────────────────────────────────────────────────────────┐
│  BV Notes                                                           │
├────────────────┬────────────────────────────────────────────────────┤
│                │                                                    │
│  Milestones    │  Visit Questions                                  │
│                │  ┌──────────────────────────────────────────────┐ │
│  ┌──────────┐  │  │ Date of Visit: [Date Picker]                 │ │
│  │ 2 Month  │  │  │ CDS done?: [Yes|No|Other]                    │ │
│  └──────────┘  │  └──────────────────────────────────────────────┘ │
│                │                                                    │
│  ┌──────────┐  │  Vaccines for 12 Month                           │
│  │ 4 Month  │  │  ┌──────────────────────────────────────────────┐ │
│  └──────────┘  │  │ ☑ MMR                Optional                 │ │
│                │  │   Lot Number: [Z006553]                       │ │
│  ┌──────────┐  │  │   Dosage: [Dose 1]                           │ │
│  │ 6 Month  │  │  ├──────────────────────────────────────────────┤ │
│  └──────────┘  │  │ ☑ Varicella                                  │ │
│                │  │   Lot Number: [Y010272]                       │ │
│  ┌──────────┐  │  │   Dosage: [Dose 1]                           │ │
│  │█12 Month █  │  ├──────────────────────────────────────────────┤ │
│  └──────────┘  │  │ ☑ Prevenar 13                                │ │
│                │  │   Lot Number: [MH9555]                        │ │
│  ┌──────────┐  │  │   Dosage: [Booster 1]                        │ │
│  │ 15 Month │  │  └──────────────────────────────────────────────┘ │
│  └──────────┘  │                                                    │
│                │  Additional Notes                                 │
│  ┌──────────┐  │  ┌──────────────────────────────────────────────┐ │
│  │ 18 Month │  │  │ No immediate adverse events observed...      │ │
│  └──────────┘  │  │                                              │ │
│                │  └──────────────────────────────────────────────┘ │
│                │  [+ Add Side Effects Note] [Reset]               │
│                │                                                    │
│  [⚙️ Vaccine   │  Generated Clinical Notes                         │
│   Settings]    │  ┌──────────────────────────────────────────────┐ │
│                │  │ Date of Visit: 09/11/2025                    │ │
│                │  │                                              │ │
│                │  │ Vaccine Administration Documentation         │ │
│                │  │                                              │ │
│                │  │ Vaccine Name     Dosage Seq    Lot Number   │ │
│                │  │ MMR              Dose 1        Z006553       │ │
│                │  │ Varicella        Dose 1        Y010272       │ │
│                │  │ Prevenar 13      Booster 1     MH9555        │ │
│                │  │                                              │ │
│                │  │ CDS Done?: Yes                               │ │
│                │  └──────────────────────────────────────────────┘ │
│                │                                                    │
│                │  [📋 Copy to Clipboard]                           │
│                │                                                    │
└────────────────┴────────────────────────────────────────────────────┘
```

### iPhone Layout (Stacked)
```
┌─────────────────────────────────────┐
│  < BV Notes                         │
├─────────────────────────────────────┤
│                                     │
│  Select Milestone                   │
│  [2m|4m|6m|12m|15m|18m]            │
│         ▲ Selected: 12m            │
│                                     │
├─────────────────────────────────────┤
│                                     │
│  Visit Questions                    │
│  ┌───────────────────────────────┐ │
│  │ Date: [09/11/2025]            │ │
│  │ CDS: [Yes|No|Other]           │ │
│  └───────────────────────────────┘ │
│                                     │
│  Vaccines for 12 Month              │
│  ┌───────────────────────────────┐ │
│  │ ☑ MMR                         │ │
│  │   Lot: [Z006553]              │ │
│  │   Dosage: [Dose 1]            │ │
│  ├───────────────────────────────┤ │
│  │ ☑ Varicella                   │ │
│  │   Lot: [Y010272]              │ │
│  │   Dosage: [Dose 1]            │ │
│  ├───────────────────────────────┤ │
│  │ ☑ Prevenar 13                 │ │
│  │   Lot: [MH9555]               │ │
│  │   Dosage: [Booster 1]         │ │
│  └───────────────────────────────┘ │
│                                     │
│  Additional Notes                   │
│  ┌───────────────────────────────┐ │
│  │ [Text editor area...]         │ │
│  └───────────────────────────────┘ │
│  [+ Side Effects] [Reset]          │
│                                     │
│  Generated Clinical Notes           │
│  ┌───────────────────────────────┐ │
│  │ Date: 09/11/2025              │ │
│  │                               │ │
│  │ [Formatted note...]           │ │
│  └───────────────────────────────┘ │
│                                     │
│  [📋 Copy to Clipboard]            │
│                                     │
└─────────────────────────────────────┘
```

## Component Hierarchy

```
BVNotesView
├── milestonesSidebar (iPad only)
│   ├── Header
│   ├── ScrollView
│   │   └── VStack
│   │       └── MilestoneListItem (×6)
│   └── Settings Button
│
├── milestonePicker (iPhone only)
│   └── Picker (segmented)
│
└── formAndOutputPane
    └── ScrollView
        └── VStack
            ├── ValidationErrorBanner
            │   └── Error messages (if any)
            │
            ├── visitQuestionsSection
            │   └── SectionCard
            │       ├── DatePicker
            │       └── CDS Picker
            │
            ├── vaccinesSection
            │   └── SectionCard
            │       └── VStack
            │           └── For each vaccine:
            │               ├── VaccineToggleRow
            │               ├── LotNumberField
            │               └── DosageSequenceField
            │
            ├── paymentModeSection (conditional)
            │   └── SectionCard
            │       └── PaymentModePicker
            │
            ├── additionalNotesSection
            │   └── SectionCard
            │       ├── TextEditor
            │       └── Buttons (Add Note, Reset)
            │
            └── generatedNotesSection
                └── ClinicalNotesPreview
                    ├── Note text (monospaced)
                    └── CopyButton
```

## Color Scheme

### Primary Colors
```
Green (BV Notes card):     #00C853 → #00A843
Blue (Primary actions):    #007AFF
Orange (Warnings):         #FF9500
Red (Errors):             #FF3B30
Gray (Disabled):          #8E8E93
```

### Background Colors
```
System Background:        White (Light) / Black (Dark)
Secondary Background:     Gray6 (Light) / Gray5 (Dark)
Card Shadow:             Black @ 5% opacity
Selected Card:           Blue gradient
```

### Text Colors
```
Primary:                 Black (Light) / White (Dark)
Secondary:               Gray
Tertiary:                Light Gray
Link:                    Blue
```

## Typography

### Sizes
```
Large Title:             34pt, Bold
Title:                   28pt, Regular
Title 2:                 22pt, Regular
Title 3:                 20pt, Regular
Headline:                17pt, Semibold
Body:                    17pt, Regular
Subheadline:             15pt, Regular
Caption:                 12pt, Regular
```

### Fonts
```
UI Text:                 SF Pro (System)
Generated Note:          SF Mono (Monospaced)
```

## Spacing

### Padding
```
Section padding:         20pt
Card padding:            16pt
Element spacing:         12pt
Tight spacing:           8pt
Minimal spacing:         4pt
```

### Corner Radius
```
Cards:                   12pt
Buttons:                 10pt
Text fields:             8pt
Badges:                  4pt
```

## Icons

### System SF Symbols
```
BV Notes card:           cross.case.fill
Milestone selected:      checkmark.circle.fill
Milestone unselected:    circle
Vaccine checked:         checkmark.square.fill
Vaccine unchecked:       square
Copy:                    doc.on.doc
Copy success:            checkmark.circle.fill
Add note:                plus.circle.fill
Reset:                   arrow.counterclockwise
Settings:                gear
Warning:                 exclamationmark.triangle.fill
Error:                   exclamationmark.circle.fill
```

## Animations

### Button Press
```
Scale: 0.98 (pressed) → 1.0 (released)
Duration: 0.15s ease-in-out
```

### Copy Success
```
Icon transition: doc.on.doc → checkmark.circle.fill
Color transition: Blue → Green
Duration: 0.2s ease-in-out
Reset delay: 2.0s
```

### Card Shadow
```
Normal: radius 5, y-offset 2, opacity 0.05
Pressed: radius 3, y-offset 1, opacity 0.03
```

## Interaction States

### Buttons
```
Normal:     Full opacity, normal shadow
Pressed:    98% scale, reduced shadow
Disabled:   60% opacity, no interaction
```

### Text Fields
```
Normal:     Gray border, white background
Focused:    Blue border, white background
Disabled:   60% opacity, gray background
Error:      Red border, pink background
```

### Checkboxes
```
Unchecked:  Gray square outline
Checked:    Blue filled square with checkmark
Disabled:   60% opacity
```

## Accessibility

### Dynamic Type
- All text scales with user preference
- Minimum touch target: 44×44pt
- Sufficient contrast ratios (WCAG AA)

### VoiceOver
- All controls properly labeled
- Semantic structure for screen readers
- Logical navigation order

### Color Blindness
- Not reliant on color alone
- Icons + text for all states
- Patterns where applicable

## Responsive Breakpoints

```
iPhone SE:              320pt width → Compact layout
iPhone Pro:             390pt width → Compact layout
iPhone Pro Max:         430pt width → Compact layout
iPad Mini:              768pt width → Regular layout
iPad Pro:               1024pt width → Regular layout

Threshold:              600pt width for layout switch
```

## Performance Notes

### Rendering
- Cards use lazy loading where applicable
- Images are SF Symbols (vector, no loading)
- No heavy animations or effects

### Memory
- State size: < 10KB per milestone
- Settings size: < 5KB
- No image caching needed

### Battery
- No continuous updates
- No background processing
- Minimal CPU usage
