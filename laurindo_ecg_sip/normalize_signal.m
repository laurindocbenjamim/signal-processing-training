function x_norm = normalize_signal(x)
    % Step 1: Apply x(n) = x(n) / sum(x^2(n))
    sum_of_squares = sum(x.^2);
    
    % Avoid division by zero
    if sum_of_squares == 0
        error('Signal has zero energy - cannot normalize');
    end
    
    x_norm = x / sum_of_squares;
    
    % Step 2: Remove mean value
    x_norm = x_norm - mean(x_norm);
end