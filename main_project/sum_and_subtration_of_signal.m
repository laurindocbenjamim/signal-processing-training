%% LIMPEZA E CONFIGURAÇÃO INICIAL
clear all; close all; clc;

%% DEFINIÇÃO DO SINAL CONTÍNUO x(t)
t = -2:0.01:6;
x_t = t .* exp(-0.5*t) .* (t >= 0);

%% FIGURAS INDIVIDUAIS PARA SINAIS CONTÍNUOS

% Figura 1: Sinal Original x(t)
figure(1);
plot(t, x_t, 'b-', 'LineWidth', 2);
title('x(t) = t\cdot e^{-0.5t} para t\geq0');
xlabel('t (s)'); ylabel('Amplitude'); grid on;
xlim([-2 6]); ylim([-0.5 1.5]);  % Escalas fixas para comparação

% Figura 2: Comparação x(t) e x(t+2)
figure(2);
plot(t, x_t, 'b--', 'LineWidth', 1.5); hold on;
plot(t, t.*exp(-0.5*(t+2)).*((t+2)>=0), 'r-', 'LineWidth', 2);
title('x(t) (tracejado) vs x(t+2) (sólido) - Deslocamento Esquerda');
xlabel('t (s)'); ylabel('Amplitude'); grid on;
legend('x(t)', 'x(t+2)', 'Location', 'best');
xlim([-2 6]); ylim([-0.5 1.5]);

% Figura 3: -x(t+2)
figure(3);
plot(t, -t.*exp(-0.5*(t+2)).*((t+2)>=0), 'g-', 'LineWidth', 2);
title('-x(t+2) - Inversão de Amplitude');
xlabel('t (s)'); ylabel('Amplitude'); grid on;
xlim([-2 6]); ylim([-1.5 0.5]);

% Figura 4: -x(-t+2)
figure(4);
plot(t, -(-t+2).*exp(-0.5*(-t+2)).*((-t+2)>=0), 'm-', 'LineWidth', 2);
title('-x(-t+2) - Reversão Temporal + Deslocamento + Inversão');
xlabel('t (s)'); ylabel('Amplitude'); grid on;
xlim([-2 6]); ylim([-1.5 0.5]);

%% DEFINIÇÃO DO SINAL DISCRETO x[n]
n = -4:10;
x_n = n .* (0.8).^n .* (n >= 0);

%% FIGURAS INDIVIDUAIS PARA SINAIS DISCRETOS

% Figura 5: Sinal Discreto Original x[n]
figure(5);
stem(n, x_n, 'b-', 'LineWidth', 2, 'Marker', 'o');
title('x[n] = n\cdot 0.8^n para n\geq0');
xlabel('n'); ylabel('Amplitude'); grid on;
xlim([-4 10]); ylim([-0.5 2.5]);

% Figura 6: Comparação x[n] e x[n+2]
figure(6);
stem(n, x_n, 'b--', 'LineWidth', 1); hold on;
shifted_n = n + 2;
x_n2 = shifted_n .* (0.8).^shifted_n .* (shifted_n >= 0);
stem(n, x_n2, 'r-', 'LineWidth', 2, 'Marker', 's');
title('x[n] vs x[n+2] - Deslocamento Esquerda');
xlabel('n'); ylabel('Amplitude'); grid on;
legend('x[n]', 'x[n+2]', 'Location', 'best');
xlim([-4 10]); ylim([-0.5 2.5]);

% Figura 7: -x[n+2]
figure(7);
stem(n, -x_n2, 'g-', 'LineWidth', 2, 'Marker', '^');
title('-x[n+2] - Inversão de Amplitude');
xlabel('n'); ylabel('Amplitude'); grid on;
xlim([-4 10]); ylim([-2.5 0.5]);

% Figura 8: -x[-n+2]
figure(8);
reversed_n = -n + 2;
x_rev = reversed_n .* (0.8).^reversed_n .* (reversed_n >= 0);
stem(n, -x_rev, 'm-', 'LineWidth', 2, 'Marker', 'd');
title('-x[-n+2] - Reversão Temporal + Deslocamento + Inversão');
xlabel('n'); ylabel('Amplitude'); grid on;
xlim([-4 10]); ylim([-2.5 0.5]);

%% EXPLICAÇÃO DAS ESCALAS
fprintf('\n=== DICAS PARA VISUALIZAR ESCALAS ===\n');
fprintf('1. Use ZOOM: Clique no ícone de lupa na janela da figura\n');
fprintf('2. Use PAN: Clique no ícone de mão para mover o gráfico\n');
fprintf('3. Data Cursor: Clique no ícone de "+" para ver valores exatos\n');
fprintf('4. Os limites estão fixos com xlim/ylim para melhor comparação\n');