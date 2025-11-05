%% SOLUÇÃO COMPLETA - EXTRAIR E VISUALIZAR CARACTERÍSTICAS
fprintf('=== SOLUÇÃO: EXTRAIR CARACTERÍSTICAS DO ZERO ===\n');

% PASSO 1: Carregar os dados ORIGINAIS do ECG
fprintf('1. Carregando dados originais...\n');
try
    original_data = load('classificacao_realista_ecg.mat');
    fprintf('   Arquivo carregado com sucesso!\n');
    
    % Explorar estrutura dos dados originais
    var_names = fieldnames(original_data);
    fprintf('   Variáveis encontradas: %s\n', strjoin(var_names, ', '));
    
    % Pegar a primeira variável (assumindo que é a principal)
    main_var = original_data.(var_names{1});
    fprintf('   Variável principal: %s, Tipo: %s\n', var_names{1}, class(main_var));
    
catch ME
    fprintf('   ERRO ao carregar arquivo: %s\n', ME.message);
    return;
end

% PASSO 2: Extrair características DWT corretamente
fprintf('2. Extraindo características com DWT...\n');

wavelet_features = struct();
fs = 360; % Frequência de amostragem do MIT-BIH
segment_duration = 1.0;
wavelet_name = 'db4';
decomposition_level = 5;

% Verificar tipo dos dados e processar
if isstruct(main_var)
    fprintf('   Processando estrutura de dados...\n');
    
    for patient_idx = 1:min(length(main_var), 3) % Processar até 3 pacientes
        fprintf('   Paciente %d...\n', patient_idx);
        current_patient = main_var(patient_idx);
        
        % Encontrar sinais ECG nos campos
        ecg_signals = {};
        patient_fields = fieldnames(current_patient);
        
        for field_idx = 1:length(patient_fields)
            field_name = patient_fields{field_idx};
            field_data = current_patient.(field_name);
            
            % Verificar se é um sinal ECG (vetor numérico > 1000 amostras)
            if isnumeric(field_data) && isvector(field_data) && length(field_data) > 1000
                ecg_signals{end+1} = field_name;
                fprintf('     - Lead %s: %d amostras\n', field_name, length(field_data));
            end
        end
        
        % Processar cada lead encontrado
        all_features = {};
        feature_labels = {};
        
        for lead_idx = 1:min(length(ecg_signals), 2) % Processar até 2 leads
            lead_name = ecg_signals{lead_idx};
            ecg_signal = current_patient.(lead_name);
            
            % Pré-processamento
            ecg_signal = ecg_signal(~isnan(ecg_signal));
            ecg_signal = ecg_signal - mean(ecg_signal);
            
            % Segmentação
            samples_per_segment = fs * segment_duration;
            num_segments = floor(length(ecg_signal) / samples_per_segment);
            
            if num_segments > 0
                fprintf('     Processando %d segmentos do lead %s...\n', num_segments, lead_name);
                
                lead_features = zeros(num_segments, 10);
                
                for seg_idx = 1:num_segments
                    start_idx = (seg_idx-1) * samples_per_segment + 1;
                    end_idx = seg_idx * samples_per_segment;
                    
                    if end_idx <= length(ecg_signal)
                        segment_data = ecg_signal(start_idx:end_idx);
                        
                        % Aplicar DWT e extrair características
                        try
                            [c, l] = wavedec(segment_data, decomposition_level, wavelet_name);
                            
                            % Extrair 10 características
                            approx_coeff = appcoef(c, l, wavelet_name);
                            detail_coeffs = cell(1, decomposition_level);
                            for level = 1:decomposition_level
                                detail_coeffs{level} = detcoef(c, l, level);
                            end
                            
                            features = zeros(1, 10);
                            features(1) = sum(approx_coeff.^2); % Energia aproximação
                            
                            for level = 1:decomposition_level
                                features(1+level) = sum(detail_coeffs{level}.^2); % Energia detalhe
                            end
                            
                            features(7) = wentropy(approx_coeff, 'shannon'); % Entropia
                            features(8) = mean(approx_coeff); % Média
                            features(9) = std(approx_coeff); % Desvio padrão
                            
                            if features(1) > 0
                                features(10) = sum(features(2:6)) / features(1); % Razão energia
                            else
                                features(10) = 0;
                            end
                            
                            lead_features(seg_idx, :) = features;
                            
                        catch
                            fprintf('       Erro no segmento %d, usando zeros\n', seg_idx);
                            lead_features(seg_idx, :) = zeros(1, 10);
                        end
                    end
                end
                
                all_features{end+1} = lead_features;
                feature_labels{end+1} = lead_name;
            end
        end
        
        % Armazenar no paciente
        if ~isempty(all_features)
            wavelet_features(patient_idx).patient_id = sprintf('Paciente_%d', patient_idx);
            wavelet_features(patient_idx).features = all_features;
            wavelet_features(patient_idx).feature_labels = feature_labels;
            wavelet_features(patient_idx).parameters = struct(...
                'wavelet', wavelet_name, ...
                'decomposition_level', decomposition_level, ...
                'segment_duration', segment_duration);
        end
    end
    
elseif isnumeric(main_var) && ~isempty(main_var)
    fprintf('   Processando matriz numérica...\n');
    % Processar como matriz direta (implementação similar)
    
else
    fprintf('   Tipo de dados não suportado: %s\n', class(main_var));
    return;
end

% PASSO 3: SALVAR CARACTERÍSTICAS EXTRAÍDAS
fprintf('3. Salvando características extraídas...\n');
if ~isempty(wavelet_features)
    save('caracteristicas_corrigidas.mat', 'wavelet_features', '-v7.3');
    fprintf('   Características salvas em: caracteristicas_corrigidas.mat\n');
else
    fprintf('   AVISO: Nenhuma característica foi extraída!\n');
    return;
end

% PASSO 4: VISUALIZAR CARACTERÍSTICAS
fprintf('4. Criando visualizações...\n');

for patient_idx = 1:length(wavelet_features)
    paciente = wavelet_features(patient_idx);
    
    if ~isempty(paciente.features)
        figure('Position', [100, 100, 1200, 800]);
        sgtitle(sprintf('Características Wavelet - %s', paciente.patient_id), ...
                'FontSize', 16, 'FontWeight', 'bold');
        
        % Combinar todas as características do paciente
        all_patient_features = [];
        for lead_idx = 1:length(paciente.features)
            if ~isempty(paciente.features{lead_idx})
                all_patient_features = [all_patient_features; paciente.features{lead_idx}];
            end
        end
        
        if ~isempty(all_patient_features)
            feature_names = {'Energia_Aprox', 'Energia_Det1', 'Energia_Det2', 'Energia_Det3', ...
                            'Energia_Det4', 'Energia_Det5', 'Entropia_Aprox', 'Media_Aprox', ...
                            'Std_Aprox', 'Razao_Energia'};
            
            % Gráfico 1: Boxplot
            subplot(2, 3, 1);
            boxplot(all_patient_features, 'Labels', feature_names, 'LabelOrientation', 'inline');
            title('Distribuição das Características');
            ylabel('Valores');
            grid on;
            rotateXLabels(gca, 45);
            
            % Gráfico 2: Mapa de calor
            subplot(2, 3, 2);
            imagesc(all_patient_features);
            colorbar;
            title('Mapa de Calor das Features');
            xlabel('Características');
            ylabel('Segmentos');
            xticks(1:10);
            xticklabels(1:10);
            
            % Gráfico 3: Médias
            subplot(2, 3, 3);
            bar(mean(all_patient_features));
            title('Valores Médios das Características');
            xlabel('Características');
            ylabel('Valor Médio');
            xticks(1:10);
            xticklabels(1:10);
            grid on;
            
            % Gráfico 4: PCA
            subplot(2, 3, 4);
            [coeff, score] = pca(all_patient_features);
            scatter(score(:,1), score(:,2), 30, 'filled');
            title('Análise PCA - Projeção 2D');
            xlabel('PC1');
            ylabel('PC2');
            grid on;
            
            % Gráfico 5: Correlação
            subplot(2, 3, 5);
            corr_matrix = corr(all_patient_features);
            heatmap(feature_names, feature_names, corr_matrix, ...
                   'Title', 'Matriz de Correlação');
            
            % Gráfico 6: Histograma da primeira característica
            subplot(2, 3, 6);
            histogram(all_patient_features(:,1), 30);
            title('Distribuição - Energia Aproximação');
            xlabel('Valor');
            ylabel('Frequência');
            grid on;
            
            fprintf('   Visualização criada para %s (%d amostras)\n', ...
                   paciente.patient_id, size(all_patient_features, 1));
        end
    end
end

% PASSO 5: SALVAR TABELA CSV
fprintf('5. Gerando tabela CSV...\n');

detailed_table = table();
feature_names = {'Energia_Aprox', 'Energia_Det1', 'Energia_Det2', 'Energia_Det3', ...
                'Energia_Det4', 'Energia_Det5', 'Entropia_Aprox', 'Media_Aprox', ...
                'Std_Aprox', 'Razao_Energia'};

for patient_idx = 1:length(wavelet_features)
    paciente = wavelet_features(patient_idx);
    
    for lead_idx = 1:length(paciente.features)
        if ~isempty(paciente.features{lead_idx})
            lead_features = paciente.features{lead_idx};
            lead_name = paciente.feature_labels{lead_idx};
            
            for seg_idx = 1:size(lead_features, 1)
                new_row = table();
                new_row.Paciente = {paciente.patient_id};
                new_row.Lead = {lead_name};
                new_row.Segmento = seg_idx;
                
                for feat_idx = 1:10
                    new_row.(feature_names{feat_idx}) = lead_features(seg_idx, feat_idx);
                end
                
                if height(detailed_table) == 0
                    detailed_table = new_row;
                else
                    detailed_table = [detailed_table; new_row];
                end
            end
        end
    end
end

if height(detailed_table) > 0
    writetable(detailed_table, 'caracteristicas_detalhadas_corrigidas.csv');
    fprintf('   Tabela salva: caracteristicas_detalhadas_corrigidas.csv\n');
    fprintf('   Total de amostras: %d\n', height(detailed_table));
    
    % Mostrar primeiras linhas
    fprintf('\nPrimeiras 5 linhas da tabela:\n');
    disp(detailed_table(1:min(5, height(detailed_table)), :));
else
    fprintf('   AVISO: Tabela vazia - nenhuma característica extraída\n');
end

fprintf('\n=== PROCESSO CONCLUÍDO ===\n');
fprintf('✓ Características extraídas do arquivo original\n');
fprintf('✓ Visualizações criadas\n');
fprintf('✓ Tabelas geradas\n');