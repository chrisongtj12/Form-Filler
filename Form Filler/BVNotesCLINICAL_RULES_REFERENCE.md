//
//  CLINICAL_RULES_REFERENCE.md
//  BV Notes - Clinical Rules Quick Reference
//

# Clinical Rules Reference

## Vaccine Schedule Overview

### 2 Months
**Standard:**
- Hexaxim (Dose 1)

**Optional:**
- Rotarix (Dose 1) - Payment required
- PCV20 (Dose 1) - Payment required

### 4 Months
**Standard:**
- Pentaxim (Dose 1)
- PCV13 (Dose 1)

**Optional:**
- PCV15 (Dose 1) - Payment required ⚠️ Mutually exclusive with PCV13/20
- PCV20 (Dose 1) - Payment required ⚠️ Mutually exclusive with PCV13/15
- Rotarix (Dose 2) - Payment required

### 6 Months
**Standard:**
- Hexaxim (Dose 2)
- PCV13 (Dose 2)

**Optional:**
- PCV15 (Dose 2) - Payment required ⚠️ Mutually exclusive with PCV13/20
- PCV20 (Dose 2) - Payment required ⚠️ Mutually exclusive with PCV13/15

### 12 Months
**Standard:**
- MMR (Dose 1)
- Varicella (Dose 1)
- PCV13 (Booster 1)

**Optional:**
- PCV15 (Booster 1) - Payment required ⚠️ Mutually exclusive with PCV13/20
- PCV20 (Booster 1) - Payment required ⚠️ Mutually exclusive with PCV13/15

### 15 Months
**Standard:**
- MMR (Dose 2)
- Varicella (Dose 2)

**Optional:**
- Influenza (Dose 1) - ✅ No payment required
- Havrix Jr (Dose 1) - Payment required

### 18 Months
**Standard:**
- Pentaxim (Booster 1)

**Optional:**
- Influenza (Dose 1) - ✅ No payment required
- Havrix Jr (Dose 2) - Payment required

## Clinical Rules

### Rule 1: PCV Mutual Exclusion ⚠️

**What:** Only one PCV vaccine can be administered at a time.

**Why:** PCV13, PCV15, and PCV20 are different formulations of the pneumococcal conjugate vaccine. A patient should follow one vaccine series consistently.

**Implementation:**
- If PCV13 is selected, PCV15 and PCV20 are automatically deselected
- If PCV15 is selected, PCV13 and PCV20 are automatically deselected
- If PCV20 is selected, PCV13 and PCV15 are automatically deselected
- Selecting multiple PCVs simultaneously shows validation error

**Clinical Note:** 
- PCV13 covers 13 serotypes (Prevenar 13)
- PCV15 covers 15 serotypes
- PCV20 covers 20 serotypes (most comprehensive)

### Rule 2: Optional Vaccines Require Payment Mode 💳

**What:** Optional vaccines (except Influenza) require payment mode selection.

**Which vaccines:**
- Rotarix ✅
- PCV15 ✅
- PCV20 ✅
- Havrix Jr ✅
- Influenza ❌ (Exception: No payment required)

**Payment Modes:**
1. PayNow
2. CDA (Child Development Account)
3. Credit Card

**Implementation:**
- Payment mode picker appears when any optional vaccine (except Influenza) is selected
- Payment mode must be selected to clear validation
- Payment mode is hidden when no qualifying optional vaccines are selected

**Why Influenza is exempt:** Often covered by public health programs or clinic policies.

### Rule 3: At Least One Vaccine Required ✓

**What:** At least one vaccine must be selected for a valid vaccination visit.

**Implementation:**
- If no vaccines are selected, validation error is shown
- Copy to clipboard is disabled until at least one vaccine is selected

### Rule 4: Lot Number Tracking 📝

**What:** Each vaccine administered should have a lot number recorded.

**Implementation:**
- Lot number field appears when vaccine is selected
- Warning indicator shows if lot number is empty
- Warning is non-blocking (clinician can proceed)
- Global settings allow pre-filling default lot numbers

**Best Practice:** Always record lot numbers for traceability and adverse event reporting.

## Dosage Sequences

### Standard Sequences

**Primary Series (First Doses):**
- "Dose 1" - First administration
- "Dose 2" - Second administration
- "Dose 3" - Third administration (if applicable)

**Booster Series:**
- "Booster 1" - First booster
- "Booster 2" - Second booster (if applicable)

**Custom:**
- Any text can be entered if standard sequences don't apply

## CDS (Clinical Decision Support)

**Question:** "CDS Done by you during this visit?"

**Options:**
- **Yes** (Default) - Clinical decision support was provided
- **No** - CDS was not provided
- **Other** - Special circumstances (explain in notes)

**What is CDS?**
Clinical Decision Support refers to:
- Reviewing patient history
- Assessing contraindications
- Discussing benefits/risks with caregiver
- Confirming vaccine schedule compliance
- Providing post-vaccination advice

## Additional Notes Best Practices

### Recommended Documentation

**Side Effects:**
```
No immediate adverse events observed post-vaccination.
```
(Quick-add button available)

**Follow-up Plan:**
```
Next visit at [AGE] for [VACCINES].
```
(Auto-filled from milestone templates)

**Special Circumstances:**
- Allergies or sensitivities noted
- Delayed schedule reasons
- Caregiver concerns addressed
- Educational materials provided

**Payment Details (if applicable):**
```
Payment via PayNow confirmed. Transaction ID: [ID]
```

## Common Scenarios

### Scenario 1: Standard 12-Month Visit

**Vaccines:**
- ✅ MMR (Dose 1) - Lot: Z006553
- ✅ Varicella (Dose 1) - Lot: Y010272
- ✅ PCV13 (Booster 1) - Lot: MH9555

**Payment:** Not required (all standard)
**CDS:** Yes

### Scenario 2: 15-Month Visit with Optional Vaccines

**Vaccines:**
- ✅ MMR (Dose 2) - Lot: Z006553
- ✅ Varicella (Dose 2) - Lot: Y010272
- ✅ Influenza (Dose 1) - Lot: FLU-001
- ✅ Havrix Jr (Dose 1) - Lot: HAV-001

**Payment:** Required (PayNow) for Havrix Jr only
**CDS:** Yes

### Scenario 3: 4-Month Visit with PCV20

**Vaccines:**
- ✅ Pentaxim (Dose 1) - Lot: X3J474V
- ✅ PCV20 (Dose 1) - Lot: PCV20-001
- ❌ PCV13 (automatically deselected due to PCV rule)

**Payment:** Required (CDA) for PCV20
**CDS:** Yes

### Scenario 4: Delayed Schedule

**Vaccines:**
- ✅ Hexaxim (Dose 1) - Lot: X3J474V

**Additional Notes:**
```
Patient presented late for 2-month vaccinations at 3 months actual age.
Caregiver educated on importance of timely vaccination.
Catch-up schedule discussed and provided.
Next visit scheduled in 6 weeks for remaining vaccines.
```

**Payment:** Not required
**CDS:** Yes

## Validation Error Messages

### Error 1: Multiple PCV Selected
**Message:** "Only one PCV vaccine (PCV13, PCV15, or PCV20) can be selected."

**Resolution:**
1. Review which PCV series the patient is following
2. Deselect the incorrect PCV vaccines
3. Keep only one PCV type selected

### Error 2: Payment Mode Required
**Message:** "Payment mode required for optional vaccines (except Influenza)."

**Resolution:**
1. Select appropriate payment mode (PayNow, CDA, or Credit Card)
2. Or deselect optional vaccines if not being administered

### Error 3: No Vaccines Selected
**Message:** "Please select at least one vaccine."

**Resolution:**
1. Select at least one vaccine to administer
2. Or exit the form if no vaccination is being performed

## Workflow Tips

### Speed Entry
1. Select milestone first
2. Review pre-selected vaccines (from template)
3. Confirm/update lot numbers
4. Use "Add Side Effects Note" button for standard text
5. Copy and paste into Avixo

### Template Customization
1. Set default lot numbers in Global Settings
2. Configure milestone templates for your clinic's standard practice
3. Adjust follow-up plan templates to match your clinic's wording

### Quality Checks
- ✓ Lot number recorded for each vaccine
- ✓ Dosage sequence correct (Dose 1, 2, 3 or Booster 1, 2)
- ✓ Payment mode documented when required
- ✓ CDS status documented
- ✓ Follow-up plan included

## References

**Vaccine Product Names:**
- **Hexaxim**: DTaP-IPV-HepB-Hib
- **Pentaxim**: DTaP-IPV-Hib
- **PCV13**: Prevenar 13 (13-valent pneumococcal conjugate)
- **PCV15**: 15-valent pneumococcal conjugate
- **PCV20**: 20-valent pneumococcal conjugate
- **Rotarix**: Rotavirus vaccine
- **MMR**: Measles-Mumps-Rubella
- **Varicella**: Chickenpox vaccine
- **Influenza**: Seasonal flu vaccine
- **Havrix Jr**: Hepatitis A vaccine (pediatric)

---

**For clinical questions or policy clarifications, consult your clinic's medical director or vaccination protocols.**
