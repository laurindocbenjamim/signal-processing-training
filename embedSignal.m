function X = embedSignal(x, m, tau)

% embedSignal: Phase space reconstruction for a 1D signal
% X = embedSignal(x, m, tau)
% x   : 1D signal (vector)
% m   : embedding dimension
% tau : time delay

    x = x(:);    % make sure x is a column vector
    N = length(x);   % length of the signal


    M = N - (m-1)*tau;  % number of vectors after embedding

    if M <= 0
        error('Signal too short for this m and tau');
    end

    X = zeros(M, m);  % preallocate matrix for embedded vectors

    for d = 1:m
        X(:,d) = x( (1:M) + (d-1)*tau );
    end
end
