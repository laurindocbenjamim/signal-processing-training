% Functions to normalize signal
classdef NormalizeSignal
    methods(Static)
        
        % ---------------------- Basic normalization ---------------------------
        function ecg_norm = normalize_z(x)
            ecg_norm = (x - mean(x)) / std(x);
        end
        
        %%
        function Z = zscore_normalize(F)
            allFeat = vertcat(F.Features);
            
            Z = zscore(cell2mat(struct2cell(allFeat))');
            
            % Replace back (optional; or save separately)
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

        %%
        function x_norm = normalize_ecg(x)
            % x(n) = x(n) / sum(x^2)
            % then remove mean
            
            den = sum(x.^2);
            
            if den == 0
                x_norm = x; return;
            end
            
            x_norm = x ./ den;
            x_norm = x_norm - mean(x_norm);
            z=NormalizeSignal.plotsignal(x, x_norm);
        end

        %%
        function z=plotsignal(x, x_norm)
            % Plotting the normalized and non-normalized signals for comparison
            figure;
            
            % Create a 2x1 subplot layout
            subplot(2, 1, 1);
            plot(x, 'DisplayName', 'Original Signal'); 
            title('Original Signal');
            xlabel('Sample Index');
            ylabel('Amplitude');
            legend show;
            zoom on; % Enable zooming on the original signal
            zoomToggle = zoom; % Create a zoom object
            set(zoomToggle, 'ActionPostCallback', @(src, event) disp('Zoom removed. Use zoom out to reset.'));

            subplot(2, 1, 2);
            plot(x_norm, 'DisplayName', 'Normalized Signal');
            title('Normalized Signal');
            xlabel('Sample Index');
            ylabel('Amplitude');
            legend show;
            zoom on; % Enable zooming on the normalized signal
            set(zoomToggle, 'ActionPostCallback', @(src, event) disp('Zoom removed. Use zoom out to reset.'));

            hold off;

            z="Done";
        end

    end
end



