### Used Theorem and Equations of the Signal Processing 
Below is a **clean, structured documentation** describing *every major signal-processing equation and method* used in your full ECG-processing pipeline.

---

# 📘 **ECG Processing Pipeline — Technical Documentation**

This documentation describes the **mathematical foundations** behind each signal-processing step implemented in your ECG batch-processing script, including filtering, normalization, segmentation, feature extraction, and spectral/fractal analysis.

---

# 1. 📡 **Signal Acquisition & Header Parsing**

ECG records are stored in **WFDB format**, with information in a `.hea` header file:

* Sampling frequency:$$\mathbf{F}_s \text{ Hz}$$

* Number of samples: $$\text{N} $$

* For each lead (i):

  $$* Gain (G_i)$$
  $$* Baseline (B_i)$$


### 1.1 Conversion from ADC counts to millivolts

Raw signal $$(x_i[n])$$ is converted to mV by:

$$\text{ECG}_i[n] = \frac{x_i[n] - B_i}{G_i}$$

This ensures that each lead has proper physical units.

---

# 2. 🔧 **Preprocessing**

## 2.1 **Baseline Wander Removal (High-pass filter)**

Baseline drift is removed using a **Butterworth high-pass filter**:

$$
H(z) = \frac{b_0 + b_1 z^{-1} + b_2 z^{-2}}{1 + a_1 z^{-1} + a_2 z^{-2}}
$$

Typical cutoff:

$$
f_c = 0.5;\text{Hz}
$$

Digital filtering operation:

$$
y[n] = \sum_{k=0}^{M} b_k x[n-k] - \sum_{m=1}^{N} a_m y[n-m]
$$

---

## 2.2 **Power-Line Noise Removal (Notch Filter)**


If the power-line frequency is $$(f_0 = 50\text{ or }60\text{ Hz})$$ 

$$
H_{\text{notch}}(e^{j\omega}) = 1 - \frac{2\cos(\omega_0)}{1 - 2r\cos(\omega_0) + r^2} e^{-j\omega}
$$

where: 
$$\omega_0 = 2\pi f_0 / F_s$$

---

## 2.3 **Robust Normalization (Median + MAD)**

The robust normalization uses the **median** and **median absolute deviation (MAD)**:

$$\text{m = median}(x[n])$$

$$\text{MAD} = \text{median}(|x[n] - m|)$$

Normalized signal:

$$
x_{\text{norm}}[n] = \frac{x[n] - m}{\text{MAD}}
$$

This is resistant to outliers and artifacts.

---

# 3. ✂ **Segmentation**

Signals are divided into fixed-length windows:

$$
\text{Segment length in samples} = L = T_{\text{seg}} \cdot F_s
$$

If (x[n]) is the full signal:

$$
x_k[n] = x[n + kL], \qquad n = 0,1,\dots,L-1
$$

Each segment gets indexed:

$$
k = 1, 2, \dots, \left\lfloor \frac{N}{L} \right\rfloor
$$

Feature extraction is applied **per segment**.

---

# 4. ⚙️ **R-Peak Detection & HRV Features**

## 4.1 **R-Peak Detection (Pan–Tompkins principles)**

Although simplified filters are used, the basic operation is:

1. Bandpass filtering
2. Derivative
3. Squaring
4. Moving window integration

Energy function:
$$
\text{E[n] = \sum_{k=0}^{W-1} x^2[n - k]}
$$

Peaks above a threshold are labeled as R-peaks.

---

## 4.2 **Heart Rate (BPM)**

If (RR_i) is the interval between peaks:

$$
\text{BPM} = \frac{60}{\overline{RR}}
$$

---

## 4.3 **SDNN (Standard Deviation of RR Intervals)**

$$
\text{SDNN} = \sqrt{ \frac{1}{M-1} \sum_{i=1}^{M} (RR_i - \overline{RR})^2 }
$$

---

# 5. 📉 **Signal Compression (Downsampling)**

Given a compression factor (C):

$$
x_{\text{comp}}[n] = x[nC]
$$

This reduces sample count while preserving general morphology.

Plots compare original vs. compressed signals.

---

# 6. 📈 **Wavelet Energy Features**

Using a discrete wavelet transform (DWT):

$$
x[n] \rightarrow A_j[n], D_j[n]
$$

Energy of detail coefficients:

$$
E_{D_j} = \sum_{n} D_j[n]^2
$$

Total energy:

$$
E_{\text{total}} = \sum_{j} E_{D_j}
$$

---

# 7. 🧮 **Fractal Features**

## 7.1 **Hurst Exponent (Rescaled Range Analysis)**

The rescaled range (R/S) over window size (n):

$$
\frac{R(n)}{S(n)} \propto n^H
$$

Taking logs:

$$
\log(R/S) = H \log(n) + C
$$

Slope of fitted line gives (H).

---

## 7.2 **Higuchi Fractal Dimension**

We build subsampled sequences:

$$
X_m^k = { x[m], x[m+k], x[m+2k], \dots }
$$

Compute curve length:

$$
L_m(k) = \frac{ (N-1)}{ \left\lfloor \frac{N-m}{k} \right\rfloor k^2 }
\sum_{i=1}^{\left\lfloor \frac{N-m}{k} \right\rfloor} |x[m + ik] - x[m + (i-1)k]|
$$

Average over (m) values:

$$
L(k) = \frac{1}{k} \sum_{m=1}^{k} L_m(k)
$$

Fractal dimension (D) is slope:

$$\text{\log(L(k)) = -D \log(k) + C}$$
---

## 7.3 **Katz Fractal Dimension**
$$
D = \frac{\log(n)}{\log(n) + \log(d/L)}
$$

where

* (n): number of samples
* (d): maximum distance from first point
* (L): total curve length

---

# 8. 🔊 **Frequency Analysis**

Using the Fourier Transform:
$$
\text{X[k] = \sum_{n=0}^{N-1} x[n] e^{-j2\pi kn/N}}
$$

Power spectrum:

$$
P[k] = |X[k]|^2
$$

Useful for:

* power-line noise validation
* frequency content visualization
* compression and normalization evaluation

---

# 9. 💾 **Data Saving Strategy**

The script stores:

### Per Signal

```
signal_name_features.csv
signal_name_segment_01.csv
signal_name_segment_02.csv
...
```

### Per Patient

```
Patient_ID/
    signal1_features.csv
    signal2_features.csv
```

### Global Summary

```
FEATURE_MASTER_SUMMARY.csv
```

---

# ✔️ Documentation Complete

If you want, I can also provide:

### ✅ A PDF user manual

### ✅ Flowcharts or diagrams for the processing pipeline

### ✅ A LaTeX-formatted scientific documentation

### ✅ A short version for your thesis or publication

Just tell me **"generate PDF"**, **"create diagram"**, or **"create thesis section"**.
 