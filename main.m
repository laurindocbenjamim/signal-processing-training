clear; close all; clc;

%% Setup paths and choose record

projectRoot = '/Users/eli/Desktop/signal processing project';
addpath(genpath('/Users/eli/Desktop/signal-processing-training-user02/main_db'));
cd(projectRoot);

patientFolder = 'ecg_db_patient_01';  
recordName    = 's0010_re';           

folderPath = fullfile(projectRoot, patientFolder);
datFile    = fullfile(folderPath, [recordName '.dat']);
heaFile    = fullfile(folderPath, [recordName '.hea']);

fprintf('Reading %s / %s ...\n', patientFolder, recordName);

%% Read header (.hea)

fid = fopen(heaFile, 'r');
if fid < 0
    error('Cannot open .hea file: %s', heaFile);
end
headerLine = fgetl(fid);
fclose(fid);

headerInfo = strsplit(headerLine);
numLeads   = str2double(headerInfo{2});
Fs         = str2double(headerInfo{3});
numSamples = str2double(headerInfo{4});

fprintf('numLeads = %d, Fs = %.1f Hz\n', numLeads, Fs);

%% Read raw signal from .dat (actual length)

fid = fopen(datFile, 'r');
if fid < 0
    error('Cannot open .dat file: %s', datFile);
end
data = fread(fid, [numLeads, Inf], 'int16');
fclose(fid);

[~, numSamples_real] = size(data);
tm = (0:numSamples_real-1) / Fs;

%% ===== Load Filter Designer filters (Hd objects) =====

% Band-pass filter
Sbp = load(fullfile(projectRoot, 'myfilter.mat'));
fn1 = fieldnames(Sbp);
Hd_bp = Sbp.(fn1{1});   

% Low-pass filter
Slp = load(fullfile(projectRoot, 'mylowfilter.mat'));
fn2 = fieldnames(Slp);
Hd_lp = Slp.(fn2{1});

%% Initialize feature arrays and parameters

LogEn_val     = [];
ShaEn_val     = [];
CorrDim_val   = [];
Patient_ID    = {};
Signal_Name   = {};
Lead_Index    = [];
Lead_Name     = {};
Segment_Index = [];

% DWT coefficient storage (cell arrays)
DWT_D1   = {};  
DWT_D2   = {};  
DWT_D3   = {};   
DWT_A3   = {};   

m_embed   = 3;
tau_embed = 5;
kOffset   = 10;
l_radius  = 0.5;
Nmax_corr = 2000;

segmentLength = 5;           
windowSize    = segmentLength * Fs;

fprintf('\nStarting feature extraction...\n');

%% Main loop: z-score, filters, DWT, features

globalWindowIdx = 0;  

for leadIdx = 1:numLeads
    fprintf('  Lead %d / %d ...\n', leadIdx, numLeads);

    x = double(data(leadIdx, :));  
    % ---------- z-score normalization ----------
    mu    = mean(x);
    sigma = std(x);
    if sigma == 0
        x_norm = x - mu;
    else
        x_norm = (x - mu) / sigma;
    end
    x_norm(~isfinite(x_norm)) = 0;

    % ---------- Filter Designer: Band-pass then Low-pass ----------
    x_bp = filter(Hd_bp, x_norm);   % Band-pass
    y    = filter(Hd_lp, x_bp);     % Low-pass
    y(~isfinite(y)) = 0;

    % ---------- Debug figure for Lead 1 (0–5 s) ----------
    if leadIdx == 1
        idxPlot = tm <= 5;

        figure;
        tiledlayout(3,1);

        nexttile;
        plot(tm(idxPlot), x(idxPlot));
        title('Lead 1 - Raw ECG (0–5 s)');
        xlabel('Time (s)'); ylabel('Amplitude');

        nexttile;
        plot(tm(idxPlot), x_bp(idxPlot));
        title('Lead 1 - After Band-Pass (0–5 s)');
        xlabel('Time (s)'); ylabel('Amplitude');

        nexttile;
        plot(tm(idxPlot), y(idxPlot));
        title('Lead 1 - After Low-Pass (0–5 s)');
        xlabel('Time (s)'); ylabel('Amplitude');
    end

    % ---------- Segmentation into 5-second windows ----------
    numSegments = floor(length(y) / windowSize);
    fprintf('    numSegments = %d\n', numSegments);

    for segmentIdx = 1:numSegments
        idxStart    = (segmentIdx-1)*windowSize + 1;
        idxEnd      = segmentIdx*windowSize;
        segmentData = y(idxStart:idxEnd);

        globalWindowIdx = globalWindowIdx + 1;

        %% ====== DWT (db4, level 3) for this window ======
        [c,l] = wavedec(segmentData, 3, 'db4');  

        A3 = appcoef(c,l,'db4',3);   
        D1 = detcoef(c,l,1);         
        D2 = detcoef(c,l,2);         
        D3 = detcoef(c,l,3);         

        % Save DWT coefficients in cell arrays
        DWT_D1{globalWindowIdx,1} = D1;
        DWT_D2{globalWindowIdx,1} = D2;
        DWT_D3{globalWindowIdx,1} = D3;
        DWT_A3{globalWindowIdx,1} = A3;

        % --- Debug plot of DWT for first window of lead 1 ---
        if (leadIdx == 1) && (segmentIdx == 1)
            figure;
            tiledlayout(4,1);

            nexttile;
            plot(D1);
            title('DWT Detail 1 (Window 1, Lead 1)');

            nexttile;
            plot(D2);
            title('DWT Detail 2 (Window 1, Lead 1)');

            nexttile;
            plot(D3);
            title('DWT Detail 3 (Window 1, Lead 1)');

            nexttile;
            plot(A3);
            title('DWT Approximation 3 (Window 1, Lead 1)');
        end
        %% ================================================

        % ---------- Other features on the same window ----------
        LogEn_val(end+1) = logEn(segmentData);
        ShaEn_val(end+1) = shannonEntropy(segmentData);

        x_short = segmentData;
        if length(x_short) > Nmax_corr
            x_short = x_short(1:Nmax_corr);
        end
        X = embedSignal(x_short, m_embed, tau_embed);
        CorrDim_val(end+1) = corrDim(X, l_radius, kOffset);

        % ---------- Metadata ----------
        Patient_ID{end+1}    = patientFolder;
        Signal_Name{end+1}   = recordName;
        Lead_Index(end+1)    = leadIdx;
        Lead_Name{end+1}     = sprintf('%s_L%d', recordName, leadIdx);
        Segment_Index(end+1) = segmentIdx;
    end
end

fprintf('\nFeature extraction finished.\n');

%% Build feature table (features based on raw time-domain segment)

T = table(Patient_ID', Signal_Name', Lead_Index', Lead_Name', Segment_Index', ...
          LogEn_val', ShaEn_val', CorrDim_val', ...
          'VariableNames', {'Patient_ID','Signal_Name','Lead_Index', ...
                            'Lead_Name','Segment_Index','LogEn','ShaEn','CorrDim'});

disp(' ');
disp('=== First Rows of Feature Table ===');
disp(T(1:min(10, height(T)), :));

