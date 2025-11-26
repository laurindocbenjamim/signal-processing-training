

folder = 'main_db/ecg_db_patient_01/';
%recordName = "s0010_re"; % Isto causa o erro na toolbox antiga
%recordName = convertStringsToChars("s0010_re"); % Isto causa o erro na toolbox antiga
recordName = 'main_db/ecg_db_patient_01/s0010_re';

[signal, Fs, tm] = rdsamp(recordName); 

whos signal;

[numSamples,numLeads,desired_samples,total_seconds] = calculate_seconds(signal, Fs);

fprintf('Regist read with %d samples & %d channels/Leads (columns within the matriz) \n to %d Hz %d Tot.Seconds (rows within the matriz) \n', numSamples, numLeads, Fs, total_seconds);

fprintf('Desired samples: %d \n', desired_samples);

conventional_leads = signal(:, 1:12); % Get the first 12 leads
frank_leads = signal(:, 13:15); % Get the 3 leads, 13,14 and 15 (15=columns of the matriz)


% =====================================================================================
% 2. READ THE DIAGNOSTIC (Parsing of .hea file)
% The rdsamp function focuses on numbers. To get the diagnostic text ("Label"),
% the most direct way in MATLAB is to read the .hea text file line by line.


[patient_diagnose_label, fid] = load_patient_diagnose(recordName, 'Reason for admission', 'IgnoreCase');


if strcmp(patient_diagnose_label, 'unknow')
    fprintf('Patient dignostic: %s\n', patient_diagnose_label);
else
    fprintf('Patient diagnostic: %s\n', patient_diagnose_label);
end

% Split the signal into 10 seconds

[signal_10s] = splite_sample_int_10_seconds(signal, desired_samples);

% Create a matrix to store the processed signal 
signal_normal = zeros(size(signal_10s));


% Start the signal normalization for each lead
% the process is done LEAD per LEAD (Column per Column)
for i = 1: numLeads
    lead = signal_10s(:, i); % Get the current lead

    % Remove the Mean (Zero-Mean
    lead_centered = lead - mean(lead);

    % Normalization of the power using the equation from the article
    % x(n) = lead(n) / sqrt(x^2);
    energy = sum(lead_centered .^2);

    % Avoid division by zero (if the signal is straight line)
    if energy > 0
        lead_final = lead_centered / sqrt(energy);
    else
        lead_final = lead_centered;
    end

    % Store into the final signal
    signal_normal(:, i) = lead_final;

end

    % =========================================================================
% VERIFICAÇÃO
% Prepare to plot the comparison for all leads
num_leads = 3; % Ensure num_leads is defined for the plotting function
plot_and_compare_leads(signal_10s, signal_normal, num_leads);


% Check for noise 
sig = abs(fftshift(fft(signal_normal)));
% get vector
vector = linspace(-Fs/2, Fs/2, length(sig));

figure, plot(vector, sig);

% Apluing the wavelet
% [C, L] = wavedec(sig, 3, 'sym5');
% 
% A = appcoef(C, L, 'sym5', 3);

%% Prepare to plot the comparison for all leads

function [] = plot_and_compare_leads(signal_10s,signal_normal,num_leads)
    % Prepare to plot the comparison for all leads
    for lead = 1:num_leads
        % =========================================================================
        fprintf('Sinal normalizado. Média da Lead %d: %.4f (Deve ser ~0)\n', lead, mean(signal_normal(:,lead)));
        fprintf('Energia da Lead %d: %.4f (Deve ser 1)\n', lead, sum(signal_normal(:,lead).^2));

        figure;
        subplot(2,1,1); plot(signal_10s(:,lead)); title(sprintf('Original Signal (10s) - Lead %d', lead));
        subplot(2,1,2); plot(signal_normal(:,lead)); title(sprintf('Normalized signal (Eq. 1) - Lead %d', lead));
    end
end
%%  Load the diagnose of the patient from .hea file 

function [patient_diagnose_label, fid] = load_patient_diagnose(recordName, key_word, flag)

    fid = fopen([recordName, '.hea'], 'r');
    % Check if the file was opened
    if fid == -1
        error('Failed to read .hea file');
    end

    patient_diagnose_label ='unknow';
    
    while ~feof(fid)
        tline = strtrim(fgetl(fid));
        % Look for the line that contains the clinical classification
        % In PTB it usually appears as: "# clinical classification: Myocardial infarction"
    
        % Check if the line contains the specified keyword for diagnosis
        % 'Reason for admission' is the keyword we are looking for in the .hea file
        % 'IgnoreCase' is a flag that allows the search to be case insensitive
        if contains(tline, key_word, flag, true)
            % Extract the text only after : points
            parts = split(tline, ':');
            
            fprintf('Parts found: %d\n', length(parts)); 
            
            if length(parts) >= 2
                patient_diagnose_label = strtrim(parts{2}); % Extract and trim the diagnosis label from the line
            end
            break;
        end
    end

    fclose(fid); % Close the file
end

%%

function [numSamples,numLeads,desired_samples,total_seconds] = calculate_seconds(signal, Fs)
    [numSamples,numLeads] = size(signal); % Get the number of samples and leads from the signal
    
    % Get the total of seconds and use round function to format the scientific
    % value 3.840000e+01
    total_seconds = round(numSamples / Fs);
    
    % 2. Crop to match the article (Only the first 10s)
    % 10 seconds * 1000 samples/second = 10000 samples
    desired_samples = 10 * Fs;
end


%% Splite the sample into 10 seconds
function [signal_10s] = splite_sample_int_10_seconds(signal, desired_samples)
    % Split the signal into segments of 10 seconds
    if size(signal, 1) >= desired_samples
        signal_10s = signal(1: desired_samples,:);
        fprintf('Splited signal to 10 seconds (10000 samples)\n');
    else
        warning('This signal has less than 10 seconds!');
        signal_10s = signal;
    end
end

