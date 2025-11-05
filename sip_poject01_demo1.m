%% Configuração inicial
clear; close all; clc;
%load('main_db/ecg_db_patient_01')
%% Definir diretório da base de dados
data_dir = 'main_db/ecg_db_patient_01/';  % Ajuste conforme seu diretório

%% Função para listar arquivos .hea (arquivos de header)
function files = list_hea_files(directory)
    % Lista todos os arquivos .hea no diretório
    file_list = dir(fullfile(directory, '*.hea'));
    files = {file_list.name};
    
    % Remover a extensão .hea para obter o nome base
    for i = 1:length(files)
        [~, name, ~] = fileparts(files{i});
        files{i} = name;
    end
end

%% Função para carregar sinal WFDB (SIMULAÇÃO - já que não temos a toolbox)
function [ecg_signal, fs, info] = load_wfdb_signal(filename, data_dir)
    try
        % SIMULAÇÃO - Criar sinal ECG sintético para demonstração
        % Na prática, você usaria: [signal, ~, ~] = rdsamp(fullfile(data_dir, filename));
        
        fs = 500; % Frequência de amostragem padrão
        t = 0:1/fs:10; % 10 segundos de sinal
        duration = 10;
        
        % Criar sinal ECG sintético com algum ruído
        ecg_signal = 0.5 * sin(2*pi*1*t) + ... % Componente fundamental
                     0.2 * sin(2*pi*2*t) + ... % Harmônico
                     0.1 * sin(2*pi*0.5*t) + ... % Baseline wander
                     0.05 * randn(size(t)); % Ruído
        
        % Adicionar alguns artefatos baseados no nome do arquivo para teste
        if contains(filename, '50010')
            % Sinal bom
            ecg_signal = ecg_signal;
        elseif contains(filename, '50014')
            % Adicionar saturação
            ecg_signal(1000:1100) = 5;
        elseif contains(filename, '50016')
            % Adicionar ruído excessivo
            ecg_signal = ecg_signal + 0.5 * randn(size(t));
        end
        
        % Informações
        info.filename = filename;
        info.sampling_freq = fs;
        info.num_channels = 1;
        info.num_samples = length(ecg_signal);
        info.duration = duration;
        
        fprintf('Carregado: %s - %d amostras, %.1f segundos, FS: %.1f Hz\n', ...
            filename, info.num_samples, info.duration, fs);
        
    catch ME
        fprintf('Erro ao carregar %s: %s\n', filename, ME.message);
        ecg_signal = [];
        fs = [];
        info = [];
    end
end

%% Função para detecção de artefatos em ECG
function [artefato_detectado, motivo, metricas] = detectar_artefatos_ecg(sinal, fs, filename)
    artefato_detectado = false;
    motivo = 'Sinal válido';
    metricas = struct();
    
    if isempty(sinal) || length(sinal) < 10
        artefato_detectado = true;
        motivo = 'Sinal vazio ou muito curto';
        metricas.artefato_detectado = true;
        metricas.motivo = motivo;
        return;
    end
    
    % Converter para double e vetor coluna
    sinal = double(sinal(:));
    
    % Métricas básicas
    metricas.filename = filename;
    metricas.num_amostras = length(sinal);
    metricas.media = mean(sinal);
    metricas.desvio_padrao = std(sinal);
    metricas.variancia = var(sinal);
    metricas.maximo = max(sinal);
    metricas.minimo = min(sinal);
    metricas.range = metricas.maximo - metricas.minimo;
    metricas.fs = fs;
    metricas.duracao = metricas.num_amostras / fs;
    
    % 1. Verificar NaN/Inf
    if any(isnan(sinal)) || any(isinf(sinal))
        artefato_detectado = true;
        motivo = 'Valores NaN ou Inf detectados';
        metricas.artefato_detectado = true;
        metricas.motivo = motivo;
        return;
    end
    
    % 2. Verificar sinal plano (baixa variância)
    if metricas.variancia < 0.001
        artefato_detectado = true;
        motivo = 'Variância muito baixa (sinal plano)';
        metricas.artefato_detectado = true;
        metricas.motivo = motivo;
        return;
    end
    
    % 3. Verificar comprimento mínimo
    if metricas.num_amostras < 2 * fs
        artefato_detectado = true;
        motivo = sprintf('Sinal muito curto (%d amostras = %.1f s)', ...
            metricas.num_amostras, metricas.duracao);
        metricas.artefato_detectado = true;
        metricas.motivo = motivo;
        return;
    end
    
    % 4. Detecção de saturação
    limiar_saturacao = 5 * metricas.desvio_padrao;
    amostras_saturadas = sum(abs(sinal - metricas.media) > limiar_saturacao);
    percentual_saturado = (amostras_saturadas / metricas.num_amostras) * 100;
    
    if percentual_saturado > 5
        artefato_detectado = true;
        motivo = sprintf('Saturação (%.1f%% das amostras)', percentual_saturado);
        metricas.artefato_detectado = true;
        metricas.motivo = motivo;
        return;
    end
    
    % 5. Análise de ruído
    try
        if metricas.num_amostras > 3 * fs
            % Filtro passa-banda simplificado
            fc_low = 40;
            fc_high = 0.5;
            
            [b_low, a_low] = butter(2, fc_low/(fs/2), 'low');
            [b_high, a_high] = butter(2, fc_high/(fs/2), 'high');
            
            sinal_filtrado = filtfilt(b_low, a_low, sinal);
            sinal_filtrado = filtfilt(b_high, a_high, sinal_filtrado);
            
            ruido = sinal - sinal_filtrado;
            potencia_ruido = mean(ruido.^2);
            potencia_sinal = mean(sinal.^2);
            razao_ruido_sinal = potencia_ruido / potencia_sinal;
            
            metricas.potencia_ruido = potencia_ruido;
            metricas.razao_ruido_sinal = razao_ruido_sinal;
            metricas.SNR_estimado = 10 * log10(potencia_sinal / potencia_ruido);
            
            if razao_ruido_sinal > 0.1
                artefato_detectado = true;
                motivo = sprintf('Ruído excessivo (razão: %.3f)', razao_ruido_sinal);
                metricas.artefato_detectado = true;
                metricas.motivo = motivo;
                return;
            end
        end
    catch ME
        fprintf('Aviso: Erro na análise de ruído para %s: %s\n', filename, ME.message);
    end
    
    metricas.artefato_detectado = artefato_detectado;
    metricas.motivo = motivo;
end

%% Função para aplicar filtragem
function sinal_filtrado = filtrar_sinal_ecg(sinal, fs)
    if isempty(sinal) || length(sinal) < 3 * fs
        sinal_filtrado = sinal;
        return;
    end
    
    sinal = double(sinal(:));
    
    try
        fc_low = 40;
        fc_high = 0.5;
        
        [b_low, a_low] = butter(2, fc_low/(fs/2), 'low');
        [b_high, a_high] = butter(2, fc_high/(fs/2), 'high');
        
        sinal_filtrado = filtfilt(b_low, a_low, sinal);
        sinal_filtrado = filtfilt(b_high, a_high, sinal_filtrado);
        
    catch
        sinal_filtrado = sinal;
    end
end

%% PROCESSAMENTO PRINCIPAL - VERSÃO CORRIGIDA
fprintf('=== CARREGAMENTO E PROCESSAMENTO DA BASE DE DADOS ECG ===\n');

% Listar arquivos
arquivos_hea = list_hea_files(data_dir);
fprintf('Encontrados %d arquivos na base de dados:\n', length(arquivos_hea));
for i = 1:length(arquivos_hea)
    fprintf('  %d. %s\n', i, arquivos_hea{i});
end

% Inicializar estruturas CORRETAMENTE
resultados = [];
sinais_validos = {};
sinais_removidos = {};

% Processar cada arquivo
for i = 1:length(arquivos_hea)
    filename = arquivos_hea{i};
    fprintf('\n[%d/%d] Processando: %s\n', i, length(arquivos_hea), filename);
    
    % Carregar sinal
    [ecg_signal, fs, info] = load_wfdb_signal(filename, data_dir);
    
    if isempty(ecg_signal)
        fprintf('  → Não foi possível carregar o sinal\n');
        % Adicionar entrada vazia aos resultados
        resultados(i).filename = filename;
        resultados(i).artefato_detectado = true;
        resultados(i).motivo = 'Falha no carregamento';
        resultados(i).metricas.num_amostras = 0;
        resultados(i).metricas.duracao = 0;
        resultados(i).fs = 0;
        continue;
    end
    
    % Detectar artefatos
    [artefato, motivo, metricas] = detectar_artefatos_ecg(ecg_signal, fs, filename);
    
    % Aplicar filtragem se o sinal for válido
    if ~artefato
        sinal_filtrado = filtrar_sinal_ecg(ecg_signal, fs);
    else
        sinal_filtrado = [];
    end
    
    % Armazenar resultados CORRETAMENTE
    resultados(i).filename = filename;
    resultados(i).sinal_original = ecg_signal;
    resultados(i).sinal_filtrado = sinal_filtrado;
    resultados(i).artefato_detectado = artefato;
    resultados(i).motivo = motivo;
    resultados(i).metricas = metricas;
    resultados(i).fs = fs;
    resultados(i).info = info;
    
    if artefato
        sinais_removidos{end+1} = filename;
        fprintf('  → ❌ REMOVIDO: %s\n', motivo);
    else
        sinais_validos{end+1} = filename;
        fprintf('  → ✅ VÁLIDO: %s\n', motivo);
    end
end

%% ESTATÍSTICAS E RELATÓRIOS - VERSÃO CORRIGIDA
fprintf('\n\n=== RELATÓRIO FINAL ===\n');

% Verificar se resultados foi criado corretamente
if isempty(resultados)
    fprintf('Nenhum resultado foi processado.\n');
    return;
end

total_processados = length(arquivos_hea);
total_validos = length(sinais_validos);
total_removidos = length(sinais_removidos);

fprintf('Total de sinais processados: %d\n', total_processados);
fprintf('Sinais válidos: %d\n', total_validos);
fprintf('Sinais removidos: %d\n', total_removidos);

if total_processados > 0
    fprintf('Taxa de remoção: %.1f%%\n', (total_removidos/total_processados)*100);
else
    fprintf('Taxa de remoção: 0.0%%\n');
end

%% Tabela resumo - VERSÃO CORRIGIDA
fprintf('\n=== TABELA RESUMO ===\n');
fprintf('%-15s | %-8s | %-10s | %-8s | %-12s | %-s\n', ...
    'Arquivo', 'Amostras', 'Duração(s)', 'FS(Hz)', 'Status', 'Motivo');
fprintf('%-15s-|-%-8s-|-%-10s-|-%-8s-|-%-12s-|-%-s\n', ...
    repmat('-',1,15), repmat('-',1,8), repmat('-',1,10), ...
    repmat('-',1,8), repmat('-',1,12), repmat('-',1,20));

for i = 1:length(resultados)
    % Verificar se o campo existe antes de acessá-lo
    if ~isempty(resultados(i)) && isfield(resultados(i), 'artefato_detectado')
        r = resultados(i);
        status = 'VÁLIDO';
        if r.artefato_detectado
            status = 'REMOVIDO';
        end
        
        % Verificar se as métricas existem
        if isfield(r, 'metricas') && isfield(r.metricas, 'num_amostras')
            num_amostras = r.metricas.num_amostras;
            duracao = r.metricas.duracao;
        else
            num_amostras = 0;
            duracao = 0;
        end
        
        if isfield(r, 'fs')
            fs_val = r.fs;
        else
            fs_val = 0;
        end
        
        fprintf('%-15s | %-8d | %-10.1f | %-8.1f | %-12s | %-s\n', ...
            r.filename, num_amostras, duracao, fs_val, status, r.motivo);
    else
        fprintf('%-15s | %-8s | %-10s | %-8s | %-12s | %-s\n', ...
            arquivos_hea{i}, 'N/A', 'N/A', 'N/A', 'ERRO', 'Estrutura inválida');
    end
end

%% Visualização de exemplos - VERSÃO CORRIGIDA
fprintf('\n=== VISUALIZAÇÃO DE EXEMPLOS ===\n');

% Encontrar exemplos de forma segura
idx_valido = [];
idx_removido = [];

for i = 1:length(resultados)
    if ~isempty(resultados(i)) && isfield(resultados(i), 'artefato_detectado')
        if ~resultados(i).artefato_detectado && isempty(idx_valido)
            idx_valido = i;
        elseif resultados(i).artefato_detectado && isempty(idx_removido)
            idx_removido = i;
        end
    end
end

if ~isempty(idx_valido) && ~isempty(idx_removido)
    figure('Position', [100, 100, 1400, 800]);
    
    % Plot sinal válido
    subplot(2,2,1);
    r_valido = resultados(idx_valido);
    plot(r_valido.sinal_original, 'b', 'LineWidth', 1);
    hold on;
    if ~isempty(r_valido.sinal_filtrado)
        plot(r_valido.sinal_filtrado, 'r', 'LineWidth', 1.5);
        legend('Original', 'Filtrado', 'Location', 'best');
    end
    title(sprintf('SINAL VÁLIDO: %s', r_valido.filename));
    xlabel('Amostras'); ylabel('Amplitude'); grid on;
    
    % Plot sinal removido
    subplot(2,2,2);
    r_removido = resultados(idx_removido);
    plot(r_removido.sinal_original, 'b', 'LineWidth', 1);
    title(sprintf('SINAL REMOVIDO: %s\n%s', r_removido.filename, r_removido.motivo));
    xlabel('Amostras'); ylabel('Amplitude'); grid on;
    
else
    fprintf('Não foram encontrados exemplos suficientes para visualização.\n');
end

%% Salvar resultados
fprintf('\nSalvando resultados...\n');
try
    save('resultados_processamento_ecg.mat', 'resultados', 'sinais_validos', 'sinais_removidos');
    fprintf('Resultados salvos em: resultados_processamento_ecg.mat\n');
catch
    fprintf('Aviso: Não foi possível salvar os resultados.\n');
end

fprintf('\n=== PROCESSAMENTO CONCLUÍDO ===\n');