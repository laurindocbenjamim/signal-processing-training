%% FUNÇÃO MODERNA PARA TRANSFORMAÇÕES
function [y_transformed, n_transformed] = transform_signal(x, n, transform_type, shift)
    % transform_type: 'reverse', 'shift', 'scale', 'reverse_shift'
    % shift: valor do deslocamento (opcional)
    
    switch transform_type
        case 'reverse'
            % Time reversal: x[-n]
            y_transformed = flip(x);
            n_transformed = -flip(n);
            
        case 'shift'
            % Time shifting: x[n - shift]
            y_transformed = zeros(size(n));
            for i = 1:length(n)
                source_val = n(i) - shift;
                idx = find(n == source_val, 1);
                if ~isempty(idx)
                    y_transformed(i) = x(idx);
                end
            end
            n_transformed = n;
            
        case 'scale'
            % Time scaling: x[shift * n]
            y_transformed = zeros(size(n));
            for i = 1:length(n)
                source_val = shift * n(i);
                idx = find(n == source_val, 1);
                if ~isempty(idx)
                    y_transformed(i) = x(idx);
                end
            end
            n_transformed = n;
            
        case 'reverse_shift'
            % Time reversal + shifting: x[-n + shift]
            y_transformed = flip(x);
            n_transformed = -flip(n) + shift;
            
        otherwise
            error('Tipo de transformação não reconhecido');
    end
end