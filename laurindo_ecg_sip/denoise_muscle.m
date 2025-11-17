function y = denoise_muscle(x, fs)
    % denoise_muscle - Denoises the input signal using a low-pass FIR filter
    % 
    % Syntax: y = denoise_muscle(x, fs)
    %
    % Inputs:
    %    x  - Input signal to be denoised
    %    fs - Sampling frequency of the input signal
    %
    % Outputs:
    %    y  - Denoised output signal

    fc = 40; % Cut-off frequency for the low-pass filter (in Hz)
    n = 1001; % Order of the FIR filter
    % Design the low-pass FIR filter using the specified cut-off frequency
    b = fir1(n, fc/(fs/2), 'low');
    % Apply the filter to the input signal using zero-phase filtering
    y = filtfilt(b, 1, x);
end