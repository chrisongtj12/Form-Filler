# BV Notes (Baby Vaccination Notes)

A comprehensive baby vaccination notes feature for generating Avixo-ready clinical documentation.

## Overview

BV Notes provides a streamlined workflow for documenting baby vaccination visits at key milestones (2, 4, 6, 12, 15, and 18 months). The feature enforces clinical rules, manages optional vaccines with payment tracking, and generates properly formatted clinical notes ready to copy into Avixo.

## Features

### Core Functionality

- **Milestone-based workflow**: Select from 6 key vaccination milestones (2m, 4m, 6m, 12m, 15m, 18m)
- **Smart vaccine selection**: Only shows applicable vaccines for each milestone
- **PCV mutual exclusion**: Enforces rule that only one PCV vaccine (13/15/20) can be selected
- **Payment mode tracking**: Required for optional vaccines (except Influenza)
- **Auto-save**: Automatically persists state per milestone
- **Copy to clipboard**: One-click copy of formatted clinical notes

### UI Design

- **iPad**: Side-by-side layout with milestone sidebar + form/output pane
- **iPhone**: Stacked layout with milestone picker + scrollable form
- **Modern cards**: Clean card-based sections with subtle shadows
- **Validation feedback**: Real-time error banners for rule violations
- **Copy confirmation**: Visual feedback with checkmark animation

### Global Settings

- **Lot numbers**: Set default lot numbers for all vaccines
- **Milestone templates**: Configure per-milestone defaults
  - Which vaccines are pre-selected
  - Default dosage sequences
  - Follow-up plan templates

## File Structure

```
BVNotes/
├── Models.swift                    # Data models (Milestone, Vaccine, BVState, etc.)
├── BVNotesViewModel.swift          # State management & business logic
├── BVNotesView.swift              # Main UI (2-pane layout)
├── Components.swift                # Reusable UI components
├── NotesComposer.swift            # Note generation & validation functions
├── VaccineSettingsSheet.swift     # Global settings modal
└── BVNotesTests.swift             # Unit tests

Home/
└── ContentView+BVEntry.swift      # Home screen integration
```

## Milestones & Vaccines

### Milestone Configuration

| Milestone | Vaccines | Optional | Payment Required |
|-----------|----------|----------|------------------|
| 2 Month   | Hexaxim, Rotarix*, PCV20* | Rotarix, PCV20 | Rotarix, PCV20 |
| 4 Month   | Pentaxim, PCV13, PCV15*, PCV20*, Rotarix* | PCV15, PCV20, Rotarix | PCV15, PCV20, Rotarix |
| 6 Month   | Hexaxim, PCV13, PCV15*, PCV20* | PCV15, PCV20 | PCV15, PCV20 |
| 12 Month  | MMR, Varicella, PCV13, PCV15*, PCV20* | PCV15, PCV20 | PCV15, PCV20 |
| 15 Month  | MMR, Varicella, Influenza*, Havrix Jr* | All except MMR, Varicella | Havrix Jr only |
| 18 Month  | Pentaxim, Influenza*, Havrix Jr* | Influenza, Havrix Jr | Havrix Jr only |

*Optional vaccines

### Validation Rules

1. **PCV Mutual Exclusion**: Only one of PCV13, PCV15, or PCV20 can be selected at a time
2. **Payment Mode**: Required when any optional vaccine (except Influenza) is selected
3. **Minimum Selection**: At least one vaccine must be selected
4. **Lot Numbers**: Warning indicator if lot number is empty (not blocking)

## Usage Workflow

### For Clinicians

1. **Select Milestone**: Tap the age milestone (e.g., "12 Month")
2. **Fill Visit Details**:
   - Date of visit (defaults to today)
   - CDS status (Yes/No/Other)
3. **Select Vaccines**:
   - Check vaccines to administer
   - Enter/confirm lot numbers
   - Adjust dosage sequences if needed
4. **Payment Mode** (if applicable):
   - Appears automatically when optional vaccines are selected
   - Choose PayNow, CDA, or Credit Card
5. **Additional Notes**:
   - Free-text area for any notes
   - Quick-add "Side Effects Note" button
6. **Review & Copy**:
   - View generated clinical note in formatted table
   - Tap "Copy to Clipboard"
   - Paste into Avixo

### Managing Settings

1. Tap "Vaccine Settings" button (bottom-left on iPad, via toolbar on iPhone)
2. **Global Lot Numbers**:
   - Set default lot numbers for each vaccine
   - These pre-fill when creating new records
3. **Milestone Templates**:
   - Select a milestone
   - Toggle default vaccine selections
   - Set default dosage sequences
   - Configure follow-up plan template
4. **Restore Defaults**: Reset all settings to factory defaults

## Generated Note Format

```
Date of Visit: 09/11/2025

Vaccine Administration Documentation

Vaccine Name          Dosage Sequence   Lot Number
---------------------------------------------------
MMR                   Dose 1            Z006553
Prevenar 13           Booster 1         MH9555
Varicella             Dose 1            Y010272

CDS Done by you during this visit?: Yes

Payment Mode (for optional vaccines): PayNow

Additional Notes:
No immediate adverse events observed post-vaccination.

Next visit at 15 months for nurse visit: MMR dose 2, Varicella dose 2, and Influenza.
```

## Data Persistence

### Per-Milestone State
- Saved to: `Documents/bv_state_<milestone>.json`
- Includes: selections, lot numbers, dosage sequences, notes, payment mode
- Auto-saves on every change

### Global Settings
- Saved to: `Documents/bv_settings.json`
- Includes: default lot numbers, milestone templates
- Persists across app launches

### Last Used Milestone
- Saved to: `UserDefaults` key `bv_last_milestone`
- Restores last viewed milestone on app launch

## Testing

Run unit tests with:
- Xcode: Product → Test
- Command line: `swift test`

Test coverage includes:
- Validation rules (PCV exclusion, payment requirements)
- Note composition (formatting, content inclusion)
- Milestone configuration (vaccine lists, optional flags)
- Global settings (defaults, persistence)

## Code Examples

### Validation

```swift
let errors = validateSelections(state)
if errors.isEmpty {
    // Valid state
} else {
    // Show errors to user
    for error in errors {
        print(error.message)
    }
}
```

### Note Generation

```swift
let clinicalNote = composeClinicalNote(for: state)
UIPasteboard.general.string = clinicalNote
```

### Toggle Vaccine

```swift
viewModel.toggleVaccineSelection(vaccine: .mmr, isSelected: true)
// Automatically handles PCV mutual exclusion if applicable
```

## Design Patterns

- **MVVM-lite**: `BVNotesViewModel` manages state, views are declarative
- **Pure functions**: Validation and note composition are side-effect-free
- **Unidirectional data flow**: UI → ViewModel → State → UI
- **Codable persistence**: All models conform to `Codable` for JSON serialization
- **Identifiable enums**: Using `CaseIterable` + `Identifiable` for type-safe iteration

## Future Enhancements

Potential improvements:
- [ ] Barcode scanner for lot numbers
- [ ] Photo capture for vaccination cards
- [ ] Export to PDF
- [ ] Cloud sync between devices
- [ ] Batch operations for multiple patients
- [ ] Vaccine expiry date tracking
- [ ] Integration with inventory management

## Troubleshooting

**Problem**: Lot numbers not pre-filling
- **Solution**: Check Global Settings → Vaccine Lot Numbers are set

**Problem**: Payment mode not showing
- **Solution**: Ensure at least one optional vaccine (except Influenza) is selected

**Problem**: Cannot select multiple PCV vaccines
- **Solution**: This is intentional - only one PCV type allowed per clinical guidelines

**Problem**: State not persisting between sessions
- **Solution**: Check app has write permissions to Documents directory

## Credits

Built with SwiftUI for iOS 16+
No third-party dependencies
Follows Apple Human Interface Guidelines
