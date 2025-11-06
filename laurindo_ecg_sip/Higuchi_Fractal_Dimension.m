function H = Higuchi_Fractal_Dimension(Signal, Kmax)
% Higuchi_Fractal_Dimension - Calcula a Dimensão Fractal de Higuchi (H).
%
% H = Higuchi_Fractal_Dimension(Signal, Kmax)
%
% Entrada:
%   Signal: Vetor do sinal de tempo (ECG_filtered_final).
%   Kmax: Número máximo de escalas de tempo (K), tipicamente 8-16.
%
% Saída:
%   H: Dimensão Fractal de Higuchi (valor entre 1 e 2).
% --------------------------------------------------------------------------

N = length(Signal);
Lk_avg = zeros(1, Kmax);
K_values = 1:Kmax;

for k = K_values
    % Comprimentos médios Lm(k) para k escalas e m=1..k
    Lk_m = zeros(1, k); 
    
    for m = 1:k % Ponto de partida (m)
        
        % 1. Sub-série x_k^m (sinal de passo k, começando em m)
        indices = m:k:N;
        xk_m = Signal(indices);
        
        % 2. Comprimento da curva L_m(k)
        N_m = length(indices);
        
        % Cálculo da Soma das distâncias entre pontos
        sum_distances = sum(abs(diff(xk_m)));
        
        % 3. Fator de Normalização
        % (N-1)/((N_m-1)*k)
        if N_m > 1
            normalization_factor = (N - 1) / ((N_m - 1) * k);
            Lk_m(m) = sum_distances * normalization_factor;
        else
            Lk_m(m) = 0; % Evitar erro se N_m <= 1
        end
    end
    
    % 4. L(k) é a média dos Lm(k) para m=1..k
    Lk_avg(k) = mean(Lk_m(Lk_m > 0));
end

% 5. Regressão Linear: H é a inclinação de log(L(k)) vs log(1/k)
log_Lk = log10(Lk_avg(Lk_avg > 0));
log_k_inv = log10(1./K_values(Lk_avg > 0));

P = polyfit(log_k_inv, log_Lk, 1);
H = P(1);

end