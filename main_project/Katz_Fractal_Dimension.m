function K = Katz_Fractal_Dimension(Signal)
% Katz_Fractal_Dimension - Calcula a Dimensão Fractal de Katz (K).
%
% K = Katz_Fractal_Dimension(Signal)
%
% Entrada:
%   Signal: Vetor do sinal de tempo (ECG_filtered_final).
%
% Saída:
%   K: Dimensão Fractal de Katz (valor entre 1 e 2).
% --------------------------------------------------------------------------

N = length(Signal);

% 1. Comprimento Total da Curva (L)
% Soma das distâncias euclidianas entre pontos consecutivos.
L = sum(sqrt(diff(Signal).^2 + 1)); 

% 2. Diâmetro (d)
% Máxima distância euclidiana entre o primeiro ponto e qualquer outro ponto.
% O sinal é assumido em 2D (índice vs amplitude).
% Distância de cada ponto (i) ao primeiro ponto (1)
distance_to_start = zeros(N, 1);
for i = 2:N
    % Distância Euclidiana 2D: sqrt((x_i - x_1)^2 + (y_i - y_1)^2)
    % x_i é o índice, y_i é a amplitude
    distance_to_start(i) = sqrt((i - 1)^2 + (Signal(i) - Signal(1))^2);
end
d = max(distance_to_start);

% 3. Katz Fractal Dimension (K)
K = log10(N) / (log10(N) + log10(L/d));

end