function [reduced_signal] = open_signal_analyzer(dataset_signal, total_channels, max_samples)
    %% Obter dimensões e preparar para Signal Analyzer
    % total_channels: número máximo de canais a analisar
    % max_samples: número máximo de amostras por canal
    
    if nargin < 3
        max_samples = 10000;  % Valor padrão
    end
    
    if nargin < 2
        total_channels = 5;   % Valor padrão
    end
    
    [total_canais, total_amostras] = size(dataset_signal);
    
    fprintf('Sinal original: %d canais x %d amostras\n', total_canais, total_amostras);
    
    % Limitar número de canais e amostras
    canais_analisar = min(total_channels, total_canais);
    amostras_analisar = min(max_samples, total_amostras);
    
    reduced_signal = dataset_signal(1:canais_analisar, 1:amostras_analisar);
    
    fprintf('Sinal reduzido: %d canais x %d amostras\n', canais_analisar, amostras_analisar);
    
    % Abrir automaticamente no Signal Analyzer
    signalAnalyzer(reduced_signal');
end