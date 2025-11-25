


classdef ECGProcessing
    properties
        SIGNAL
        DIR
        NUM_samples
        NUM_leads
        DESIRED_samples
        TOTAL_seconds
    end

    methods

        function obj = ECGProcessing(dir)
            obj.DIR = dir;
        end
        
        function extract(obj, OUTPUT_DIR)
            
            % read the signal with 
            %load('main_db/ecg_db_patient_01/');
            
            % clear; clc; close all;
            BASE_DIR = obj.DIR %'main_db/';
            %OUTPUT_DIR = './Extracted_Features_Batch';
            
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
                    output_path = [patient_path, '/', header];
                    %if contains(header, '10_re')
                        % Condition is correct, you can add any additional processing here
                         % Get the basic informations from the signal
                
                    [signal, Fs, tm] = rdsamp(output_path); 
                    
                    % Start pre-processing the signal
                    
                    [numSamples,numLeads,desired_samples,total_seconds] = SigPreProcessing.calculate_seconds(signal, Fs);
                    

                    
                    whos signal;
                    
                    %end
                end % EndFor
            end % EndFor


        end % EndFunction

    end % EndMethod
end