%% Visualize some parameters
 %% 3. VISUALIZAÇÃO E ANÁLISE COMPARATIVA

 function [] = visualization_and_analysis(BASE_DIR, Feature_Master_Table)
    
    disp(' ');
    disp('=== ANÁLISE GRÁFICA E TABULAR ===');
    
    % --- A. Visualização da Tabela Resumo (SDNN, BPM e Fractais) ---
    % Seleciona apenas as colunas principais para fácil visualização
    Feature_Display_Table = Feature_Master_Table(:, {'Patient_ID', 'Signal_Name', 'BPM_avg', 'SDNN', 'Hurst_Exp', 'Higuchi_FD', 'Katz_FD'});
    disp('Tabela Resumo das Características Chave:');
    disp(Feature_Display_Table);
    
    % --- B. Comparação Gráfica dos Sinais Filtrados ---
    
    % 1. Encontra um sinal de exemplo para cada paciente para comparação
    Patient_List = unique(Feature_Master_Table.Patient_ID);
    Num_Patients = length(Patient_List);
    
    figure('Name', 'Comparação de ECG Filtrado por Paciente', 'Position', [100, 100, 1200, 600]);
    sgtitle('Comparação de um Sinal Filtrado entre Pacientes (Primeiros 5s)');
    
    for p = 1:Num_Patients
        current_patient = Patient_List{p};
        
        % Encontra o primeiro sinal válido deste paciente na tabela
        idx = find(strcmp(Feature_Master_Table.Patient_ID, current_patient), 1, 'first');
        
        if ~isempty(idx)
            % Re-processa o sinal para obter os dados filtrados (necessário pois os dados brutos não foram salvos no loop)
            % IDEALMENTE: Você salvaria o ECG_filtered_final em uma Cell Array no loop.
            
            % ATENÇÃO: Seus parâmetros de tempo (t, num_samples, Fs)
            % devem ser reconstruídos aqui ou salvos no loop.
            
            % Para simplificar, vamos assumir que o primeiro sinal (s0010_re) é sempre o melhor exemplo 
            % e que você re-executou o processamento do loop para o s0010_re.
            
            % *** CÓDIGO DE REPROCESAMENTO BÁSICO (Para fins de plotagem) ***
            Signal_Name = Feature_Master_Table.Signal_Name{idx};
            
            % CONSTRUÇÃO DINÂMICA DOS CAMINHOS
            Base_Path = fullfile(BASE_DIR, current_patient, Signal_Name);
            data_file_dat = [Base_Path, '.dat'];
            
            % Tenta carregar os dados brutos (Novamente, a Fs e Ganho são assumidos)
            try
                fid = fopen(data_file_dat, 'r');
                data_int = fread(fid, [12, num_samples], 'int16'); 
                fclose(fid);
                ECG_raw = data_int(lead_index, :);
                ECG_mV = (ECG_raw - Baseline) / Gain; 
                
                % Filtragem
                [ECG_filtered_plot] = remove_artefacts_2(ECG_mV, Fs);
                
                % Plotagem
                subplot(Num_Patients, 1, p);
                
                t_plot = (0:length(ECG_filtered_plot)-1)/Fs;
                plot(t_plot, ECG_filtered_plot, 'LineWidth', 1);
                
                title(['Paciente: ', current_patient, ' - Sinal: ', Signal_Name]);
                xlabel('Tempo (s)'); ylabel('Amplitude (mV)');
                xlim([0 5]); % Foco nos primeiros 5 segundos
                grid on;
            catch
                warning(['Não foi possível carregar/plotar o sinal ', Signal_Name, ' do paciente ', current_patient]);
            end
        end
    end
    hold off;
end % End of the function