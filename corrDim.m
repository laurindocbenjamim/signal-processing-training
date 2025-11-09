function C = corrDim(X, l, k)
% corrDim: Compute the correlation sum for a given radius
%   X : M×d matrix of reconstructed vectors (each row = X_i)
%   l : distance threshold (radius)
%   k : Theiler window (offset to remove temporal correlation, e.g., 1, 5, ...)

    if nargin < 3
        k = 1;    % default Theiler window if not provided  
    end

    X = double(X);
    [M, ~] = size(X);    % number of vectors


    count = 0;        % counter for pairs with distance <= l


 % loop over all pairs of points with Theiler window

    for i = 1 : M-k
        for j = i+k : M
            

            d = norm(X(i,:) - X(j,:));   % Euclidean distance between X_i and X_j

        
            if d <= l       % Heaviside function: 1 if distance <= l, else 0

                count = count + 1;
            end
        end
    end

     % correlation sum formula

    C = 2 * count / (M^2);

end
