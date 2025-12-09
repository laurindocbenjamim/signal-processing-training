function [patient_cell, diagnosis_ids, id_map] = create_patient_id(patient_cell, column_name, remove_col)
% create_patient_id Converte uma coluna de string para IDs numéricos numa tabela 
% e devolve o mapa de IDs.
%
% Inputs:
%   (os mesmos que anteriormente)
%
% Outputs:
%   patient_cell: A tabela modificada com a nova coluna de IDs.
%   diagnosis_ids: O array numérico com os IDs gerados para a tabela completa.
%   id_map: Uma matriz de células 2xN com {String Original; ID Numerico}.

% Extrair os dados da coluna especificada
diagnoses_str = patient_cell.(column_name); 

% Gerar os IDs numéricos e a lista de diagnósticos únicos
% unique_diagnoses (C) contém a lista ordenada/estável dos nomes únicos.
% diagnosis_ids (ib) contém os IDs que mapeiam de volta para diagnoses_str.
[unique_diagnoses, ~, diagnosis_ids] = unique(diagnoses_str, 'stable'); 

% --- SCRIPT PARA CRIAR O MAPA DE IDS ---

% unique_diagnoses é um array de strings/cell array. 
% Precisamos dos IDs únicos correspondentes, que são simplesmente números de 1 até N.
num_unique = length(unique_diagnoses);
unique_ids = (1:num_unique)'; % Criar um vetor coluna de IDs (1, 2, 3...)

% Criar a matriz de células de mapeamento {String; ID}
% Empilhamos as strings em cima dos IDs numéricos correspondentes
id_map = [unique_diagnoses, num2cell(unique_ids)];

% ---------------------------------------

if remove_col == true
    % Remover a coluna antiga da tabela, usando o nome da coluna passado como input
    patient_cell = removevars(patient_cell, column_name);
    patient_cell.('Diagnosis_ID_Numeric') = diagnosis_ids;
else
    % Adicionar a nova coluna com um nome diferente se a original for mantida
    patient_cell.([column_name '_ID']) = diagnosis_ids;
end

end
