function y = bandpass_ecg(x, fs, pass)

[b,a] = butter(4, pass/(fs/2), 'bandpass');
y = filtfilt(b,a,x);
