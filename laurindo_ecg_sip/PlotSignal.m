


%% ======================= VISUALIZATION ===============================
classdef PlotSignal

    methods(Static)
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
        
        
        %%
        
        
        function plot_compression(t, ecg, t2, compressed, title_name)
            figure('Name',['Compression - ' title_name],'NumberTitle','off');
            subplot(2,1,1); plot(t, ecg); title('Original ECG'); grid on;
            subplot(2,1,2); plot(t2, compressed); title('Compressed ECG'); grid on;
        end
        
        
        %% ======================= SIGNAL ANALYZER =============================
        function open_signal_analyzer(ecg, Fs)
            signalAnalyzer(ecg, Fs);
        end

    end 
end

