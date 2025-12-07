function H = higuchi_fd(x, Kmax)

    N = length(x);
    Lk = zeros(1, Kmax);

    for k = 1:Kmax
        Lmk = zeros(1, k);

        for m = 1:k
            idx = m:k:N;
            L = sum(abs(diff(x(idx)))) * (N - 1) / ( (length(idx) - 1) * k);
            Lmk(m) = L;
        end

        Lk(k) = mean(Lmk);
    end

    H = polyfit(log(1./(1:Kmax)), log(Lk), 1);
    H=H(1);

end