%% CARREGAR E EXPLORAR O ARQUIVO DE DADOS
fprintf('=== CARREGANDO ARQUIVO classficacao_realista_ecg.mat ===\n');

% Carregar o arquivo .mat
loaded_data = load('classificacao_realista_ecg.mat');

% Explorar a estrutura do arquivo
fprintf('Variáveis carregadas do arquivo:\n');
whos

% Verificar nomes das variáveis
variable_names = fieldnames(loaded_data);
fprintf('\nVariáveis encontradas no arquivo:\n');
for i = 1:length(variable_names)
    fprintf('%d: %s\n', i, variable_names{i});
end

% Examinar a primeira variável
if ~isempty(variable_names)
    first_var = loaded_data.(variable_names{1});
    fprintf('\nEstrutura da variável "%s":\n', variable_names{1});
    
    if isstruct(first_var)
        fprintf('É uma estrutura com campos:\n');
        field_names = fieldnames(first_var);
        for i = 1:length(field_names)
            fprintf('  - %s\n', field_names{i});
        end
        
        % Mostrar tamanho se for um array de estruturas
        if length(first_var) > 1
            fprintf('Tamanho do array de estruturas: %d elementos\n', length(first_var));
        end
    else
        fprintf('Tipo: %s\n', class(first_var));
        fprintf('Dimensões: %s\n', mat2str(size(first_var)));
    end
end

%% CONTINUAÇÃO COM FEATURE EXTRACTION BASEADA NOS DADOS CARREGADOS
fprintf('\n=== INICIANDO FEATURE EXTRACTION COM DWT ===\n');

% Usar a variável carregada como dados de ECG
% Assumindo que a variável principal contém os dados de ECG
if ~isempty(variable_names)
    ecg_dataset = loaded_data.(variable_names{1});
    
    % Verificar se é estrutura ou matriz
    if isstruct(ecg_dataset)
        fprintf('Processando estrutura de dados ECG...\n');
        
        % Parâmetros para extração de características
        fs = 360; % Frequência de amostragem assumida do MIT-BIH
        segment_duration = 1.0; % segmentos de 1 segundo
        wavelet_name = 'db4';
        decomposition_level = 5;
        
        % Inicializar estrutura para características
        wavelet_features = struct();
        
        % Processar cada paciente/registro na estrutura
        for patient_idx = 1:length(ecg_dataset)
            fprintf('Processando paciente %d/%d...\n', patient_idx, length(ecg_dataset));
            
            current_patient = ecg_dataset(patient_idx);
            
            % Verificar campos disponíveis
            available_fields = fieldnames(current_patient);
            fprintf('Campos disponíveis: %s\n', strjoin(available_fields, ', '));
            
            % Procurar por sinais ECG (assumindo que contém leads como MLII, V1, etc.)
            ecg_leads = {};
            for i = 1:length(available_fields)
                field_name = available_fields{i};
                field_data = current_patient.(field_name);
                
                % Verificar se é um sinal ECG (vetor numérico)
                if isnumeric(field_data) && isvector(field_data) && length(field_data) > 100
                    ecg_leads{end+1} = field_name;
                end
            end
            
            fprintf('Leads ECG encontrados: %s\n', strjoin(ecg_leads, ', '));
            
            % Processar cada lead ECG
            all_features = {};
            feature_labels = {};
            
            for lead_idx = 1:length(ecg_leads)
                lead_name = ecg_leads{lead_idx};
                ecg_signal = current_patient.(lead_name);
                
                % Pré-processamento básico
                ecg_signal = ecg_signal(~isnan(ecg_signal));
                ecg_signal = ecg_signal - mean(ecg_signal); % Remover DC
                
                if length(ecg_signal) >= fs * segment_duration
                    % Segmentar o sinal em segmentos de 1 segundo
                    samples_per_segment = fs * segment_duration;
                    num_segments = floor(length(ecg_signal) / samples_per_segment);
                    
                    % Extrair características de cada segmento
                    lead_features = zeros(num_segments, 10);
                    
                    for seg_idx = 1:num_segments
                        start_sample = (seg_idx-1) * samples_per_segment + 1;
                        end_sample = seg_idx * samples_per_segment;
                        segment_data = ecg_signal(start_sample:end_sample);
                        
                        % Aplicar Discrete Wavelet Transform
                        [c, l] = wavedec(segment_data, decomposition_level, wavelet_name);
                        
                        % Extrair 10 características
                        features = extract_wavelet_features(c, l, wavelet_name);
                        lead_features(seg_idx, :) = features;
                    end
                    
                    all_features{end+1} = lead_features;
                    feature_labels{end+1} = lead_name;
                    
                    fprintf('  Lead %s: %d segmentos processados\n', lead_name, num_segments);
                else
                    fprintf('  Lead %s: Sinal muito curto\n', lead_name);
                end
            end
            
            % Armazenar características
            if isfield(current_patient, 'record_name')
                patient_id = current_patient.record_name;
            else
                patient_id = sprintf('Paciente_%d', patient_idx);
            end
            
            wavelet_features(patient_idx).patient_id = patient_id;
            wavelet_features(patient_idx).features = all_features;
            wavelet_features(patient_idx).feature_labels = feature_labels;
            wavelet_features(patient_idx).parameters = struct(...
                'wavelet', wavelet_name, ...
                'decomposition_level', decomposition_level, ...
                'segment_duration', segment_duration, ...
                'sampling_rate', fs);
        end
        
    else
        fprintf('Processando matriz de dados ECG...\n');
        % Se for uma matriz, processar diretamente
        % (implementação similar mas adaptada para matriz)
    end
    
else
    error('Nenhuma variável encontrada no arquivo .mat');
end

%% FUNÇÃO AUXILIAR PARA EXTRAIR CARACTERÍSTICAS WAVELET
function features = extract_wavelet_features(c, l, wavelet_name)
    % Extrair 10 características dos coeficientes wavelet
    
    features = zeros(1, 10);
    
    % Coeficientes de aproximação
    approx_coeff = appcoef(c, l, wavelet_name);
    
    % Coeficientes de detalhe
    detail_coeffs = cell(1, length(l)-2);
    for level = 1:length(l)-2
        detail_coeffs{level} = detcoef(c, l, level);
    end
    
    % 1. Energia dos coeficientes de aproximação
    features(1) = sum(approx_coeff.^2);
    
    % 2-6. Energia dos coeficientes de detalhe (5 níveis)
    for level = 1:min(5, length(detail_coeffs))
        features(1 + level) = sum(detail_coeffs{level}.^2);
    end
    
    % 7. Entropia dos coeficientes de aproximação
    if ~isempty(approx_coeff)
        features(7) = wentropy(approx_coeff, 'shannon');
    else
        features(7) = 0;
    end
    
    % 8. Média dos coeficientes de aproximação
    features(8) = mean(approx_coeff);
    
    % 9. Desvio padrão dos coeficientes de aproximação
    features(9) = std(approx_coeff);
    
    % 10. Razão entre energia de detalhe e aproximação
    total_detail_energy = sum(features(2:6));
    if features(1) > 0
        features(10) = total_detail_energy / features(1);
    else
        features(10) = 0;
    end
end

%% SALVAR CARACTERÍSTICAS EXTRAÍDAS
fprintf('\n=== SALVANDO CARACTERÍSTICAS EXTRAÍDAS ===\n');

% Criar nome do arquivo de saída baseado no arquivo original
[~, base_name, ~] = fileparts('classificacao_realista_ecg.mat');
output_filename = sprintf('%s_wavelet_features.mat', base_name);

% Salvar características
save(output_filename, 'wavelet_features', '-v7.3');
fprintf('Características salvas em: %s\n', output_filename);

fprintf('\n=== PROCESSO CONCLUÍDO ===\n');
fprintf('✓ Arquivo carregado e explorado\n');
fprintf('✓ Feature extraction com DWT realizada\n');
fprintf('✓ 10 características por segmento de 1 segundo extraídas\n');
fprintf('✓ Resultados salvos em arquivo\n');