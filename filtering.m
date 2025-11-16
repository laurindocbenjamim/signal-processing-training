
% -------------- Bandpass filtering (combine low and high pass filters)
function y = lowpass_filter(x, fs, lowcut, highcut)
    [b,a] = butter(4, [lowcut highcut] / (fs/2), 'bandpass');
    y = filtfilt(b,a,x);
end

% -------------- Bandpass filtering (combine low and high pass filters)
function y = highpass_filter(x, fs, lowcut, highcut)
    [b,a] = butter(4, [lowcut highcut] / (fs/2), 'bandpass');
    y = filtfilt(b,a,x);
end

% -------------- Bandpass filtering (combine low and high pass filters)
function y = bandpass_filter(x, fs, lowcut, highcut)
    [b,a] = butter(4, [lowcut highcut] / (fs/2), 'bandpass');
    y = filtfilt(b,a,x);
end