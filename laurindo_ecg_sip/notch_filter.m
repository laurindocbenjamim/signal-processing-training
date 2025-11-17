function y = notch_filter(x, fs, f0)

Q = 35; % quality factor
w0 = f0/(fs/2);
[b,a] = iirnotch(w0, w0/Q);
y = filtfilt(b,a,x);
