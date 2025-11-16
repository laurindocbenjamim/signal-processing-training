% Functions to normalize signal

% ---------------------- Basic normalization ---------------------------
function y = normalize_z(x)
    y = (x - mean(x)) / std(x);
end

% ---------------------- Robust MAD Normalization ----------------------
function y = normalize_by_MAD(x)
    % Median Absolute Deviation normalization
    med = median(x);
    mad_val = median(abs(x - med));
    y = (x - med) / mad_val;
end

