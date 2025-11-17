classdef ECGSegmentation
    methods(Static)
        function segments = segment_signal(X, fs)
            num_segments = size(X,2) / fs; % 10 segments for 10 seconds
            
            segments = cell(1,num_segments);
            
            for s = 1:num_segments
                idx = (s-1)*fs + 1 : s*fs;
                segments{s} = X(:, idx);
            end
        end
        %%
        function segments = segment_signal_2(X, fs, window_sec)
            % segment_signal_2 segments the input signal X into smaller segments
            % based on the specified window length in seconds (window_sec).
            % Inputs:
            %   X - Input signal matrix where rows represent different signals
            %       and columns represent time samples.
            %   fs - Sampling frequency of the signal (samples per second).
            %   window_sec - Length of each segment in seconds.
            % Output:
            %   segments - A cell array containing the segmented signals.

            window_len = window_sec * fs; % Calculate the number of samples in each segment
            num_segments = floor(size(X,2) / window_len); % Determine the number of complete segments in 2-D
            
            segments = cell(1,num_segments); % Initialize a cell array to hold the segments
            
            for s = 1:num_segments % Loop over each segment
                idx = (s-1)*window_len + 1 : s*window_len; % Calculate the index range for the current segment
                segments{s} = X(:, idx); % Extract the segment from the input signal
            end
        end

    end
end