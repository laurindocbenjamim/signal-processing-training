function out = resample_subbands(subbands, fs, s)
% This function takes a cell array of subbands and a sampling frequency fs
% and resamples each subband to the specified frequency.

[L, B] = size(subbands);
% Get the number of rows (L) and columns (B) in the input cell array 'subbands'.

out = cell(L,B);
% Initialize an output cell array 'out' of the same size as 'subbands' to store the resampled subbands.

for i=1:L
    % Loop over each row of the cell array.
    for b = 1:B
        % Loop over each column of the cell array.
        out{i,b} = resample(subbands{i,b}, fs, length(subbands{i,b}));
        % Resample the subband at (i,b) to the new sampling frequency 'fs' 
        % and store the result in the corresponding position in the output cell array.

        % Plot the results of the decomposition and resampling
            % figure;
            % for i = 1:length(out)
            %     subplot(length(out), 1, i);
            %     plot(out{i});
            %     title(sprintf('Subband %d', i));
            %     xlabel('Samples');
            %     ylabel('Amplitude');
            % end
            % sgtitle(sprintf('Decomposed and Resampled Subbands for Segment %d', s));

    end
end
% End of the nested loops.