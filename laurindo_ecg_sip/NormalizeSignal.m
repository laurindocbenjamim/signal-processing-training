% Functions to normalize signal
classdef NormalizeSignal
    methods(Static)
        
        % ---------------------- Basic normalization ---------------------------
        function ecg_norm = normalize_z(x)
            ecg_norm = (x - mean(x)) / std(x);
        end
        
        % ---------------------- Robust MAD Normalization ----------------------
        function ecg_norm = normalize_by_MAD(signal)
            % Median Absolute Deviation normalization
            med = median(signal);
            mad_val = median(abs(signal - med));
            ecg_norm = (signal - med) / mad_val;
        end
        
        %% ======================= ROBUST NORMALIZATION ========================
        function ecg_norm = robust_normalize(ecg)
            med = median(ecg);
            mad_val = mad(ecg,1);
            ecg_norm = (ecg - med)/mad_val;
        end
    end
end

