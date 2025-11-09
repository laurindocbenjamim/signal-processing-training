% Main script to:
% 1) Read all ECG records
% 2) Compute LogEn, ShaEn, and CorrDim for each record
% 3) Create a table and save as CSV


clc; clear; close all;

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

nRec = size(records,1);      

% Preallocate arrays for three features
LogEn_val   = zeros(nRec,1);
ShaEn_val   = zeros(nRec,1);
CorrDim_val = zeros(nRec,1);

% Parameters for CorrDim
m_embed   = 3;      % embedding dimension
tau_embed = 5;      % delay
kOffset   = 10;     % Theiler window
l_radius  = 0.5;     % radius for CorrDim 

% Max number of samples to use for CorrDim
Nmax_corr = 2000;   

%% 2) Loop over all records
for k = 1:nRec

    patientFolder = records{k,1};
    rec           = records{k,2};

    % Full path to patient folder
    folderPath = fullfile(base, patientFolder);

    % Path to .dat and .hea files
    datFile = fullfile(folderPath, [rec '.dat']);
    heaFile = fullfile(folderPath, [rec '.hea']);

    fprintf('Reading %s / %s ...\n', patientFolder, rec);

   %2.1) Read raw ECG signal from .dat

    fid  = fopen(datFile, 'r');
    if fid < 0
        error('Cannot open file: %s', datFile);
    end
    x = fread(fid, 'int16');
    fclose(fid);

    %2.2) Simple normalization

    x = double(x);
    x = x - mean(x);    % remove mean

    if std(x) > 0
        x = x / std(x);    % divide by std so standard deviation becomes approximately 1
    end

   % Shortened signal for CorrDim (to save time)
    if numel(x) > Nmax_corr
        x_short = x(1:Nmax_corr);
    else
        x_short = x;
    end

    %2.3) Logarithmic Entropy (full signal)
    LogEn_val(k) = logEn(x);

    %2.4) Shannon Entropy (full signal) 
    ShaEn_val(k) = shannonEntropy(x);

    %2.5) Correlation Dimension (short signal)
    X = embedSignal(x_short, m_embed, tau_embed);

    % Compute CorrDim
    CorrDim_val(k) = corrDim(X, l_radius, kOffset);

end

%% 3) Create table
Patient_ID  = records(:,1);
Signal_Name = records(:,2);

T = table(Patient_ID, Signal_Name, LogEn_val, ShaEn_val, CorrDim_val, ...
          'VariableNames', {'Patient_ID','Signal_Name','LogEn','ShaEn','CorrDim'});

disp(' ')
disp('=== Final Feature Table ===')
disp(T)


%% 4) Save table as CSV
outFile = fullfile(base, 'features_all.csv');   % CSV for all three features
writetable(T, outFile);
fprintf('\nSaved to: %s\n', outFile);
