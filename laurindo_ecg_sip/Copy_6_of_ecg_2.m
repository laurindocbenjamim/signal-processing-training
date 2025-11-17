% ======================================================================
%   Complete Modular ECG Batch Processing Framework
%   Features:
%   - Automatic header parsing
%   - Artifact removal
%   - Robust normalization
%   - Feature extraction (time, wavelet, fractals)
%   - Signal compression & visualization
%   - Total signals & leads reporting
%   - Signal Analyzer toolbox integration
% ======================================================================
run_ecg_batch_processing();

%% ======================= MAIN SCRIPT ================================
function run_ecg_batch_processing()
clc; clear; close all;


BASE_DIR = '../main_db/';
Patient_Dirs = {'ecg_db_patient_01', ...
'ecg_db_patient_02', 'ecg_db_patient_03', };


OUTPUT_DIR = 'Extracted_Features_Batch';
if ~exist(OUTPUT_DIR, 'dir'), mkdir(OUTPUT_DIR); end


Feature_Master = table();


total_patients = length(Patient_Dirs);
total_signals = 0;
total_leads_processed = 0;


disp('=== STARTING BATCH ECG PROCESSING ===');


for p = 1:length(Patient_Dirs)
patient_path = fullfile(BASE_DIR, Patient_Dirs{p});
[Feature_Master, sig_count, leads_count] = process_patient_folder(patient_path, Patient_Dirs{p}, Feature_Master, OUTPUT_DIR);
total_signals = total_signals + sig_count;
total_leads_processed = total_leads_processed + leads_count;
end


fprintf('Total Patients: %d\n', total_patients);
fprintf('Total Signals Processed: %d\n', total_signals);
fprintf('Total Leads Processed: %d\n', total_leads_processed);


disp('=== BATCH PROCESSING COMPLETE ===');
disp(Feature_Master(1:min(5, height(Feature_Master)), :));


writetable(Feature_Master, fullfile(OUTPUT_DIR, 'ECG_Features_Master_Summary.csv'));
end

%% ======================= PATIENT PROCESSOR UPDATED ====================

function [Feature_Master, signal_counter, lead_count_total] = process_patient_folder(patient_path, patient_id, Feature_Master, OUTPUT_DIR)
files = dir(fullfile(patient_path, '*.hea'));
if isempty(files)
warning('No .hea files in %s', patient_path);
signal_counter = 0;
lead_count_total = 0;
return;
end


signal_counter = 0;
lead_count_total = 0;


patient_output_dir = fullfile(OUTPUT_DIR, patient_id);
if ~exist(patient_output_dir, 'dir'), mkdir(patient_output_dir); end


for k = 1:length(files)
signal_name = erase(files(k).name, '.hea');
header_file = fullfile(patient_path, [signal_name '.hea']);


[Fs, num_samples, lead_names, gains, baselines] = parse_wfdb_header(header_file);


signal_feature_table = table();

for lead_idx = 1:length(lead_names)
[t, ecg_mV, success] = read_ecg_signal(patient_path, signal_name, num_samples, lead_idx, gains(lead_idx), baselines(lead_idx), Fs);
if ~success, continue; end


ecg_filtered = remove_artefacts_2(ecg_mV, Fs);
ecg_norm = robust_normalize(ecg_filtered);


% --- Signal Segmentation ---
segment_length_s = 10; % 10-second segments
segment_samples = segment_length_s * Fs;
num_segments = floor(length(ecg_norm)/segment_samples);
for seg_idx = 1:num_segments
seg_start = (seg_idx-1)*segment_samples + 1;
seg_end = seg_idx*segment_samples;
segment_ecg = ecg_norm(seg_start:seg_end);
segment_t = t(seg_start:seg_end);


% Feature extraction per segment
features = extract_features_all(segment_ecg, segment_t, Fs);


% Build row
row = table({patient_id}, {signal_name}, lead_idx, {lead_names{lead_idx}}, seg_idx, features.BPM, features.SDNN, ...
features.EnTotal, features.EnD5, features.Hurst, features.Higuchi, features.Katz, ...
'VariableNames', {'Patient_ID','Signal_Name','Lead_Index','Lead_Name','Segment_Index','BPM_avg','SDNN','En_Total','En_D5','Hurst_Exp','Higuchi_FD','Katz_FD'});


Feature_Master = [Feature_Master; row];
signal_feature_table = [signal_feature_table; row];
end


% Visualization
plot_ecg_overview(t, ecg_mV, ecg_filtered, [signal_name ' - ' lead_names{lead_idx}]);
factor = 5;
[ecg_comp, ratio] = compress_signal(ecg_filtered, factor);
t_comp = t(1:factor:end);
plot_compression(t, ecg_filtered, t_comp, ecg_comp, [signal_name ' - ' lead_names{lead_idx}]);


signal_counter = signal_counter + 1;
lead_count_total = lead_count_total + 1;
end

% Save per-signal feature table
if ~isempty(signal_feature_table)
signal_output_file = fullfile(patient_output_dir, [signal_name '_features.csv']);
writetable(signal_feature_table, signal_output_file);
end
end
end
%% ======================= HEADER PARSER ===============================
function [Fs, num_samples, lead_names, gains, baselines] = parse_wfdb_header(header_file)
    fid = fopen(header_file,'r');
    tline = fgetl(fid);
    header_info = strsplit(tline);
    Fs = str2double(header_info{3});
    num_samples = str2double(header_info{4});
    num_leads = str2double(header_info{2});

    lead_names = cell(1,num_leads);
    gains = zeros(1,num_leads);
    baselines = zeros(1,num_leads);

    for i = 1:num_leads
        line = fgetl(fid);
        parts = strsplit(strtrim(line));
        lead_names{i} = parts{1};
        gains(i) = str2double(parts{2});
        baselines(i) = str2double(parts{3});
    end
    fclose(fid);
end

%% ======================= SIGNAL READER ===============================
function [t, ecg_mV, success] = read_ecg_signal(patient_path, signal_name, num_samples, lead_index, Gain, Baseline, Fs)
dat_file = fullfile(patient_path, [signal_name '.dat']);
success = true;
try
fid = fopen(dat_file, 'r');
data = fread(fid, [12, num_samples], 'int16');
fclose(fid);


if lead_index > size(data,1)
warning('Lead index %d exceeds available leads (%d) in %s. Skipping.', lead_index, size(data,1), signal_name);
ecg_mV = [];
t = [];
success = false;
return;
end


raw = data(lead_index,:);
ecg_mV = (raw - Baseline)/Gain;
t = (0:length(ecg_mV)-1)/Fs;


catch ME
warning('Error reading %s: %s', dat_file, ME.message);
ecg_mV = [];
t = [];
success = false;
end
end

%% ======================= ROBUST NORMALIZATION ========================
function ecg_norm = robust_normalize(ecg)
    med = median(ecg);
    mad_val = mad(ecg,1);
    ecg_norm = (ecg - med)/mad_val;
end

%% ======================= FEATURE EXTRACTION ==========================
function F = extract_features_all(ecg, t, Fs)
    [pks, locs] = findpeaks(ecg, Fs, 'MinPeakHeight',0.2*max(ecg),'MinPeakDistance',0.2);
    BPM = length(locs)/t(end)*60;
    RR = diff(locs);
    SDNN = std(RR*1000);

    [C,L] = wavedec(ecg,5,'db4');
    cA = appcoef(C,L,'db4',5);
    EnA = sum(cA.^2);
    EnD_total = 0;
    for i=1:5, cD = detcoef(C,L,i); EnD_total = EnD_total + sum(cD.^2); end
    cD5 = detcoef(C,L,5);
    EnD5 = sum(cD5.^2);

    H = Hurst_Exponent_RS_Analysis(ecg);
    Hig = Higuchi_Fractal_Dimension(ecg, 16);
    K = Katz_Fractal_Dimension(ecg);

    F = struct('BPM',BPM,'SDNN',SDNN,'EnTotal',EnA+EnD_total,'EnD5',EnD5,'Hurst',H,'Higuchi',Hig,'Katz',K);
end

%% ======================= VISUALIZATION ===============================
function plot_ecg_overview(t, raw, filtered, title_name)
    figure('Name',['ECG - ' title_name],'NumberTitle','off');
    subplot(2,1,1); plot(t, raw); title(['Raw ECG - ' title_name]); xlabel('Time (s)'); ylabel('mV'); grid on;
    subplot(2,1,2); plot(t, filtered); title('Filtered ECG'); xlabel('Time (s)'); ylabel('mV'); grid on;
end

function plot_normalization_comparison(t, raw, norm_sig, title_name)
    figure('Name',['Normalization - ' title_name],'NumberTitle','off');
    subplot(2,1,1); plot(t, raw); title('Filtered ECG (Before Normalization)'); grid on;
    subplot(2,1,2); plot(t, norm_sig); title('Robust Normalized ECG'); grid on;
end

%% ======================= COMPRESSION ================================
function [comp, ratio] = compress_signal(ecg, factor)
    comp = ecg(1:factor:end);
    ratio = length(ecg)/length(comp);
end

function plot_compression(t, ecg, t2, compressed, title_name)
    figure('Name',['Compression - ' title_name],'NumberTitle','off');
    subplot(2,1,1); plot(t, ecg); title('Original ECG'); grid on;
    subplot(2,1,2); plot(t2, compressed); title('Compressed ECG'); grid on;
end

%% ======================= FREQUENCY ANALYSIS ==========================
function plot_frequency_analysis(ecg, Fs, title_name)
    L = length(ecg);
    f = Fs*(0:(L/2))/L;
    Y = fft(ecg);
    P = abs(Y/L);
    P1 = P(1:L/2+1);
    figure('Name',['Frequency Spectrum - ' title_name],'NumberTitle','off');
    plot(f, P1); grid on; title('ECG Frequency Spectrum'); xlabel('Hz'); ylabel('Amplitude');
end

%% ======================= SIGNAL ANALYZER =============================
function open_signal_analyzer(ecg, Fs)
    signalAnalyzer(ecg, Fs);
end