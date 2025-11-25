


% read the signal with 
%load('main_db/ecg_db_patient_01/');

% clear; clc; close all;
BASE_DIR = 'main_db/';
OUTPUT_DIR = './Extracted_Features_Batch';

ecg_pro = ECGProcessing(BASE_DIR);

ecg_pro.extract(OUTPUT_DIR);


if ~exist(OUTPUT_DIR, 'dir')
    mkdir(OUTPUT_DIR);
end

Patient_Folders = dir(BASE_DIR); % Get a list of all files and folders in the BASE_DIR
Patient_Folders = Patient_Folders([Patient_Folders.isdir]); % Filter to keep only directories
Patient_Folders = Patient_Folders(~ismember({Patient_Folders.name},{'.','..'})); % Remove the current (.) and parent (..) directory entries

% Load the corresponding signal file
for p = 1:length(Patient_Folders)
    patient_name = Patient_Folders(p).name;
    patient_path = fullfile(BASE_DIR, patient_name);

    head_files = dir(fullfile(patient_path, '*.hea'));

    % load the header file of the signal
    for f = 1 : length(head_files)
        header = erase(head_files(f).name, '.hea');

        % Concatenate the path and file name
        recordName = [patient_path, '/', header];
       
        [signal, Fs, tm] = rdsamp(recordName); 

        whos signal;
        
        [numSamples,numLeads,desired_samples,total_seconds] = SigPreProcessing.calculate_seconds(signal, Fs);

        fprintf('Regist read with %d samples & %d channels/Leads (columns within the matriz) \n to %d Hz %d Tot.Seconds (rows within the matriz) \n', numSamples, numLeads, Fs, total_seconds);
        
        fprintf('Desired samples: %d \n', desired_samples);

        [conventional_leads, frank_leads] = SigPreProcessing.load_leads(signal);

        % =====================================================================================
        % 2. READ THE DIAGNOSTIC (Parsing of .hea file)
        % The rdsamp function focuses on numbers. To get the diagnostic text ("Label"),
        % the most direct way in MATLAB is to read the .hea text file line by line.

        
        [patient_diagnose_label, fid] = SigPreProcessing.load_patient_diagnose(recordName, 'Reason for admission', 'IgnoreCase');
        
        
        if strcmp(patient_diagnose_label, 'unknow')
            fprintf('Patient dignostic: %s\n', patient_diagnose_label);
        else
            fprintf('Patient diagnostic: %s\n', patient_diagnose_label);
        end

    end % EndFor
end % EndFor


%%
