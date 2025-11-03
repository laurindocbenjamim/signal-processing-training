%% Filter signal
function [ecgSampleFiltered] = ecg_filter_signal(dataset_signal, Fs)
fprintf('=== Filtering the Signal ===\n');
notchFilt = designfilt('bandstopiir', 'FilterOrder', 6,'HalfPowerFrequency1', 59, ...
    'HalfPowerFrequency2', 61, 'SampleRate', Fs);
ecgSampleFiltered = filtfilt(notchFilt, dataset_signal);