

classdef SigPreProcessing
    methods(Static)
        %% Get the Leads
        function [conventional_leads, frank_leads] = load_leads(signal)
            conventional_leads = signal(:, 1:12); % Get the first 12 leads
            frank_leads = signal(:, 13:15); % Get the 3 leads, 13,14 and 15 (15=columns of the matriz)
        end

        %% Prepare to plot the comparison for all leads

        function [] = plot_and_compare_leads(signal_10s,signal_normal,num_leads)
        % Prepare to plot the comparison for all leads
            for lead = 1:num_leads
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


    end
end