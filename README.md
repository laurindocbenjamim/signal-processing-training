# ECG Signal Processing

<div align="center">
  <img src="https://www.phytosudoe.eu/wp-content/uploads/sites/3/2020/06/UCP-CRP.png" alt="ESB – Catholic University of Portugal – Porto" width="200"/>
  <p><i>Project developed within the Biomedical Signal Processing course</i></p>
</div>

Project focused on electrocardiographic (ECG) signal processing, emphasizing artifact removal and signal normalization.

**Reference Paper:**  
*Cardiovascular Diseases Diagnosis Using an ECG Multi-Band Non-Linear Analysis*

---

## Authors

- **Your Full Name**  
- **Laurindo C. Benjamim** (MSc.)  
- **Bernardo Aragão Português** (MSc.)  
- **Elham Rahmaty** (MSc.)

---

## Project Workflow

1. **ECG Signal Acquisition**  
   Loading of the raw signal (e.g., `.mat`, `.txt`, or PhysioNet databases).

2. **Pre-processing**  
   - Removal of *baseline wander*  
   - Band-pass filtering (0.5 Hz – 40 Hz)

3. **Artifact Removal**  
   - Motion artifacts  
   - Power-line interference (50/60 Hz)

4. **R-Peak Detection**  
   Pan-Tompkins algorithm or wavelet transform

5. **Heartbeat Segmentation**  
   Windows centered on the R-peaks

6. **Normalization**  
   - Z-score or min-max scaling  
   - Resampling to a fixed rate (e.g., 360 Hz)

---

## MATLAB Code Example

```matlab
% Load ECG signal
load('ecg_signal.mat');

% Band-pass filtering (0.5 - 40 Hz)
fs = 360; % Sampling frequency
[b, a] = butter(4, [0.5/(fs/2) 40/(fs/2)], 'bandpass');
ecg_filt = filtfilt(b, a, ecg);

% Baseline removal
ecg_baseline = filtfilt(butter(4, 0.5/(fs/2), 'high'), 1, ecg_filt);
ecg_clean = ecg_filt - ecg_baseline;

% Z-score normalization
ecg_norm = (ecg_clean - mean(ecg_clean)) / std(ecg_clean);

% Plot
figure; plot(ecg_norm); 
title('Normalized ECG Signal'); 
xlabel('Samples'); ylabel('Amplitude');