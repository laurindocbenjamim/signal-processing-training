% Inicializa a tabela mestre (FORA do loop)
Feature_Master_Table = table(); 

% Diretório onde os resultados serão salvos:
OUTPUT_DIR = 'Extracted_Features';
if ~exist(OUTPUT_DIR, 'dir')
    mkdir(OUTPUT_DIR);
end

% INÍCIO DO LOOP: Para cada arquivo...
for i = 1:length(lista_de_arquivos) 
    % ... (Seu código de leitura, filtragem e extração de features) ...
    
    % Nome do Arquivo Atual
    File_Name = lista_de_arquivos{i}; 

    % Geração da Feature_Table para este arquivo (dentro do loop)
    Feature_Table_Current = table(File_Name, En_Total, Hurst_Exp, Higuchi_FD, Katz_FD, En_D5, ...
                                  'VariableNames', {'File_Name', 'En_Total', 'Hurst_Exp', 'Higuchi_FD', 'Katz_FD', 'En_D5'});
    
    % 2. Acumular os Resultados (CONCATENAR)
    Feature_Master_Table = [Feature_Master_Table; Feature_Table_Current]; 
    % O ';' garante que você está adicionando uma nova linha à tabela mestre
end
% FIM DO LOOP


%% === VISUALIZAÇÃO ===
disp(' ');
disp('=== RELATÓRIO MESTRE DE CARACTERÍSTICAS EXTRAÍDAS ===');
disp(Feature_Master_Table);

% === SALVAMENTO FINAL ===
% Salva a tabela completa em um arquivo CSV (Comma Separated Values), 
% que pode ser facilmente aberto em Excel, Python, R, ou qualquer software de ML.
Output_Filename = fullfile(OUTPUT_DIR, 'ECG_Features_Summary.csv');

writetable(Feature_Master_Table, Output_Filename);

disp(' ');
disp(['✅ Tabela Mestre salva com sucesso em: ', Output_Filename]);