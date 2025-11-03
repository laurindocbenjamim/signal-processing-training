% Exemplo de Convolução no MATLAB
% Os vetores x1 e x2 já foram definidos no item 1.
y_conv = conv(x1, x2);

% O vetor de tempo para y_conv deve ser recalculado:
n_inicio_x1 = n(find(x1, 1, 'first')); % Onde x1[-3] começa
n_inicio_x2 = n(find(x2, 1, 'first')); % Onde x2[-3] começa

n_conv_inicio = n_inicio_x1 + n_inicio_x2; % -3 + (-3) = -6
n_conv_fim = n_conv_inicio + length(y_conv) - 1; % O número de amostras
n_conv = n_conv_inicio : n_conv_fim;

% Plotagem do resultado da convolução
figure;
stem(n_conv, y_conv, 'filled');
title('Convolução y[n] = x_1[n] * x_2[n]');
xlabel('n');
ylabel('y[n]');
grid on;