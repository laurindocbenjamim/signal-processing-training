        %% Display erro or warning messages
        function sms = displayErrorMessage(ME, Signal_Name, Patient_ID)
             % More detailed error information
            errorMessage = sprintf('ERROR to read %s for patient %s: %s', ...
                Signal_Name, Patient_ID, ME.message);
            warning(errorMessage);
            
            % Log additional debug information
            fprintf('Error in function: %s\n', ME.stack(1).name);
            fprintf('Line number: %d\n', ME.stack(1).line);
            
            % Handle specific error types
            if contains(ME.message, 'File not found')
                fprintf('File %s does not exist\n', Signal_Name);
            elseif contains(ME.message, 'Permission denied')
                fprintf('No permission to read file: %s\n', Signal_Name);
            end
            
            sms = []; % Set default value
        end