function [patient_diagnose_label, fid] = load_patient_diagnose(recordName, key_word, flag)
        
            fid = fopen(recordName, 'r');
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