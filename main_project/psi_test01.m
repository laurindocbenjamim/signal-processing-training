%% Load the signal
%load("ECG_EEG_DATASET/ECGData.mat");
load("COVID-19 Database\ECG Signals\Patient_0001_Down.mat");
load("COVID-19 Database\ECG Signals\Patient_0001_Up.mat");

%% Check which variables were loaded
clc % clear the command window 
whos % check the variables loaded

%%
Patient_0001_Down = ECGch_2;


%% Apply normalization according to the equation
% The equation: x(n) = x(n) / sum(x^2(n)), then remove mean

% Normalization function
function x_norm = normalize_signal(x)
    % Step 1: Apply x(n) = x(n) / sum(x^2(n))
    sum_of_squares = sum(x.^2);
    
    % Avoid division by zero
    if sum_of_squares == 0
        error('Signal has zero energy - cannot normalize');
    end
    
    x_norm = x / sum_of_squares;
    
    % Step 2: Remove mean value
    x_norm = x_norm - mean(x_norm);
end

%% Apply normalization to ECGch_2 (which contains the ECG signal)
if exist('ECGch_2', 'var')
    fprintf('Normalizing ECGch_2 signal...\n');
    fprintf('Original signal size: %s\n', mat2str(size(ECGch_2)));
    fprintf('Original signal stats - Min: %.6f, Max: %.6f, Mean: %.6f\n', ...
        min(ECGch_2), max(ECGch_2), mean(ECGch_2));
    
    % Apply normalization
    ECGch_2_normalized = normalize_signal(ECGch_2);
    
    % Verify normalization
    energy_after = sum(ECGch_2_normalized.^2);
    fprintf('After normalization - Energy: %.6f, Mean: %.6f\n', ...
        energy_after, mean(ECGch_2_normalized));
else
    warning('ECGch_2 variable not found');
end

%% Check if there are other potential ECG signals
potential_signals = {'ecg_signal', 'ecg_signal_test', 'sinalf1', 'ecg_filtered_test'};
for i = 1:length(potential_signals)
    if exist(potential_signals{i}, 'var')
        signal_data = eval(potential_signals{i});
        fprintf('\nFound potential signal: %s\n', potential_signals{i});
        fprintf('Size: %s\n', mat2str(size(signal_data)));
        
        % Apply normalization if it's a reasonable size
        if isvector(signal_data) && length(signal_data) > 100
            normalized_name = [potential_signals{i} '_normalized'];
            eval([normalized_name ' = normalize_signal(signal_data);']);
            
            energy_after = sum(eval([normalized_name '.^2']));
            fprintf('Normalized - Energy: %.6f, Mean: %.6f\n', ...
                energy_after, mean(eval(normalized_name)));
        end
    end
end

%% Plot comparison - Original vs Normalized signals
if exist('ECGch_2', 'var') && exist('ECGch_2_normalized', 'var')
    figure('Position', [100, 100, 1200, 600]);
    
    % Plot original signal
    subplot(2,1,1);
    plot(ECGch_2);
    title('Original ECG Signal (ECGch\_2)');
    xlabel('Samples');
    ylabel('Amplitude');
    grid on;
    
    % Plot normalized signal
    subplot(2,1,2);
    plot(ECGch_2_normalized);
    title('Normalized ECG Signal (ECGch\_2\_normalized)');
    xlabel('Samples');
    ylabel('Amplitude');
    grid on;
    
    % Add some statistics to the plot
    sgtitle(sprintf('Signal Normalization - Energy: %.6f → %.6f', ...
        sum(ECGch_2.^2), sum(ECGch_2_normalized.^2)));
end

%% Display summary
fprintf('\n=== NORMALIZATION SUMMARY ===\n');
if exist('ECGch_2_normalized', 'var')
    fprintf('✓ ECGch_2_normalized created successfully\n');
    fprintf('  Original energy: %.6f\n', sum(ECGch_2.^2));
    fprintf('  Normalized energy: %.6f\n', sum(ECGch_2_normalized.^2));
    fprintf('  Normalized mean: %.6f\n', mean(ECGch_2_normalized));
end

%% Save normalized signal (optional)
% save('Patient_0001_Down_Normalized.mat', 'ECGch_2_normalized', 'Fs');
% fprintf('Normalized signal saved to Patient_0001_Down_Normalized.mat\n');
