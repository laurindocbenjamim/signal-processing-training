% ======================================================================
%   Modular ECG Batch Processing Framework (Clean & Organized)
%   - Directory scanning
%   - Reading ECG signals
%   - Filtering & artifact removal
%   - Feature extraction (time, wavelet, fractal)
%   - Visualization tools
%   - Signal Analyzer Toolbox Integration
% ======================================================================
run_ecg_batch_processing();

%% ======================= MAIN SCRIPT ================================
function run_ecg_batch_processing()
    clc; clear; close all;

    BASE_DIR = '../main_db/';
    Patient_Dirs = {'ecg_db_patient_01', ...
                    'ecg_db_patient_02', 'ecg_db_patient_03', ...
                    'ecg_db_patient_04'};

    OUTPUT_DIR = 'Extracted_Features_Batch';
    if ~exist(OUTPUT_DIR, 'dir'), mkdir(OUTPUT_DIR); end

    % Parameters
    Fs = 1000;
    num_samples = 38400;
    lead_index = 2;
    Gain = 2000;
    Baseline = -458;

    Feature_Master = table();

    disp('=== STARTING BATCH ECG PROCESSING ===');

    total_patients = length(Patient_Dirs);
    total_signals = 0;
    total_leads_processed = 1; % always lead_index=2 but counted per signal


    for p = 1:length(Patient_Dirs)
        patient_path = fullfile(BASE_DIR, Patient_Dirs{p});
        [Feature_Master, sig_count] = process_patient_folder(patient_path, ...
            Patient_Dirs{p}, Fs, num_samples, lead_index, Gain, Baseline, Feature_Master);
        total_signals = total_signals + sig_count;

    end

    fprintf('Total Patients: %d', total_patients);
    fprintf('Total Signals Processed: %d', total_signals);
    fprintf('Total Leads Processed: %d', total_signals * total_leads_processed);

    disp(' ');
    disp('=== BATCH PROCESSING COMPLETE ===');
    disp(Feature_Master(1:min(5, height(Feature_Master)), :));

    writetable(Feature_Master, fullfile(OUTPUT_DIR, 'ECG_Features_Master_Summary.csv'));
end

%% ======================= PATIENT PROCESSOR ===========================
function [Feature_Master, signal_counter] = process_patient_folder(patient_path, patient_id, Fs, num_samples, lead_index, Gain, Baseline, Feature_Master)
    files = dir(fullfile(patient_path, '*.hea'));
    if isempty(files)
        warning('No .hea files in %s', patient_path);
        return;
    end

    signal_counter = 0;

    for k = 1:length(files)
        signal_name = erase(files(k).name, '.hea');
        [t, ecg_mV] = read_ecg_signal(patient_path, signal_name, num_samples, lead_index, Gain, Baseline, Fs);

        ecg_filtered = remove_artefacts_2(ecg_mV, Fs);

        % === Robust Normalization ===
        ecg_norm = robust_normalize(ecg_filtered);

        % Plot normalization comparison
        plot_normalization_comparison(t, ecg_filtered, ecg_norm, signal_name);

        features = extract_features_all(ecg_filtered, t, Fs);

        % Build row
        row = table({patient_id}, {signal_name}, features.BPM, features.SDNN, ...
                    features.EnTotal, features.EnD5, features.Hurst, ...
                    features.Higuchi, features.Katz, ...
                    'VariableNames', {'Patient_ID','Signal_Name','BPM_avg','SDNN', ...
                    'En_Total','En_D5','Hurst_Exp','Higuchi_FD','Katz_FD'});

        Feature_Master = [Feature_Master; row];

        % Plot tools
        plot_ecg_overview(t, ecg_mV, ecg_filtered, signal_name);

        signal_counter = signal_counter + 1;
        
    end
end

%% ======================= SIGNAL READER ===============================
function [t, ecg_mV] = read_ecg_signal(patient_path, signal_name, num_samples, lead_index, Gain, Baseline, Fs)
    dat_file = fullfile(patient_path, [signal_name '.dat']);

    try
        fid = fopen(dat_file, 'r');
        data = fread(fid, [12, num_samples], 'int16');
        fclose(fid);

        raw = data(lead_index,:);
        ecg_mV = (raw - Baseline) / Gain;
        t = (0:length(ecg_mV)-1) / Fs;
    catch
        error('Error reading %s', dat_file);
    end
end

%% ======================= NORMALIZATION (ROBUST) =======================
function ecg_norm = robust_normalize(ecg)
    med = median(ecg);
    mad_val = mad(ecg,1);
    ecg_norm = (ecg - med) / mad_val;
end

%% ======================= FEATURE EXTRACTION ==========================
function F = extract_features_all(ecg, t, Fs)
    % Time
    [pks, locs] = findpeaks(ecg, Fs, 'MinPeakHeight',0.2*max(ecg),'MinPeakDistance',0.2);
    BPM = length(locs)/t(end)*60;
    RR = diff(locs);
    SDNN = std(RR*1000);

    % Wavelet
    [C,L] = wavedec(ecg,5,'db4');
    cA = appcoef(C,L,'db4',5);
    EnA = sum(cA.^2);
    EnD_total = 0;
    for i=1:5
        cD = detcoef(C,L,i); EnD_total = EnD_total + sum(cD.^2);
    end
    cD5 = detcoef(C,L,5);
    EnD5 = sum(cD5.^2);

    % Fractals
    H = Hurst_Exponent_RS_Analysis(ecg);
    Hig = Higuchi_Fractal_Dimension(ecg, 16);
    K = Katz_Fractal_Dimension(ecg);

    F = struct('BPM',BPM,'SDNN',SDNN,'EnTotal',EnA+EnD_total,'EnD5',EnD5,...
               'Hurst',H,'Higuchi',Hig,'Katz',K);
end

%% ======================= VISUALIZATION ===============================
function plot_normalization_comparison(t, raw, norm_sig, title_name)
    figure('Name',['Normalization - ' title_name], 'NumberTitle','off');
    subplot(2,1,1); plot(t, raw); title('Filtered ECG (Before Normalization)'); grid on;
    subplot(2,1,2); plot(t, norm_sig); title('Robust Normalized ECG'); grid on;
end

function plot_ecg_overview(t, raw, filtered, title_name)
    figure('Name',['ECG - ' title_name], 'NumberTitle','off');
    subplot(2,1,1);
    plot(t, raw); title(['Raw ECG - ' title_name]); xlabel('Time (s)'); ylabel('mV'); grid on;

    subplot(2,1,2);
    plot(t, filtered); title('Filtered ECG'); xlabel('Time (s)'); ylabel('mV'); grid on;
end

%% ======================= COMPRESSION (DOWNSAMPLING) ===================
function [comp, ratio] = compress_signal(ecg, factor)
    comp = ecg(1:factor:end);
    ratio = length(ecg)/length(comp);
end

function plot_compression(t, ecg, t2, compressed, title_name)
    figure('Name',['Compression - ' title_name], 'NumberTitle','off');
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

    figure('Name',['Frequency Spectrum - ' title_name], 'NumberTitle','off');
    plot(f, P1); grid on; title('ECG Frequency Spectrum'); xlabel('Hz'); ylabel('Amplitude');
end

%% ======================= SIGNAL ANALYZER TOOLBOX ======================
function open_signal_analyzer(ecg, Fs)
    signalAnalyzer(ecg, Fs);
end
