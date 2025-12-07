function L = logEn(x)
% x : input signal 
% L : result


    x = x(:);         % convert to column vector  
    x = double(x);      % make sure it's double type


    eps_val = 1e-12;   % small value to avoid log(0)

    
    % Formula: sum of log2(|x(n)|^2)

    power = abs(x).^2;               % |x(n)|^2
    L = sum( log2( power + eps_val ) );

end
