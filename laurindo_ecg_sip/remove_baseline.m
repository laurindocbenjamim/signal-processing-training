function y = remove_baseline(x, fs)

hp = 0.5;
[b,a] = butter(2, hp/(fs/2), 'high');
y = filtfilt(b,a,x);
