%% CONFIGURAÇÃO INICIAL - ABORDAGEM REALISTA PARA ECG
clear; close all; clc;

%% CARREGAR ARQUIVO GERADO
fprintf('=== CARREGANDO DADOS PROCESSADOS ===\n');
try
    load('resultados_processamento_ecg.mat');
    fprintf('✓ Arquivo resultados_processamento_ecg.mat carregado com sucesso\n');
    fprintf('✓ %d sinais disponíveis para análise\n', length(resultados));
catch ME
    fprintf('❌ Erro ao carregar arquivo: %s\n', ME.message);
    fprintf('✓ Criando dados de exemplo para demonstração...\n');
    %resultados = criar_dados_exemplo();
end

%% PARÂMETROS BASEADOS EM GUIDELINES MÉDICAS
parametros = struct();

% FREQUÊNCIA CARDÍACA (Guidelines AHA/ACC)
parametros.bpm_normal_min = 60;
parametros.bpm_normal_max = 100;
parametros.bpm_taquicardia = 100;
parametros.bpm_bradicardia = 60;

% DURAÇÃO DO QRS (Guidelines AHA)
parametros.qrs_normal_max = 0.10;      % < 100ms = normal
parametros.qrs_bbb_incompleto = 0.10;  % 100-120ms
parametros.qrs_bbb_completo = 0.12;    % > 120ms = BBB

% VARIABILIDADE CARDÍACA
parametros.hrv_normal_min = 0.02;      % HRV muito baixa = possível arritmia
parametros.hrv_arritmia = 0.25;        % HRV muito alta = possível FA

% AMPLITUDES (Critérios de voltagem)
parametros.amplitude_minima = 0.1;     % Sinal muito fraco
parametros.amplitude_normal_min = 0.3;
parametros.amplitude_normal_max = 3.0;

%% FUNÇÃO PARA EXTRAIR CARACTERÍSTICAS REALISTAS
function caracteristicas = extrair_caracteristicas_realistas(sinal, fs)
    caracteristicas = struct();
    sinal = double(sinal(:));
    
    % 1. FREQUÊNCIA CARDÍACA E VARIABILIDADE
    [caracteristicas.bpm, caracteristicas.hrv_std, caracteristicas.num_batimentos] = ...
        estimar_ritmo_cardiaco(sinal, fs);
    
    % 2. DURAÇÃO DO QRS (estimativa simplificada)
    caracteristicas.duracao_qrs = estimar_duracao_qrs(sinal, fs);
    
    % 3. AMPLITUDE DO SINAL
    caracteristicas.amplitude_pico_a_pico = max(sinal) - min(sinal);
    caracteristicas.amplitude_rms = rms(sinal);
    
    % 4. CARACTERÍSTICAS MORFOLÓGICAS (simulações)
    caracteristicas.razao_sinal_ruido = estimar_snr(sinal);
    caracteristicas.complexidade = estimar_complexidade(sinal);
    
    % 5. INDICADORES DE QUALIDADE
    caracteristicas.qualidade_sinal = classificar_qualidade_sinal(caracteristicas);
end

%% FUNÇÕES AUXILIARES PARA ANÁLISE REALISTA
function [bpm, hrv_std, num_batimentos] = estimar_ritmo_cardiaco(sinal, fs)
    try
        % Detecção de batimentos por análise de energia
        sinal_suavizado = movmean(abs(sinal), round(0.1*fs));
        [pks, locs] = findpeaks(sinal_suavizado, ...
            'MinPeakHeight', 0.3 * max(sinal_suavizado), ...
            'MinPeakDistance', round(0.3*fs));
        
        num_batimentos = length(pks);
        
        if num_batimentos > 1
            rr_intervals = diff(locs) / fs;
            bpm = 60 / mean(rr_intervals);
            hrv_std = std(rr_intervals);
        else
            bpm = 0;
            hrv_std = 0;
        end
    catch
        bpm = 0;
        hrv_std = 0;
        num_batimentos = 0;
    end
end

function duracao_qrs = estimar_duracao_qrs(sinal, fs)
    % Estimativa simplificada da duração do QRS
    try
        sinal_deriv = diff(sinal);
        limiar = 0.4 * max(abs(sinal_deriv));
        
        if limiar == 0
            duracao_qrs = 0.08; % Valor padrão
            return;
        end
        
        qrs_regions = abs(sinal_deriv) > limiar;
        inicio = find(qrs_regions, 1, 'first');
        fim = find(qrs_regions, 1, 'last');
        
        if isempty(inicio) || isempty(fim)
            duracao_qrs = 0.08;
        else
            duracao_qrs = (fim - inicio) / fs;
            % Limitar a valores fisiológicos
            duracao_qrs = min(max(duracao_qrs, 0.06), 0.16);
        end
    catch
        duracao_qrs = 0.08;
    end
end

function snr = estimar_snr(sinal)
    % Estimativa simplificada da relação sinal-ruído
    try
        sinal_filtrado = highpass(sinal, 0.5, 500);
        ruido = sinal - sinal_filtrado;
        potencia_sinal = mean(sinal_filtrado.^2);
        potencia_ruido = mean(ruido.^2);
        
        if potencia_ruido == 0
            snr = 100;
        else
            snr = 10 * log10(potencia_sinal / potencia_ruido);
        end
    catch
        snr = 20; % Valor padrão razoável
    end
end

function complexidade = estimar_complexidade(sinal)
    % Medida de complexidade do sinal (entropia aproximada)
    try
        sinal_normalizado = (sinal - mean(sinal)) / std(sinal);
        [~, edges] = histcounts(sinal_normalizado, 10);
        counts = histcounts(sinal_normalizado, edges);
        prob = counts / sum(counts);
        prob = prob(prob > 0);
        complexidade = -sum(prob .* log2(prob));
    catch
        complexidade = 2.0;
    end
end

function qualidade = classificar_qualidade_sinal(caracteristicas)
    % Classifica a qualidade do sinal para análise
    if caracteristicas.num_batimentos < 3
        qualidade = 'Inadequado';
    elseif caracteristicas.amplitude_pico_a_pico < 0.1
        qualidade = 'Muito Fraco';
    elseif caracteristicas.razao_sinal_ruido < 10
        qualidade = 'Ruidoso';
    elseif caracteristicas.bpm == 0
        qualidade = 'Sem Batimentos Detectáveis';
    else
        qualidade = 'Adequado';
    end
end

%% FUNÇÃO PRINCIPAL DE CLASSIFICAÇÃO REALISTA
function classe = classificar_ecg_realista(caracteristicas, parametros)
    % Classificação baseada em padrões realmente detectáveis no ECG
    
    % Verificar qualidade do sinal primeiro
    if strcmp(caracteristicas.qualidade_sinal, 'Inadequado') || ...
       strcmp(caracteristicas.qualidade_sinal, 'Muito Fraco') || ...
       strcmp(caracteristicas.qualidade_sinal, 'Sem Batimentos Detectáveis')
        classe = 'Sinal Inadequado para Análise';
        return;
    end
    
    % 1. ANÁLISE DA FREQUÊNCIA CARDÍACA
    if caracteristicas.bpm == 0
        classe = 'Ritmo Não Detectável';
        
    elseif caracteristicas.bpm > parametros.bpm_taquicardia
        if caracteristicas.hrv_std > parametros.hrv_arritmia
            classe = 'Taquicardia com Arritmia';
        else
            classe = 'Taquicardia Sinusal';
        end
        
    elseif caracteristicas.bpm < parametros.bpm_bradicardia
        if caracteristicas.hrv_std > parametros.hrv_arritmia
            classe = 'Bradicardia com Arritmia';
        else
            classe = 'Bradicardia Sinusal';
        end
        
    % 2. ANÁLISE DA CONDUÇÃO (QRS)
    elseif caracteristicas.duracao_qrs >= parametros.qrs_bbb_completo
        classe = 'Padrão de Bloqueio de Condução (QRS Alargado)';
        
    % 3. ANÁLISE DE ARRITMIAS
    elseif caracteristicas.hrv_std > parametros.hrv_arritmia
        classe = 'Arritmia (Alta Variabilidade)';
        
    % 4. ANÁLISE DE QUALIDADE/RUÍDO
    elseif strcmp(caracteristicas.qualidade_sinal, 'Ruidoso')
        classe = 'Sinal Ruidoso - Análise Limitada';
        
    % 5. RITMO NORMAL
    elseif caracteristicas.bpm >= parametros.bpm_normal_min && ...
           caracteristicas.bpm <= parametros.bpm_normal_max && ...
           caracteristicas.duracao_qrs <= parametros.qrs_normal_max
        classe = 'Ritmo Sinusal Normal';
        
    else
        classe = 'Padrão Não Específico';
    end
end

%% PROCESSAMENTO PRINCIPAL
fprintf('\n=== ANÁLISE REALISTA DOS SINAIS ECG ===\n\n');

% Classes realisticamente detectáveis
classes_detectaveis = {
    'Ritmo Sinusal Normal'
    'Taquicardia Sinusal'
    'Bradicardia Sinusal'
    'Taquicardia com Arritmia'
    'Bradicardia com Arritmia'
    'Arritmia (Alta Variabilidade)'
    'Padrão de Bloqueio de Condução (QRS Alargado)'
    'Sinal Ruidoso - Análise Limitada'
    'Ritmo Não Detectável'
    'Sinal Inadequado para Análise'
    'Padrão Não Específico'
};

% Inicializar estruturas para resultados
classificacoes = struct();
contagem_classes = zeros(length(classes_detectaveis), 1);
sinais_por_classe = cell(length(classes_detectaveis), 1);
for i = 1:length(sinais_por_classe)
    sinais_por_classe{i} = {};
end

% Processar cada sinal
for i = 1:length(resultados)
    fprintf('Analisando: %s\n', resultados(i).filename);
    
    % Usar sinal original (já que temos remoção de artefatos)
    if isfield(resultados(i), 'sinal_original')
        sinal = resultados(i).sinal_original;
    else
        sinal = resultados(i).sinal_filtrado;
    end
    
    fs = 500; % Assumindo 500Hz baseado nos processamentos anteriores
    
    try
        % Extrair características realistas
        caracteristicas = extrair_caracteristicas_realistas(sinal, fs);
        
        % Classificar
        classe = classificar_ecg_realista(caracteristicas, parametros);
        
        % Encontrar índice da classe
        idx_classe = find(strcmp(classes_detectaveis, classe));
        if isempty(idx_classe)
            idx_classe = find(strcmp(classes_detectaveis, 'Padrão Não Específico'));
        end
        
        % Armazenar resultados
        classificacoes(i).filename = resultados(i).filename;
        classificacoes(i).caracteristicas = caracteristicas;
        classificacoes(i).classe = classe;
        classificacoes(i).bpm = caracteristicas.bpm;
        classificacoes(i).hrv = caracteristicas.hrv_std;
        classificacoes(i).duracao_qrs = caracteristicas.duracao_qrs;
        classificacoes(i).qualidade = caracteristicas.qualidade_sinal;
        
        % Atualizar contadores
        contagem_classes(idx_classe) = contagem_classes(idx_classe) + 1;
        sinais_por_classe{idx_classe}{end+1} = resultados(i).filename;
        
        fprintf('  → %s\n', classe);
        fprintf('  → BPM: %.1f, HRV: %.3f, QRS: %.3fs, Qualidade: %s\n\n', ...
            caracteristicas.bpm, caracteristicas.hrv_std, ...
            caracteristicas.duracao_qrs, caracteristicas.qualidade_sinal);
        
    catch ME
        fprintf('  → ERRO na análise: %s\n\n', ME.message);
        
        % Armazenar como erro
        classificacoes(i).filename = resultados(i).filename;
        classificacoes(i).classe = 'Erro na Análise';
        classificacoes(i).bpm = 0;
        classificacoes(i).hrv = 0;
        classificacoes(i).duracao_qrs = 0;
        classificacoes(i).qualidade = 'Erro';
    end
end

%% RELATÓRIO FINAL - ABORDAGEM REALISTA
fprintf('\n=== DISTRIBUIÇÃO POR PADRÕES DETECTÁVEIS ===\n\n');

fprintf('LIMITAÇÕES RECONHECIDAS:\n');
fprintf('• ECG de 1 derivação tem capacidade diagnóstica limitada\n');
fprintf('• Diagnósticos específicos requerem ECG de 12 derivações\n');
fprintf('• Confirmação sempre necessária por médico cardiologista\n\n');

fprintf('TABELA - DISTRIBUIÇÃO POR PADRÃO ECG\n');
fprintf('%-45s | %-6s | %-8s\n', 'Padrão ECG', 'Nº', 'Percentual');
fprintf('%-45s-|-%-6s-|-%-8s\n', repmat('-',1,45), repmat('-',1,6), repmat('-',1,8));

total_sinais = length(classificacoes);
for i = 1:length(classes_detectaveis)
    if contagem_classes(i) > 0
        percentual = (contagem_classes(i) / total_sinais) * 100;
        fprintf('%-45s | %-6d | %-8.1f%%\n', ...
            classes_detectaveis{i}, contagem_classes(i), percentual);
    end
end

fprintf('%-45s-|-%-6s-|-%-8s\n', repmat('-',1,45), repmat('-',1,6), repmat('-',1,8));
fprintf('%-45s | %-6d | %-8.1f%%\n', 'TOTAL', total_sinais, 100);

%% ESTATÍSTICAS DETALHADAS
fprintf('\n=== ESTATÍSTICAS DETALHADAS ===\n');

% Calcular estatísticas dos sinais adequados
bpm_valores = [classificacoes.bpm];
bpm_validos = bpm_valores(bpm_valores > 0);

hrv_valores = [classificacoes.hrv];
hrv_validos = hrv_valores(hrv_valores > 0);

qrs_valores = [classificacoes.duracao_qrs];
qrs_validos = qrs_valores(qrs_valores > 0);

if ~isempty(bpm_validos)
    fprintf('Frequência Cardíaca: %.1f ± %.1f bpm (n=%d)\n', ...
        mean(bpm_validos), std(bpm_validos), length(bpm_validos));
end

if ~isempty(hrv_validos)
    fprintf('Variabilidade Cardíaca: %.3f ± %.3f s (n=%d)\n', ...
        mean(hrv_validos), std(hrv_validos), length(hrv_validos));
end

if ~isempty(qrs_validos)
    fprintf('Duração QRS: %.3f ± %.3f s (n=%d)\n', ...
        mean(qrs_validos), std(qrs_validos), length(qrs_validos));
end

%% VISUALIZAÇÃO GRÁFICA
figure('Position', [100, 100, 1400, 800]);

% Gráfico 1: Distribuição por classe
subplot(2,3,1);
idx_plot = contagem_classes > 0;
if sum(idx_plot) > 0
    bar(contagem_classes(idx_plot));
    set(gca, 'XTickLabel', classes_detectaveis(idx_plot), ...
             'XTickLabelRotation', 45, 'FontSize', 8);
    ylabel('Número de Sinais');
    title('Distribuição por Padrão ECG');
    grid on;
end

% Gráfico 2: Distribuição de BPM
subplot(2,3,2);
if ~isempty(bpm_validos)
    histogram(bpm_validos, 20);
    xlabel('BPM');
    ylabel('Frequência');
    title('Distribuição da Frequência Cardíaca');
    grid on;
    hold on;
    plot([60, 100], [0, 0], 'r-', 'LineWidth', 3);
    legend('Distribuição', 'Faixa Normal');
end

% Gráfico 3: Duração do QRS
subplot(2,3,3);
if ~isempty(qrs_validos)
    histogram(qrs_validos * 1000, 20); % Converter para ms
    xlabel('Duração QRS (ms)');
    ylabel('Frequência');
    title('Distribuição da Duração QRS');
    grid on;
    hold on;
    plot([100, 100], [0, max(histcounts(qrs_validos*1000, 20))], 'r-', 'LineWidth', 2);
    legend('Distribuição', 'Limite Normal');
end

% Gráfico 4: BPM vs HRV
subplot(2,3,4);
if ~isempty(bpm_validos) && ~isempty(hrv_validos)
    scatter(bpm_validos, hrv_validos, 50, 'filled', 'MarkerFaceAlpha', 0.6);
    xlabel('BPM');
    ylabel('HRV (std)');
    title('Relação BPM vs Variabilidade Cardíaca');
    grid on;
end

% Gráfico 5: Qualidade dos sinais
subplot(2,3,5);
qualidades = {classificacoes.qualidade};
qualidades_unicas = unique(qualidades);
contagem_qualidade = zeros(length(qualidades_unicas), 1);
for i = 1:length(qualidades_unicas)
    contagem_qualidade(i) = sum(strcmp(qualidades, qualidades_unicas{i}));
end
pie(contagem_qualidade, qualidades_unicas);
title('Qualidade dos Sinais');

% Gráfico 6: Sinal exemplo de cada classe principal
subplot(2,3,6);
text(0.1, 0.5, 'Análise Realista Concluída', 'FontSize', 14, 'FontWeight', 'bold');
text(0.1, 0.3, sprintf('Total de Sinais: %d', total_sinais), 'FontSize', 12);
text(0.1, 0.2, 'Padrões Baseados em Guidelines', 'FontSize', 10);
text(0.1, 0.1, 'AHA/ACC', 'FontSize', 10);
axis off;

%% SALVAR RESULTADOS
resultados_finais.classificacoes = classificacoes;
resultados_finais.classes_detectaveis = classes_detectaveis;
resultados_finais.contagem_classes = contagem_classes;
resultados_finais.sinais_por_classe = sinais_por_classe;
resultados_finais.parametros = parametros;

save('classificacao_realista_ecg.mat', 'resultados_finais');

fprintf('\n✓ Resultados salvos em: classificacao_realista_ecg.mat\n');
fprintf('=== ANÁLISE REALISTA CONCLUÍDA ===\n');

%% FUNÇÃO PARA DADOS DE EXEMPLO (caso o arquivo não exista)
function resultados = criar_dados_exemplo()
    fprintf('Criando dados de exemplo para demonstração...\n');
    
    resultados = struct();
    fs = 500;
    
    % Criar alguns sinais de exemplo com diferentes características
    exemplos = {
        {'s0010_re', 75, 0.08, 1.5},   % Normal
        {'s0014lre', 110, 0.09, 1.2},  % Taquicardia
        {'s0016lre', 45, 0.13, 0.8},   % Bradicardia + QRS alargado
        {'s0020_re', 85, 0.07, 0.05},  % Sinal fraco
        {'s0024lre', 95, 0.08, 2.5}    % Normal
    };
    
    for i = 1:length(exemplos)
        resultados(i).filename = exemplos{i}{1};
        t = 0:1/fs:10;
        
        % Criar sinal ECG sintético baseado nas características
        bpm = exemplos{i}{2};
        freq_fundamental = bpm / 60;
        
        sinal = 0.8 * sin(2*pi*freq_fundamental*t) + ...
                0.3 * sin(2*pi*2*freq_fundamental*t) + ...
                0.1 * sin(2*pi*0.3*t) + ... % baseline wander
                0.05 * randn(size(t));
        
        % Ajustar amplitude
        sinal = sinal * exemplos{i}{4};
        
        resultados(i).sinal_original = sinal;
        resultados(i).fs = fs;
    end
    
    fprintf('✓ %d sinais de exemplo criados\n', length(resultados));
end