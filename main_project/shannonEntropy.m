function S = shannonEntropy(x)
% x : input signal 
% S : result value of Shannon entropy

    x = x(:);            % convert to column vector
    x = double(x);       % make sure it's double type

    eps_val = 1e-12;    % small value to avoid log(0)


    p = abs(x).^2;   % signal power (used as probability)

    
    p = p / sum(p);   % normalize so the sum of all probabilities = 1

    
    p(p == 0) = eps_val;  % replace zeros with small value

    
    S = -sum( p .* log2(p) );     % Shannon entropy formula:  -sum( p * log2(p) )


end
