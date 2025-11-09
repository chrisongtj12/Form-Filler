//
//  SampleAvixoTemplate.swift
//  Speedoc Clinical Notes
//
//  Sample AVIXO templates for testing and demonstration
//

import Foundation

enum SampleAvixoTemplates {
    
    /// Complete template with all fields filled
    static let complete = """
    Name: John Tan
    NRIC: S1234567A
    Date of Visit: 2025-11-08
    Client/NOK: Mary Tan (Wife)
    
    BP: 120/80
    SpO2: 98%
    PR: 72
    Hypocount: 15
    
    Past Medical History:
    1. Hypertension - on Amlodipine 5mg daily
    2. Type 2 Diabetes Mellitus - on Metformin 500mg BD
    3. Hyperlipidemia - on Simvastatin 20mg nocte
    
    Presenting Complaint:
    Patient presents with fever (38.5°C) and productive cough for 3 days.
    Associated with mild shortness of breath on exertion.
    No chest pain. No hemoptysis.
    
    Physical Examination:
    General: Alert and conscious, appears mildly distressed
    Vital Signs: As above
    Cardiovascular: Regular rhythm, no murmurs
    Respiratory: Bilateral crepitations at lung bases, no wheeze
    Abdomen: Soft, non-tender
    
    Issues:
    1. Lower respiratory tract infection (Community-acquired pneumonia)
    2. Type 2 Diabetes Mellitus - stable
    3. Hypertension - well controlled
    
    Plan:
    1. Start Amoxicillin-Clavulanate 625mg TDS for 7 days
    2. Paracetamol 500mg QID PRN for fever
    3. Adequate hydration and rest
    4. Continue home medications
    5. Review in 3 days or earlier if symptoms worsen
    6. Red flags explained to patient and caregiver
    """
    
    /// Minimal template with only essential fields
    static let minimal = """
    Name: Jane Doe
    NRIC: S9876543B
    Date of Visit: 2025-11-08
    
    BP: 130/85
    
    Presenting Complaint:
    Headache for 2 days
    
    Plan:
    Rest and hydration
    Paracetamol PRN
    """
    
    /// Template with values on next lines
    static let nextLineValues = """
    Name:
    Alice Wong
    
    NRIC:
    S1111111C
    
    Date of Visit:
    2025-11-10
    
    BP:
    110/70
    
    SpO2:
    99%
    
    Past Medical History:
    
    Asthma since childhood, well controlled
    
    Presenting Complaint:
    
    Shortness of breath after exercise
    Mild wheeze
    
    Physical Examination:
    
    Wheeze on auscultation bilaterally
    
    Issues:
    
    Acute asthma exacerbation
    
    Plan:
    
    Salbutamol inhaler 2 puffs PRN
    Review in 1 week
    """
    
    /// Template with unusual spacing and casing
    static let variableFormatting = """
    name  :   Sarah Lim
    nRic :S3333333E
    date of visit:   2025-11-11
    
    bp  :   125/82
    SPO2:   97%
    pr:80
    HYPOCOUNT  : 12
    
    Past Medical History  :
    No known medical conditions
    
    presenting complaint:
    Cough and runny nose for 5 days
    Mild sore throat
    
    Physical Examination:
    Throat: Mild erythema
    Chest: Clear
    
    issues:
    Upper respiratory tract infection
    
    PLAN:
    Symptomatic treatment
    Lozenges for sore throat
    """
    
    /// Complex multi-line case
    static let complexMultiLine = """
    Name: Robert Chen
    NRIC: S2222222D
    Date of Visit: 2025-11-11
    Client/NOK: Linda Chen (Daughter) - 91234567
    
    BP: 145/92
    SpO2: 96%
    PR: 88
    Hypocount: 18
    
    Past Medical History:
    1. Hypertension - on Amlodipine 5mg daily, suboptimally controlled
    2. Hyperlipidemia - on Simvastatin 20mg daily
    3. Previous stroke in 2020 with residual right arm weakness
    4. Chronic kidney disease stage 3 (eGFR 45)
    5. Benign prostatic hyperplasia - on Tamsulosin
    
    Presenting Complaint:
    Patient complains of:
    - Dizziness for 1 week, worse on standing
    - New onset weakness in left arm (different from previous stroke side)
    - Difficulty walking, unsteady gait
    - No loss of consciousness
    - No headache
    - No visual changes
    - Daughter reports patient seems more confused than usual
    
    Physical Examination:
    General: Alert, oriented to person and place but not time
    Vital Signs: As documented above
    Cardiovascular: Regular rhythm, no murmurs, mild pedal edema
    Respiratory: Clear breath sounds bilaterally, no respiratory distress
    Neurological:
    - Cranial nerves intact
    - Left arm power 4/5 (new finding)
    - Right arm power 3/5 (baseline from previous stroke)
    - Lower limbs power 4/5 bilaterally
    - Sensation intact
    - Reflexes present but diminished
    Gait: Unsteady, requires walking aid, high fall risk
    
    Issues:
    1. Possible TIA (Transient Ischemic Attack) vs. evolving stroke
       - New left arm weakness concerning
       - Time window for intervention needs assessment
    2. Hypertension - suboptimally controlled
       - Current BP 145/92, target <140/90
    3. High fall risk
       - Unsteady gait, confusion, multiple comorbidities
    4. Mild cognitive impairment - new or worsening?
    
    Plan:
    1. URGENT referral to hospital neurology for assessment
       - Possible candidate for imaging and intervention
       - Family to arrange transport immediately
    2. Increase Amlodipine to 10mg daily (after neurologist review)
    3. Start Aspirin 100mg daily if TIA confirmed
    4. Blood investigations to be done at hospital:
       - FBC, RFT, electrolytes
       - Lipid panel
       - HbA1c
       - Coagulation profile
    5. Caregiver education:
       - Fall prevention strategies
       - Recognition of stroke symptoms (FAST)
       - When to call ambulance
    6. Home safety assessment arranged
    7. Follow-up in 1 week if not admitted, or earlier if symptoms worsen
    8. Continue all home medications as per current regime
    
    Notes:
    Discussed case with Dr. Lee (Neurologist) via phone.
    Family agrees with urgent hospital referral.
    Patient to be accompanied by daughter.
    """
    
    /// Template with missing sections
    static let missingSections = """
    Name: Michael Tan
    NRIC: S4444444F
    
    Presenting Complaint:
    Routine medication refill
    Feeling well, no new complaints
    
    Plan:
    Continue current medications
    Review in 3 months
    """
    
    /// Alternative header names
    static let alternativeHeaders = """
    Name: David Ng
    IC: S5555555G
    Visit Date: 2025-11-12
    
    Blood Pressure: 140/90
    Pulse: 78
    O2 Sat: 98%
    
    PMH:
    Depression diagnosed 2022
    On Sertraline 50mg daily
    
    HPI:
    Low mood for 2 weeks
    Poor sleep, early morning waking
    Loss of interest in activities
    Denies suicidal ideation
    
    PE:
    Appears sad, flat affect
    Speech slow but coherent
    No signs of self-harm
    
    Assessment:
    Major depressive episode
    PHQ-9 score: 16 (moderate-severe)
    
    Management:
    1. Increase Sertraline to 100mg daily
    2. Referral to psychiatry for consideration
    3. Psychology referral for CBT
    4. Safety planning discussed
    5. Family support mobilized
    6. Review in 2 weeks
    """
}
