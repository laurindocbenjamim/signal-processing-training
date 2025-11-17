function subbands = dwt_decompose(seg, S, wname)
    % dwt_decompose performs a discrete wavelet transform on the input signal segments.
    % Inputs:
    %   seg - a matrix where each row represents a different signal segment
    %   S - the number of levels of decomposition
    %   wname - the name of the wavelet to use for decomposition
    % Outputs:
    %   subbands - a cell array containing the approximation and detail coefficients

    num_leads = size(seg,1); % Get the number of signal segments (leads) from the number of rows in seg.
    
    subbands = cell(num_leads, S+1); % Initialize a cell array to hold the coefficients for each lead.

    for L = 1:num_leads % Loop over each lead (signal segment).
        x = seg(L,:); % Extract the current signal segment from the matrix.
        [C,Lc] = wavedec(x, S, wname); % Perform wavelet decomposition on the signal segment.

        % cA3, cD3, cD2, cD1
        subbands{L,1} = appcoef(C,Lc,wname,S); % Store the approximation coefficients in the first column of subbands.
        for s = 1:S % Loop over the number of decomposition levels.
            subbands{L,s+1} = detcoef(C,Lc,s); % Store the detail coefficients for each level in the subsequent columns of subbands.
        end
    end
end
