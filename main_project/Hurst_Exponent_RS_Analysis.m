function H = Hurst_Exponent_RS_Analysis(Signal)
% Hurst_Exponent_RS_Analysis - Calcula o Expoente de Hurst (H) usando o método R/S.
%
% H = Hurst_Exponent_RS_Analysis(Signal)
%
% Entrada:
%   Signal: Vetor do sinal de tempo (ECG_filtered_final).
%
% Saída:
%   H: O Expoente de Hurst (valor entre 0 e 1).
% --------------------------------------------------------------------------

N = length(Signal);
if N < 100
    H = NaN;
    warning('Sinal muito curto para a análise R/S. H retornado como NaN.');
    return;
end

% Definir os tamanhos das janelas de tempo (T)
T_min = floor(N/100); % Mínimo de 1% do tamanho do sinal
T_max = floor(N/4);   % Máximo de 25% do tamanho do sinal
T_values = floor(logspace(log10(T_min), log10(T_max), 20)); 
T_values = unique(T_values); % Garante que os valores de T são únicos

log_T = log10(T_values);
log_RS = zeros(size(T_values));

% Loop sobre os tamanhos de janela T
for i = 1:length(T_values)
    T = T_values(i);
    
    % Dividir o sinal em segmentos de tamanho T
    num_segments = floor(N / T);
    RS_per_segment = zeros(num_segments, 1);
    
    for j = 1:num_segments
        % 1. Extrair o segmento
        idx_start = (j - 1) * T + 1;
        idx_end = j * T;
        Segment = Signal(idx_start:idx_end);
        
        % 2. Calcular a média do segmento (M)
        M = mean(Segment);
        
        % 3. Calcular a Série Acumulada (Y)
        Y = cumsum(Segment - M);
        
        % 4. Variação (R) = max(Y) - min(Y)
        R = max(Y) - min(Y);
        
        % 5. Desvio Padrão (S)
        S = std(Segment, 1); % Usar std(X, 1) para o divisor N (em vez de N-1)
        
        % Evitar divisão por zero ou desvio zero
        if S == 0
            RS_per_segment(j) = NaN; 
        else
            RS_per_segment(j) = R / S;
        end
    end
    
    % 6. Calcular a média do R/S para o tamanho de janela T
    log_RS(i) = log10(nanmean(RS_per_segment)); % Usa média ignorando NaNs
end

% 7. Regressão Linear: H é a inclinação (slope) da linha log(R/S) vs log(T)
P = polyfit(log_T(~isinf(log_RS) & ~isnan(log_RS)), log_RS(~isinf(log_RS) & ~isnan(log_RS)), 1);
H = P(1);

end