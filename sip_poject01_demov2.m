%% Configuração inicial
clear; close all; clc;

%% Carregar resultados processados
load('resultados_processamento_ecg.mat');

%% Funções estatísticas alternativas
function sk = calcular_skewness(x)
    % Implementação manual de skewness
    x = x(:);
    n = length(x);
    media = mean(x);
    desvio = std(x);
    
    if desvio == 0
        sk = 0;
    else
        sk = (sum((x - media).^3) / n) / (desvio^3);
    end
end

function kurt = calcular_kurtosis(x)
    % Implementação manual de kurtosis
    x = x(:);
    n = length(x);
    media = mean(x);
    desvio = std(x);
    
    if desvio == 0
        kurt = 0;
    else
        kurt = (sum((x - media).^4) / n) / (desvio^4) - 3;
    end
end

function entropia = calcular_entropia_shannon(x)
    % Implementação manual de entropia de Shannon
    x = x(:);
    
    % Normalizar para histograma
    [counts, ~] = histcounts(x, 50);
    prob = counts / sum(counts);
    
    % Remover zeros para evitar log(0)
    prob = prob(prob > 0);
    
    if isempty(prob)
        entropia = 0;
    else
        entropia = -sum(prob .* log2(prob));
    end
end

%% Função para extrair características do ECG
function caracteristicas = extrair_caracteristicas_ecg(sinal, fs)
    caracteristicas = struct();
    sinal = double(sinal(:));
    
    % 1. Características no domínio do tempo
    caracteristicas.media = mean(sinal);
    caracteristicas.desvio_padrao = std(sinal);
    caracteristicas.variancia = var(sinal);
    caracteristicas.skewness = calcular_skewness(sinal);
    caracteristicas.kurtosis = calcular_kurtosis(sinal);
    caracteristicas.range = max(sinal) - min(sinal);
    
    % 2. Características de frequência
    if length(sinal) > fs
        L = min(length(sinal), 5*fs);
        [Pxx, F] = pwelch(sinal(1:L), [], [], [], fs);
        
        % Frequência dominante
        [~, idx_max] = max(Pxx);
        caracteristicas.freq_dominante = F(idx_max);
        
        % Potência em bandas específicas
        idx_delta = (F >= 0.5 & F <= 4);
        idx_theta = (F > 4 & F <= 8);
        idx_alfa = (F > 8 & F <= 13);
        idx_beta = (F > 13 & F <= 30);
        idx_gama = (F > 30 & F <= 40);
        
        if sum(idx_delta) > 0
            caracteristicas.potencia_delta = mean(Pxx(idx_delta));
        else
            caracteristicas.potencia_delta = 0;
        end
        
        if sum(idx_theta) > 0
            caracteristicas.potencia_theta = mean(Pxx(idx_theta));
        else
            caracteristicas.potencia_theta = 0;
        end
        
        if sum(idx_alfa) > 0
            caracteristicas.potencia_alfa = mean(Pxx(idx_alfa));
        else
            caracteristicas.potencia_alfa = 0;
        end
        
        if sum(idx_beta) > 0
            caracteristicas.potencia_beta = mean(Pxx(idx_beta));
        else
            caracteristicas.potencia_beta = 0;
        end
        
        if sum(idx_gama) > 0
            caracteristicas.potencia_gama = mean(Pxx(idx_gama));
        else
            caracteristicas.potencia_gama = 0;
        end
        
        % Razão de potências
        if caracteristicas.potencia_delta > 0
            caracteristicas.razao_theta_delta = caracteristicas.potencia_theta / caracteristicas.potencia_delta;
            caracteristicas.razao_alfa_theta = caracteristicas.potencia_alfa / caracteristicas.potencia_theta;
        else
            caracteristicas.razao_theta_delta = 0;
            caracteristicas.razao_alfa_theta = 0;
        end
    else
        caracteristicas.freq_dominante = 0;
        caracteristicas.potencia_delta = 0;
        caracteristicas.potencia_theta = 0;
        caracteristicas.potencia_alfa = 0;
        caracteristicas.potencia_beta = 0;
        caracteristicas.potencia_gama = 0;
        caracteristicas.razao_theta_delta = 0;
        caracteristicas.razao_alfa_theta = 0;
    end
    
    % 3. Características de complexidade
    caracteristicas.entropia = calcular_entropia_shannon(sinal);
    
    % 4. Detecção de batimentos (simplificada)
    try
        [qrs_amp, qrs_i] = pan_tompkins(sinal, fs, 0);
        caracteristicas.num_batimentos = length(qrs_amp);
        if length(qrs_i) > 1
            rr_intervals = diff(qrs_i) / fs;
            caracteristicas.bpm_medio = 60 / mean(rr_intervals);
            caracteristicas.hrv_std = std(rr_intervals);
        else
            caracteristicas.bpm_medio = 0;
            caracteristicas.hrv_std = 0;
        end
    catch ME
        % Método alternativo mais simples para detecção de batimentos
        caracteristicas = detectar_batimentos_simples(sinal, fs, caracteristicas);
    end
end

%% Função alternativa simples para detecção de batimentos
function caracteristicas = detectar_batimentos_simples(sinal, fs, caracteristicas)
    try
        % Filtro passa-banda simples
        sinal_filtrado = filtrar_sinal_simples(sinal, fs);
        
        % Encontrar picos
        [pks, locs] = findpeaks(sinal_filtrado, 'MinPeakHeight', 0.5*std(sinal_filtrado), ...
                                'MinPeakDistance', round(0.3*fs));
        
        caracteristicas.num_batimentos = length(pks);
        
        if length(locs) > 1
            rr_intervals = diff(locs) / fs;
            caracteristicas.bpm_medio = 60 / mean(rr_intervals);
            caracteristicas.hrv_std = std(rr_intervals);
        else
            caracteristicas.bpm_medio = 0;
            caracteristicas.hrv_std = 0;
        end
    catch
        caracteristicas.num_batimentos = 0;
        caracteristicas.bpm_medio = 0;
        caracteristicas.hrv_std = 0;
    end
end

%% Filtro simples para detecção de batimentos
function sinal_filtrado = filtrar_sinal_simples(sinal, fs)
    % Filtro passa-banda muito simples
    sinal = sinal - mean(sinal);
    
    % Suavização
    window_size = round(0.02 * fs); % 20ms
    if window_size > 1
        sinal_filtrado = movmean(sinal, window_size);
    else
        sinal_filtrado = sinal;
    end
end

%% Função Pan-Tompkins simplificada para detecção de QRS
function [qrs_amp, qrs_i] = pan_tompkins(ecg, fs, gr)
    % Implementação simplificada do algoritmo Pan-Tompkins
    ecg = ecg - mean(ecg);
    
    % Filtro derivativo simples
    b = [1, 2, 0, -2, -1] * (1/8);
    derivada = filter(b, 1, ecg);
    
    % Quadrado
    quadrado = derivada .^ 2;
    
    % Janela móvel
    window_size = round(0.150 * fs);
    if window_size < 1
        window_size = 1;
    end
    integrada = movmean(quadrado, window_size);
    
    % Encontrar picos
    limiar = 0.3 * max(integrada);
    [picos, locs] = findpeaks(integrada, 'MinPeakHeight', limiar, ...
                              'MinPeakDistance', round(0.3*fs));
    
    qrs_amp = picos;
    qrs_i = locs;
end

%% Função para classificar ECG baseado em características
function classe = classificar_ecg(caracteristicas)
    % Critérios de classificação baseados em características do ECG
    
    % 1. Ritmo Sinusal Normal
    if caracteristicas.bpm_medio >= 60 && caracteristicas.bpm_medio <= 100 && ...
       caracteristicas.hrv_std > 0.02 && caracteristicas.num_batimentos >= 5
        classe = 'Ritmo Sinusal Normal';
        
    % 2. Taquicardia Sinusal
    elseif caracteristicas.bpm_medio > 100 && caracteristicas.num_batimentos >= 3
        classe = 'Taquicardia Sinusal';
        
    % 3. Bradicardia Sinusal
    elseif caracteristicas.bpm_medio < 60 && caracteristicas.bpm_medio > 30 && ...
           caracteristicas.num_batimentos >= 3
        classe = 'Bradicardia Sinusal';
        
    % 4. Possível arritmia (baseado em variabilidade)
    elseif caracteristicas.hrv_std > 0.25 && caracteristicas.num_batimentos > 5
        classe = 'Possível Arritmia';
        
    % 5. Ruído excessivo
    elseif caracteristicas.potencia_gama > caracteristicas.potencia_delta * 3
        classe = 'Sinal com Ruído Excessivo';
        
    % 6. Sinal de baixa amplitude
    elseif caracteristicas.range < 0.1
        classe = 'Sinal de Baixa Amplitude';
        
    % 7. Padrão normal com variações
    elseif caracteristicas.num_batimentos >= 3
        classe = 'Padrão ECG Detectado';
        
    % 8. Sinal de baixa qualidade
    else
        classe = 'Sinal de Qualidade Insuficiente';
    end
end

%% Função para classificação alternativa baseada em machine learning simples
function classe = classificar_ecg_ml(caracteristicas)
    % Sistema de pontuação baseado em características
    pontos = 0;
    
    % Pontuação para ritmo normal
    if caracteristicas.bpm_medio >= 60 && caracteristicas.bpm_medio <= 100
        pontos = pontos + 3;
    elseif caracteristicas.bpm_medio > 40 && caracteristicas.bpm_medio < 150
        pontos = pontos + 1;
    end
    
    % Pontuação para variabilidade
    if caracteristicas.hrv_std >= 0.02 && caracteristicas.hrv_std <= 0.2
        pontos = pontos + 2;
    end
    
    % Pontuação para número de batimentos
    if caracteristicas.num_batimentos >= 8
        pontos = pontos + 3;
    elseif caracteristicas.num_batimentos >= 3
        pontos = pontos + 1;
    end
    
    % Pontuação para amplitude
    if caracteristicas.range > 0.5
        pontos = pontos + 2;
    elseif caracteristicas.range > 0.1
        pontos = pontos + 1;
    end
    
    % Pontuação para ruído
    if caracteristicas.potencia_gama < caracteristicas.potencia_delta
        pontos = pontos + 2;
    end
    
    % Classificação baseada na pontuação
    if pontos >= 8
        classe = 'ECG Normal';
    elseif pontos >= 6
        classe = 'ECG com Alterações Leves';
    elseif pontos >= 4
        classe = 'ECG com Alterações Moderadas';
    elseif pontos >= 2
        classe = 'ECG com Alterações Graves';
    else
        classe = 'Sinal Não Classificável';
    end
end

%% ANÁLISE E CLASSIFICAÇÃO DOS SINAIS
fprintf('=== ANÁLISE E CLASSIFICAÇÃO DOS SINAIS ECG ===\n\n');

% Estrutura para armazenar classificações
classificacoes = struct();

for i = 1:length(resultados)
    fprintf('Analisando: %s\n', resultados(i).filename);
    
    sinal = resultados(i).sinal_original;
    fs = 500; % Assumindo 500 Hz
    
    % Extrair características
    try
        caracteristicas = extrair_caracteristicas_ecg(sinal, fs);
        
        % Classificar usando dois métodos
        classe1 = classificar_ecg(caracteristicas);
        classe2 = classificar_ecg_ml(caracteristicas);
        
        % Armazenar resultados
        classificacoes(i).filename = resultados(i).filename;
        classificacoes(i).caracteristicas = caracteristicas;
        classificacoes(i).classe_diagnostica = classe1;
        classificacoes(i).classe_ml = classe2;
        classificacoes(i).bpm = caracteristicas.bpm_medio;
        classificacoes(i).hrv = caracteristicas.hrv_std;
        classificacoes(i).num_batimentos = caracteristicas.num_batimentos;
        classificacoes(i).amplitude = caracteristicas.range;
        
        fprintf('  → BPM: %.1f, HRV: %.3f, Batimentos: %d, Amplitude: %.3f\n', ...
            caracteristicas.bpm_medio, caracteristicas.hrv_std, ...
            caracteristicas.num_batimentos, caracteristicas.range);
        fprintf('  → Classificação: %s\n', classe1);
        fprintf('  → Classificação ML: %s\n\n', classe2);
        
    catch ME
        fprintf('  → ERRO na análise: %s\n', ME.message);
        fprintf('  → Usando classificação básica...\n');
        
        % Classificação básica baseada apenas no sinal bruto
        classe_basica = classificar_basico(sinal);
        
        % Armazenar resultados básicos
        classificacoes(i).filename = resultados(i).filename;
        classificacoes(i).classe_diagnostica = classe_basica;
        classificacoes(i).classe_ml = classe_basica;
        classificacoes(i).bpm = 0;
        classificacoes(i).hrv = 0;
        classificacoes(i).num_batimentos = 0;
        classificacoes(i).amplitude = max(sinal) - min(sinal);
        
        fprintf('  → Classificação Básica: %s\n\n', classe_basica);
    end
end

%% Função de classificação básica
function classe = classificar_basico(sinal)
    sinal = double(sinal(:));
    
    amplitude = max(sinal) - min(sinal);
    variancia = var(sinal);
    
    if amplitude < 0.05
        classe = 'Sinal Muito Fraco';
    elseif variancia < 0.001
        classe = 'Sinal Plano';
    elseif amplitude > 5
        classe = 'Sinal Saturado';
    else
        classe = 'Sinal com Padrão ECG';
    end
end

%% CONTAGEM DAS CLASSES
fprintf('=== DISTRIBUIÇÃO POR CLASSE DIAGNÓSTICA ===\n\n');

% Contar classes do método diagnóstico
classes_diagnostico = {classificacoes.classe_diagnostica};
classes_unicas_diag = unique(classes_diagnostico);
contagem_diag = zeros(length(classes_unicas_diag), 1);

for i = 1:length(classes_unicas_diag)
    contagem_diag(i) = sum(strcmp(classes_diagnostico, classes_unicas_diag{i}));
end

% Contar classes do método ML
classes_ml = {classificacoes.classe_ml};
classes_unicas_ml = unique(classes_ml);
contagem_ml = zeros(length(classes_unicas_ml), 1);

for i = 1:length(classes_unicas_ml)
    contagem_ml(i) = sum(strcmp(classes_ml, classes_unicas_ml{i}));
end

%% TABELA 1: DISTRIBUIÇÃO POR CLASSE DIAGNÓSTICA
fprintf('TABELA 1 - DISTRIBUIÇÃO POR CLASSE DIAGNÓSTICA\n');
fprintf('%-40s | %-15s | %-10s\n', 'Classe Diagnóstica', 'Número de ECGs', 'Percentual');
fprintf('%-40s-|-%-15s-|-%-10s\n', repmat('-',1,40), repmat('-',1,15), repmat('-',1,10));

for i = 1:length(classes_unicas_diag)
    percentual = (contagem_diag(i) / length(classificacoes)) * 100;
    fprintf('%-40s | %-15d | %-10.1f%%\n', ...
        classes_unicas_diag{i}, contagem_diag(i), percentual);
end

fprintf('%-40s-|-%-15s-|-%-10s\n', repmat('-',1,40), repmat('-',1,15), repmat('-',1,10));
fprintf('%-40s | %-15d | %-10.1f%%\n', ...
    'TOTAL', length(classificacoes), 100);

%% TABELA 2: DISTRIBUIÇÃO POR CLASSE ML
fprintf('\nTABELA 2 - DISTRIBUIÇÃO POR CLASSE (MÉTODO ML)\n');
fprintf('%-30s | %-15s | %-10s\n', 'Classe ML', 'Número de ECGs', 'Percentual');
fprintf('%-30s-|-%-15s-|-%-10s\n', repmat('-',1,30), repmat('-',1,15), repmat('-',1,10));

for i = 1:length(classes_unicas_ml)
    percentual = (contagem_ml(i) / length(classificacoes)) * 100;
    fprintf('%-30s | %-15d | %-10.1f%%\n', ...
        classes_unicas_ml{i}, contagem_ml(i), percentual);
end

fprintf('%-30s-|-%-15s-|-%-10s\n', repmat('-',1,30), repmat('-',1,15), repmat('-',1,10));
fprintf('%-30s | %-15d | %-10.1f%%\n', ...
    'TOTAL', length(classificacoes), 100);

%% SALVAR RESULTADOS
save('classificacao_ecg_resultados.mat', 'classificacoes');

fprintf('\nResultados salvos em: classificacao_ecg_resultados.mat\n');
fprintf('=== ANÁLISE CONCLUÍDA ===\n');