# AVIXO Template Parser - User Guide

## What is this feature?

The **Paste AVIXO Template** feature allows you to copy text from AVIXO's Home Medical Notes and automatically fill in all the form fields with a single action. No more manual typing!

---

## Quick Start (3 Steps)

### Step 1: Copy Your AVIXO Notes
In AVIXO, select and copy the entire medical notes text.

### Step 2: Open Paste & Parse
Open the Speedoc Clinical Notes app and tap the green **"Paste AVIXO Template"** button on the home screen.

### Step 3: Parse & Fill
Tap **"Paste from Clipboard"** or manually paste the text, then tap **"Parse & Fill"**. Review the preview and tap **"Apply to Form"**.

---

## Where to Find This Feature

### Option 1: Home Screen (Recommended)
The easiest way to access this feature is from the home screen:

```
Home Screen
  ├── 📄 Medical Notes (blue button)
  └── 📋 Paste AVIXO Template (green button) ← Click here!
```

### Option 2: Inside Medical Notes Form
You can also access it from within the form:

```
Medical Notes Form
  ├── 📋 Paste AVIXO Template (at top)
  ├── Patient Information
  ├── Vital Signs
  └── ...
```

---

## Detailed Walkthrough

### 1. The Paste Screen

When you open the Paste & Parse screen, you'll see:

- **Instructions Box** (blue) - Explains what to do
- **Text Editor** - Where you paste your AVIXO text
- **Parse & Fill Button** (blue) - Main action button
- **Paste from Clipboard** - Quick paste from clipboard
- **Clear** - Removes all text
- **Load Sample** (purple, debug builds only) - Load example templates

### 2. Pasting Your Text

You have two options:

**Option A: Quick Paste**
1. Make sure your AVIXO notes are copied
2. Tap "Paste from Clipboard"
3. Text appears automatically

**Option B: Manual Paste**
1. Tap inside the text editor
2. Tap and hold
3. Select "Paste" from the menu

### 3. Parsing the Text

Once your text is pasted:

1. Tap **"Parse & Fill"** button
2. The app analyzes your text
3. A preview sheet appears showing all parsed fields

### 4. Review Preview

The preview shows:

- ✅ **Patient Information** - Name, NRIC, Date
- ✅ **Vital Signs** - BP, SpO2, PR, Hypocount
- ✅ **Medical History** - Past medical history
- ✅ **Presenting Complaint** - Chief complaint details
- ✅ **Physical Examination** - Exam findings
- ✅ **Issues** - Diagnosis/assessment
- ✅ **Plan** - Management plan
- ✅ **Summary** - Shows which fields were filled

### 5. Apply Changes

At the bottom of the preview:

- Tap **"Apply to Form"** - Saves all changes to your form
- Tap **"Cancel"** - Discards changes and returns

### 6. Success!

After applying:
- A summary alert shows which fields were filled
- The screen automatically closes
- You return to the Medical Notes form
- All fields are now populated!

---

## Supported Text Formats

The parser is very flexible and handles:

### ✅ Standard Format
```
Name: John Tan
NRIC: S1234567A
BP: 120/80
```

### ✅ Extra Spaces
```
name  :   John Tan
nRic :S1234567A
bp  :   120/80
```

### ✅ Different Casing
```
NAME: John Tan
nric: S1234567A
BP: 120/80
```

### ✅ Values on Next Line
```
Name:
John Tan

NRIC:
S1234567A
```

### ✅ Multi-line Sections
```
Past Medical History:
1. Hypertension
2. Diabetes
3. High cholesterol

Plan:
1. Continue medications
2. Review in 2 weeks
```

---

## Recognized Field Names

The parser understands many variations:

| What You Want | What It Recognizes |
|--------------|-------------------|
| **Patient Name** | Name, name, NAME |
| **NRIC** | NRIC, nric, IC, ic |
| **Date** | Date of Visit, Date, Visit Date |
| **Blood Pressure** | BP, bp, Blood Pressure |
| **Oxygen Saturation** | SpO2, SPO2, Spo2, O2 Sat |
| **Pulse Rate** | PR, pr, Pulse Rate, Pulse |
| **Hypocount** | Hypocount, Hypo Count, Hypo |
| **Past Medical History** | Past Medical History, PMH, Medical History |
| **Presenting Complaint** | Presenting Complaint, HPI, Complaint |
| **Physical Exam** | Physical Examination, Physical Exam, PE |
| **Issues** | Issues, Diagnosis, Assessment |
| **Plan** | Plan, Management, Treatment Plan |

---

## Tips & Tricks

### 💡 Tip 1: Copy Everything
Copy the entire AVIXO notes section - the parser will extract what it needs.

### 💡 Tip 2: Review Before Applying
Always review the preview to make sure everything parsed correctly.

### 💡 Tip 3: Empty Fields Are Safe
Empty fields won't overwrite existing data in your form - only filled fields are applied.

### 💡 Tip 4: No Perfect Format Required
Don't worry about formatting! The parser handles:
- Extra spaces
- Different line breaks
- Various spellings
- Missing sections

### 💡 Tip 5: Test With Samples
In debug builds, use the "Load Sample" button to see examples of supported formats.

---

## Troubleshooting

### Problem: Nothing Parsed
**Solution:** Check if your text has recognizable headers like "Name:", "NRIC:", "BP:", etc.

### Problem: Some Fields Missing
**Solution:** Make sure the field headers are present. The parser can only extract what it can find.

### Problem: Multi-line Sections Cut Off
**Solution:** Make sure there's proper spacing between sections. Each section should have a clear header.

### Problem: Wrong Values Parsed
**Solution:** Check for duplicate headers or nested sections. Keep the format simple.

---

## What Gets Parsed

### ✅ Always Parsed
- Patient Name
- NRIC
- Date of Visit
- Vital Signs (BP, SpO2, PR, Hypocount)

### ✅ Usually Parsed
- Past Medical History
- Presenting Complaint
- Physical Examination
- Issues/Diagnosis
- Plan/Management

### ⚠️ Not Parsed
- Client/NOK (field not in current form)
- Notes section (not mapped)
- Any custom fields not in the standard template

---

## Privacy & Security

### ✅ Your Data is Safe
- **No internet connection required** - Everything is processed locally
- **No data is sent anywhere** - Parsing happens on your device
- **No storage of pasted text** - Only the parsed results are saved
- **Clipboard access is manual** - App only reads clipboard when you tap the button

---

## Advanced Usage

### Batch Processing
If you have multiple patients:
1. Parse and fill first patient
2. Generate PDF
3. Start new form
4. Parse and fill next patient
5. Repeat!

### Partial Updates
The parser won't overwrite existing data if a field is empty:
- Already have patient info? No problem!
- Parser will only update what it finds
- Existing data stays safe

### Custom Templates
If your AVIXO format is different:
1. Try the standard parser first
2. Check the recognized field names list
3. Adjust your copy/paste to include standard headers

---

## Example Workflow

**Real-world scenario:**

1. 📱 Open AVIXO on your phone/computer
2. 📋 Select and copy the medical notes
3. 📱 Open Speedoc Clinical Notes app
4. 🟢 Tap "Paste AVIXO Template" on home screen
5. 📋 Tap "Paste from Clipboard"
6. 🔍 Review the parsed preview
7. ✅ Tap "Apply to Form"
8. ✨ Form is filled automatically!
9. 📄 Generate PDF as usual

**Time saved:** ~3-5 minutes per patient vs. manual typing!

---

## Keyboard Shortcuts

When in the text editor:

- **⌘V** (Mac) / **Ctrl+V** (iPad with keyboard) - Paste
- **⌘A** (Mac) / **Ctrl+A** (iPad with keyboard) - Select all
- **⌘X** (Mac) / **Ctrl+X** (iPad with keyboard) - Cut

---

## Known Limitations

1. **Date format** - Keeps whatever format is in the source text (no conversion)
2. **No validation** - Vital signs aren't checked for valid ranges
3. **English only** - Currently only English headers are recognized
4. **No undo** - After applying, you need to manually edit if you made a mistake

---

## Feedback & Support

Found a format that doesn't parse correctly? Let us know!

The parser is designed to be robust, but if you encounter issues:
1. Try adjusting the format to use standard headers
2. Check the "Recognized Field Names" section
3. Use the "Load Sample" feature to see working examples

---

## Version History

**v1.0** (2025-11-08)
- Initial release
- Support for standard AVIXO format
- Flexible parsing with variations
- Preview before applying
- Comprehensive test coverage

---

**Happy auto-filling! 🎉**

This feature was built to save you time and reduce manual data entry. Enjoy!
