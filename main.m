clc;
clear;
close all;

%% 1) Database path
base = '/Users/eli/Desktop/signal-processing-training-user02/main_db';

% List of patients and signal names
records = { ...
    'ecg_db_patient_01',   's0010_re';   ...
    'ecg_db_patient_01',   's0014lre';   ...
    'ecg_db_patient_01',   's0016lre';   ...
    'ecg_db_patient_02',   's0015lre';   ...
    'ecg_db_patient_03',   's0017lre';   ...
    'ecg_db_patient_04',   's0020are';   ...
    'ecg_db_patient_04-1', 's0020bre'    ...
    };

% Preallocate arrays for features
LogEn_val   = [];
ShaEn_val   = [];
CorrDim_val = [];
Patient_ID  = {};
Signal_Name = {};
Lead_Index  = [];
Lead_Name   = {};
Segment_Index = [];

% Parameters for Correlation Dimension
m_embed   = 3;      % embedding dimension
tau_embed = 5;      % delay 
kOffset   = 10;     % Theiler window
l_radius  = 0.5;    % radius for CorrDim

% Max number of samples for CorrDim
Nmax_corr = 2000;

% Sampling frequency (this should be extracted from the .hea file in a real scenario)
Fs = 1000;  % Example value, adjust accordingly.

%% 2) Loop over all patients and their signals
for p = 1:length(records)
    patientFolder = records{p, 1};
    signalName = records{p, 2};

    % Full path to the patient's folder
    folderPath = fullfile(base, patientFolder);

    % Path to .dat and .hea files
    datFile = fullfile(folderPath, [signalName '.dat']);
    heaFile = fullfile(folderPath, [signalName '.hea']);

    fprintf('Reading %s / %s ...\n', patientFolder, signalName);

    % 2.1) Read the header file to get the number of leads and samples
    fid = fopen(heaFile, 'r');
    if fid < 0
        error('Cannot open .hea file: %s', heaFile);
    end
    headerLine = fgetl(fid);  % Read the first line of the .hea file
    headerInfo = strsplit(headerLine);  % Split the line to extract information
    numLeads = str2double(headerInfo{2});
    numSamples = str2double(headerInfo{4});
    fclose(fid);

    % 2.2) Read raw ECG signal from the .dat file
    fid = fopen(datFile, 'r');
    if fid < 0
        error('Cannot open .dat file: %s', datFile);
    end
    data = fread(fid, [numLeads, numSamples], 'int16');  % Read the data for all leads
    fclose(fid);

    % Loop through all leads for the current signal
    for leadIdx = 1:numLeads
        x = data(leadIdx, :);  % Get the data for the current lead

        %% Signal Normalization (Robust Normalization)
        % Calculate Median manually
        med = median(x);  % Calculate the median
        % Calculate MAD (Mean Absolute Deviation) using the toolbox
        mad_val = mad(x, 1);  % Calculate MAD (Mean Absolute Deviation)

        % Robust normalization: subtract the median and divide by MAD
        x_normalized = (x - med) / mad_val;

        %% Signal Filtering (Bandpass filter between 1 and 60 Hz)
        % Use bandpass filter from Signal Processing Toolbox
        [y, b] = bandpass(x_normalized, [1 60], Fs);  % Bandpass between 1 and 60 Hz

        %% 2.3) Segmentation - Split signal into 5-second windows
        % Determine number of samples per 5-second segment
        segmentLength = 5;  % segment length in seconds
        windowSize = segmentLength * Fs;  % number of samples per segment
        
        numSegments = floor(length(y) / windowSize);  % number of 5-second segments

        for segmentIdx = 1:numSegments
            % Extract the segment
            segmentData = y((segmentIdx-1)*windowSize + 1 : segmentIdx*windowSize);
            
            %% 2.3.1) Logarithmic Entropy for the segment
            LogEn_val(end+1) = logEn(segmentData);

            %% 2.3.2) Shannon Entropy for the segment
            ShaEn_val(end+1) = shannonEntropy(segmentData);

            %% 2.3.3) Correlation Dimension for the segment
            % Use filtered signal for correlation dimension
            x_short = segmentData;  % Use the full segment
            if length(x_short) > Nmax_corr
                x_short = x_short(1:Nmax_corr);
            end
            X = embedSignal(x_short, m_embed, tau_embed);  % Embedding
            CorrDim_val(end+1) = corrDim(X, l_radius, kOffset);  % Correlation dimension

            %% 2.4) Store patient, signal, lead, and feature information
            Patient_ID{end+1} = patientFolder;
            Signal_Name{end+1} = signalName;
            Lead_Index(end+1) = leadIdx;  % Index for the lead
            Lead_Name{end+1} = [signalName '_L' num2str(leadIdx)];  % Name of the lead
            Segment_Index(end+1) = segmentIdx;  % Segment index for 5-second segments
        end
    end
end

%% 3) Create a table to store the results for all leads
T = table(Patient_ID', Signal_Name', Lead_Index', Lead_Name', Segment_Index', LogEn_val', ShaEn_val', CorrDim_val', ...
          'VariableNames', {'Patient_ID', 'Signal_Name', 'Lead_Index', 'Lead_Name', 'Segment_Index', 'LogEn', 'ShaEn', 'CorrDim'});

disp(' ')
disp('=== Final Feature Table ===')
disp(T)

%% 4) Save the results to a CSV file
outFile = fullfile(base, 'features_all.csv');  % Output path for the CSV file
writetable(T, outFile);
fprintf('\nSaved to: %s\n', outFile); 
