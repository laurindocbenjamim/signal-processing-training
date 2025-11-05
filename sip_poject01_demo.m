%% Configuração inicial
clear; close all; clc;

%% Definir diretório da base de dados
data_dir = 'main_db/ecg_db_patient_01';  % Ajuste conforme seu diretório

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

%% FUNÇÃO MELHORADA: Carregar sinal WFDB (Automático - detecta toolbox)
function [ecg_signal, fs, info] = load_wfdb_signal_auto(filename, data_dir)
    try
        % Verificar se Waveform Toolbox está disponível
        has_waveform_toolbox = exist('rdsamp', 'file') == 2;
        
        if has_waveform_toolbox
            fprintf('  → Usando Waveform Toolbox\n');
            [ecg_signal, fs, info] = load_with_waveform_toolbox(filename, data_dir);
        else
            fprintf('  → Usando leitura manual\n');
            [ecg_signal, fs, info] = load_with_manual_reading(filename, data_dir);
        end
        
    catch ME
        fprintf('❌ Erro ao carregar %s: %s\n', filename, ME.message);
        ecg_signal = [];
        fs = [];
        info = [];
    end
end

%% Função para carregar COM Waveform Toolbox
function [ecg_signal, fs, info] = load_with_waveform_toolbox(filename, data_dir)
    try
        % Carregar sinal real usando Waveform Toolbox
        [ecg_signal, fs, ~] = rdsamp(fullfile(data_dir, filename));
        
        % Obter anotações se disponíveis
        try
            [~, ~, ~, ~, anotacoes] = rdann(fullfile(data_dir, filename), 'atr');
            info.anotacoes = anotacoes;
        catch
            info.anotacoes = [];
        end
        
        info.filename = filename;
        info.sampling_freq = fs;
        info.num_channels = size(ecg_signal, 2);
        info.num_samples = size(ecg_signal, 1);
        info.duration = info.num_samples / fs;
        info.load_method = 'Waveform_Toolbox';
        
        fprintf('✅ Carregado: %s - %d amostras, %.1f segundos, FS: %.1f Hz\n', ...
            filename, info.num_samples, info.duration, fs);
        
    catch ME
        error('Falha Waveform Toolbox: %s', ME.message);
    end
end

%% Função para carregar SEM Waveform Toolbox (leitura manual)
function [ecg_signal, fs, info] = load_with_manual_reading(filename, data_dir)
    try
        % 1. Ler arquivo .hea para obter metadados
        hea_path = fullfile(data_dir, [filename '.hea']);
        if ~exist(hea_path, 'file')
            error('Arquivo .hea não encontrado: %s', hea_path);
        end
        
        hea_content = fileread(hea_path);
        lines = strsplit(hea_content, '\n');
        
        % 2. Parse do header (formato WFDB)
        first_line = strsplit(lines{1});
        if length(first_line) < 4
            error('Formato de header inválido');
        end
        
        num_channels = str2double(first_line{2});
        fs = str2double(first_line{3});
        num_samples = str2double(first_line{4});
        
        % 3. Encontrar arquivo de dados
        data_file = '';
        possible_extensions = {'.dat', '.mat', '.csv', '.txt'};
        
        for i = 1:length(possible_extensions)
            test_path = fullfile(data_dir, [filename possible_extensions{i}]);
            if exist(test_path, 'file')
                data_file = test_path;
                fprintf('  → Arquivo de dados encontrado: %s\n', possible_extensions{i});
                break;
            end
        end
        
        if isempty(data_file)
            error('Nenhum arquivo de dados encontrado para %s', filename);
        end
        
        % 4. Carregar dados baseado na extensão
        [~, ~, ext] = fileparts(data_file);
        fprintf('  → Lendo formato: %s\n', ext);
        
        switch lower(ext)
            case '.mat'
                data = load(data_file);
                % Tentar encontrar o sinal ECG em várias possíveis variáveis
                if isfield(data, 'ecg_signal')
                    ecg_signal = data.ecg_signal;
                elseif isfield(data, 'signal')
                    ecg_signal = data.signal;
                elseif isfield(data, 'val')
                    ecg_signal = data.val;
                else
                    % Pegar primeira variável numérica
                    field_names = fieldnames(data);
                    for f = 1:length(field_names)
                        if isnumeric(data.(field_names{f}))
                            ecg_signal = data.(field_names{f});
                            break;
                        end
                    end
                end
                
            case '.dat'
                % Para arquivos .dat binários do WFDB (formato 16-bit)
                ecg_signal = read_wfdb_dat(data_file, num_samples, num_channels);
                
            case {'.csv', '.txt'}
                ecg_signal = readmatrix(data_file);
                
            otherwise
                error('Formato não suportado: %s', ext);
        end
        
        % 5. Processar e validar o sinal
        if ~exist('ecg_signal', 'var') || isempty(ecg_signal)
            error('Não foi possível extrair o sinal ECG do arquivo');
        end
        
        % Garantir que é vetor coluna
        if size(ecg_signal, 2) > size(ecg_signal, 1)
            ecg_signal = ecg_signal';
        end
        
        % Pegar apenas primeiro canal se for multicanal
        if size(ecg_signal, 2) > 1
            fprintf('  → Sinal multicanal (%d canais), usando canal 1\n', size(ecg_signal, 2));
            ecg_signal = ecg_signal(:, 1);
        end
        
        % Verificar se o tamanho corresponde ao header
        if num_samples > 0 && length(ecg_signal) ~= num_samples
            fprintf('  ⚠ Aviso: Número de amostras difere do header (%d vs %d)\n', ...
                length(ecg_signal), num_samples);
        end
        
        info.filename = filename;
        info.sampling_freq = fs;
        info.num_samples = length(ecg_signal);
        info.duration = info.num_samples / fs;
        info.data_file = data_file;
        info.load_method = 'Manual_Reading';
        info.original_num_samples = num_samples;
        info.original_num_channels = num_channels;
        
        fprintf('✅ Carregado: %s - %d amostras, %.1f segundos, FS: %.1f Hz\n', ...
            filename, info.num_samples, info.duration, fs);
        
    catch ME
        error('Falha leitura manual: %s', ME.message);
    end
end

%% Função auxiliar para ler arquivos .dat do WFDB
function signal = read_wfdb_dat(filename, num_samples, num_channels)
    fid = fopen(filename, 'r', 'b');  'big-endian'
    if fid == -1
        error('Não foi possível abrir o arquivo: %s', filename);
    end
    
    try
        % WFDB geralmente usa formato 16-bit
        if num_samples > 0 && num_channels > 0
            signal_data = fread(fid, [num_channels, num_samples], 'int16');
        else
            % Se não sabemos o tamanho, ler até o final
            signal_data = fread(fid, inf, 'int16');
            num_channels = 1;
            if mod(length(signal_data), 2) == 0
                signal_data = reshape(signal_data, num_channels, []);
            end
        end
        fclose(fid);
        
        signal = signal_data';
        
    catch
        fclose(fid);
        error('Erro na leitura do arquivo .dat');
    end
end

%% FUNÇÃO MELHORADA: Detecção de artefatos em ECG
%% FUNÇÃO CORRIGIDA: Detecção de artefatos em ECG (parâmetros ajustados)
function [artefato_detectado, motivo, metricas] = detectar_artefatos_ecg_ajustado(sinal, fs, filename)
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
    
    % 2. Verificar sinal plano (baixa variância) - LIMIAR MAIS FLEXÍVEL
    if metricas.variancia < 0.00001  % Reduzido de 0.0001 para 0.00001
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
    
    % 4. Detecção de saturação - LIMIAR MAIS FLEXÍVEL
    limiar_saturacao = 8 * metricas.desvio_padrao;  % Aumentado de 5 para 8
    amostras_saturadas = sum(abs(sinal - metricas.media) > limiar_saturacao);
    percentual_saturado = (amostras_saturadas / metricas.num_amostras) * 100;
    
    if percentual_saturado > 10  % Aumentado de 5% para 10%
        artefato_detectado = true;
        motivo = sprintf('Saturação (%.1f%% das amostras)', percentual_saturado);
        metricas.artefato_detectado = true;
        metricas.motivo = motivo;
        return;
    end
    
    % 5. Análise de ruído MELHORADA - LIMIAR MAIS FLEXÍVEL
    try
        if metricas.num_amostras > 3 * fs
            % Filtro passa-banda para ECG (0.5-40 Hz)
            fc_low = 40;
            fc_high = 0.5;
            
            [b_band, a_band] = butter(2, [fc_high, fc_low]/(fs/2), 'bandpass');
            sinal_filtrado = filtfilt(b_band, a_band, sinal);
            
            % Ruído = diferença entre original e filtrado
            ruido = sinal - sinal_filtrado;
            potencia_ruido = mean(ruido.^2);
            potencia_sinal = mean(sinal_filtrado.^2);
            
            if potencia_sinal > 0
                razao_ruido_sinal = potencia_ruido / potencia_sinal;
                metricas.potencia_ruido = potencia_ruido;
                metricas.razao_ruido_sinal = razao_ruido_sinal;
                metricas.SNR_estimado = 10 * log10(potencia_sinal / potencia_ruido);
                
                % LIMIAR MUITO MAIS FLEXÍVEL para ECG real
                if razao_ruido_sinal > 2.0  % Aumentado de 0.2 para 2.0
                    artefato_detectado = true;
                    motivo = sprintf('Ruído excessivo (razão: %.3f, SNR: %.1f dB)', ...
                        razao_ruido_sinal, metricas.SNR_estimado);
                    metricas.artefato_detectado = true;
                    metricas.motivo = motivo;
                    return;
                else
                    fprintf('  → Razão ruído/sinal: %.3f (SNR: %.1f dB) - ACEITÁVEL\n', ...
                        razao_ruido_sinal, metricas.SNR_estimado);
                end
            end
        end
    catch ME
        fprintf('Aviso: Erro na análise de ruído para %s: %s\n', filename, ME.message);
    end
    
    % 6. NOVA VERIFICAÇÃO: Análise de picos R (se sinal for ECG)
    try
        if metricas.num_amostras > 5 * fs
            % Tentar detectar batimentos cardíacos
            [num_batimentos, freq_cardiaca] = estimar_frequencia_cardiaca(sinal, fs);
            metricas.num_batimentos_estimados = num_batimentos;
            metricas.freq_cardiaca_estimada = freq_cardiaca;
            
            if num_batimentos > 0
                fprintf('  → Frequência cardíaca estimada: %.1f bpm (%d batimentos)\n', ...
                    freq_cardiaca, num_batimentos);
                
                % Verificar se a frequência cardíaca está em range plausível
                if freq_cardiaca < 30 || freq_cardiaca > 200
                    artefato_detectado = true;
                    motivo = sprintf('Frequência cardíaca implausível: %.1f bpm', freq_cardiaca);
                    metricas.artefato_detectado = true;
                    metricas.motivo = motivo;
                    return;
                end
            end
        end
    catch ME
        fprintf('Aviso: Erro na análise de frequência cardíaca: %s\n', ME.message);
    end
    
    metricas.artefato_detectado = artefato_detectado;
    metricas.motivo = motivo;
end

%% FUNÇÃO MELHORADA: Aplicar filtragem
function sinal_filtrado = filtrar_sinal_ecg_melhorado(sinal, fs)
    if isempty(sinal) || length(sinal) < 3 * fs
        sinal_filtrado = sinal;
        return;
    end
    
    sinal = double(sinal(:));
    
    try
        % Parâmetros otimizados para ECG
        fc_high = 0.5;  % Remove baseline wander
        fc_low = 40;    % Preserva características do QRS
        
        % Aplicar filtro passa-banda
        [b_band, a_band] = butter(2, [fc_high, fc_low]/(fs/2), 'bandpass');
        sinal_filtrado = filtfilt(b_band, a_band, sinal);
        
        % Remover tendência suavemente
        sinal_filtrado = detrend(sinal_filtrado);
        
        % Normalizar amplitude
        sinal_filtrado = sinal_filtrado / std(sinal_filtrado);
        
    catch
        fprintf('Aviso: Falha na filtragem avançada, usando filtro simples\n');
        % Filtro fallback simples
        sinal_filtrado = sinal - movmean(sinal, round(fs/2));
    end
end

%% PROCESSAMENTO PRINCIPAL - VERSÃO MELHORADA
fprintf('=== CARREGAMENTO E PROCESSAMENTO DA BASE DE DADOS ECG ===\n');
fprintf('Diretório: %s\n', data_dir);

% Verificar se diretório existe
if ~exist(data_dir, 'dir')
    fprintf('❌ ERRO: Diretório não encontrado: %s\n', data_dir);
    fprintf('   Verifique o caminho e tente novamente.\n');
    return;
end

% Listar arquivos
arquivos_hea = list_hea_files(data_dir);
fprintf('Encontrados %d arquivos .hea na base de dados:\n', length(arquivos_hea));
for i = 1:length(arquivos_hea)
    fprintf('  %d. %s\n', i, arquivos_hea{i});
end

if isempty(arquivos_hea)
    fprintf('❌ Nenhum arquivo .hea encontrado no diretório.\n');
    fprintf('   Verifique se os arquivos estão no formato correto.\n');
    return;
end

% Inicializar estruturas
resultados = struct();
sinais_validos = {};
sinais_removidos = {};

% Processar cada arquivo
for i = 1:length(arquivos_hea)
    filename = arquivos_hea{i};
    fprintf('\n[%d/%d] Processando: %s\n', i, length(arquivos_hea), filename);
    
    % Carregar sinal (automático - detecta toolbox)
    [ecg_signal, fs, info] = load_wfdb_signal_auto(filename, data_dir);
    
    if isempty(ecg_signal)
        fprintf('  → ❌ Não foi possível carregar o sinal\n');
        % Adicionar entrada vazia aos resultados
        resultados(i).filename = filename;
        resultados(i).artefato_detectado = true;
        resultados(i).motivo = 'Falha no carregamento';
        resultados(i).metricas.num_amostras = 0;
        resultados(i).metricas.duracao = 0;
        resultados(i).fs = 0;
        sinais_removidos{end+1} = filename;
        continue;
    end
    
    % Detectar artefatos
    [artefato, motivo, metricas] = detectar_artefatos_ecg_ajustado(ecg_signal, fs, filename);
    
    % Aplicar filtragem se o sinal for válido
    if ~artefato
        sinal_filtrado = filtrar_sinal_ecg_melhorado(ecg_signal, fs);
    else
        sinal_filtrado = [];
    end
    
    % Armazenar resultados
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

%% ESTATÍSTICAS E RELATÓRIOS
fprintf('\n\n=== RELATÓRIO FINAL ===\n');

total_processados = length(arquivos_hea);
total_validos = length(sinais_validos);
total_removidos = length(sinais_removidos);

fprintf('Total de sinais processados: %d\n', total_processados);
fprintf('Sinais válidos: %d\n', total_validos);
fprintf('Sinais removidos: %d\n', total_removidos);

if total_processados > 0
    fprintf('Taxa de sucesso: %.1f%%\n', (total_validos/total_processados)*100);
    fprintf('Taxa de remoção: %.1f%%\n', (total_removidos/total_processados)*100);
end

%% Tabela resumo detalhada
fprintf('\n=== TABELA RESUMO DETALHADA ===\n');
fprintf('%-15s | %-8s | %-6s | %-10s | %-8s | %-12s | %-s\n', ...
    'Arquivo', 'Amostras', 'FS(Hz)', 'Duração(s)', 'Método', 'Status', 'Motivo');
fprintf('%-15s-|-%-8s-|-%-6s-|-%-10s-|-%-8s-|-%-12s-|-%-s\n', ...
    repmat('-',1,15), repmat('-',1,8), repmat('-',1,6), repmat('-',1,10), ...
    repmat('-',1,8), repmat('-',1,12), repmat('-',1,20));

for i = 1:length(resultados)
    if isfield(resultados(i), 'artefato_detectado')
        r = resultados(i);
        status = 'VÁLIDO';
        if r.artefato_detectado
            status = 'REMOVIDO';
        end
        
        % Obter método de carregamento
        if isfield(r, 'info') && isfield(r.info, 'load_method')
            metodo = r.info.load_method;
        else
            metodo = 'N/A';
        end
        
        % Obter métricas
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
        
        fprintf('%-15s | %-8d | %-6.0f | %-10.1f | %-8s | %-12s | %-s\n', ...
            r.filename, num_amostras, fs_val, duracao, metodo, status, r.motivo);
    end
end

%% Visualização de exemplos
fprintf('\n=== VISUALIZAÇÃO DE EXEMPLOS ===\n');

% Encontrar exemplos
idx_valido = [];
idx_removido = [];

for i = 1:length(resultados)
    if isfield(resultados(i), 'artefato_detectado')
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
    t_valido = (0:length(r_valido.sinal_original)-1) / r_valido.fs;
    plot(t_valido, r_valido.sinal_original, 'b', 'LineWidth', 1);
    hold on;
    if ~isempty(r_valido.sinal_filtrado)
        plot(t_valido, r_valido.sinal_filtrado, 'r', 'LineWidth', 1.5);
        legend('Original', 'Filtrado', 'Location', 'best');
    end
    title(sprintf('SINAL VÁLIDO: %s\n(%s)', r_valido.filename, r_valido.info.load_method));
    xlabel('Tempo (s)'); ylabel('Amplitude'); grid on;
    
    % Plot sinal removido
    subplot(2,2,2);
    r_removido = resultados(idx_removido);
    t_removido = (0:length(r_removido.sinal_original)-1) / r_removido.fs;
    plot(t_removido, r_removido.sinal_original, 'b', 'LineWidth', 1);
    title(sprintf('SINAL REMOVIDO: %s\n%s', r_removido.filename, r_removido.motivo));
    xlabel('Tempo (s)'); ylabel('Amplitude'); grid on;
    
    % Histograma de amplitudes (válido)
    subplot(2,2,3);
    histogram(r_valido.sinal_original, 50, 'FaceColor', 'blue', 'FaceAlpha', 0.7);
    hold on;
    if ~isempty(r_valido.sinal_filtrado)
        histogram(r_valido.sinal_filtrado, 50, 'FaceColor', 'red', 'FaceAlpha', 0.7);
        legend('Original', 'Filtrado');
    end
    title('Distribuição de Amplitudes (Válido)');
    xlabel('Amplitude'); ylabel('Frequência');
    grid on;
    
    % Métricas comparativas
    subplot(2,2,4);
    if isfield(r_valido, 'metricas')
        texto_metricas = sprintf(['MÉTRICAS DO SINAL VÁLIDO:\n' ...
                               'Amostras: %d\n' ...
                               'Duração: %.1f s\n' ...
                               'FS: %.0f Hz\n' ...
                               'Média: %.4f\n' ...
                               'STD: %.4f\n' ...
                               'Range: %.4f\n' ...
                               'Método: %s'], ...
                              r_valido.metricas.num_amostras, ...
                              r_valido.metricas.duracao, ...
                              r_valido.fs, ...
                              r_valido.metricas.media, ...
                              r_valido.metricas.desvio_padrao, ...
                              r_valido.metricas.range, ...
                              r_valido.info.load_method);
        text(0.1, 0.7, texto_metricas, 'Units', 'normalized', 'FontSize', 10);
    end
    axis off;
    
else
    fprintf('Não foram encontrados exemplos suficientes para visualização.\n');
end

%% Salvar resultados
fprintf('\nSalvando resultados...\n');
try
    save('filtered_datasets/resultados_processamento_ecg_me.mat', 'resultados', 'sinais_validos', 'sinais_removidos', '-v7.3');
    fprintf('✅ Resultados salvos em: resultados_processamento_ecg.mat\n');
    
    % Estatísticas do arquivo salvo
    file_info = dir('resultados_processamento_ecg.mat');
    fprintf('   Tamanho do arquivo: %.1f MB\n', file_info.bytes/(1024^2));
    
catch ME
    fprintf('❌ Aviso: Não foi possível salvar os resultados: %s\n', ME.message);
end

fprintf('\n=== PROCESSAMENTO CONCLUÍDO ===\n');