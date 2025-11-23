%In CorrDim, after you embed the signal into phase space you look for pairs of points whose distance is less than or equal to a small radius

function C = corrDim(X, l, k)
    if nargin < 3
        k = 1;
    end

    % normalize embedded vectors: each column mean 0, std 1
    X = zscore(double(X));   
    [M, ~] = size(X);



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

