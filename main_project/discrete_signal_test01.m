% %% PASSO 1: Definir o sinal original x(t) ou x[n]
% t = 0:0.01:2*pi;          % Vetor tempo para sinal contínuo
% n = 0:20;                 % Vetor tempo para sinal discreto
% 
% % Sinal original - exemplo com senoidal
% x_cont = sin(t);          % Sinal contínuo
% x_disc = sin(2*pi*n/10);  % Sinal discreto
% 
% %% PASSO 2: Definir fatores de escala A
% A1 = 0.5;   % Redução de amplitude
% A2 = 1;     % Sem alteração (original)
% A3 = 2;     % Amplificação
% 
% %% PASSO 3: Aplicar amplitude scaling
% % Sinal contínuo
% y1_cont = A1 * x_cont;
% y2_cont = A2 * x_cont;
% y3_cont = A3 * x_cont;
% 
% % Sinal discreto
% y1_disc = A1 * x_disc;
% y2_disc = A2 * x_disc;
% y3_disc = A3 * x_disc;
% 
% %% PASSO 4: Plotar os gráficos (como na imagem)
% figure('Position', [100, 100, 1200, 800]);
% 
% % SUBPLOT 1: Sinal Contínuo
% subplot(2,3,1);
% plot(t, x_cont, 'b', 'LineWidth', 2);
% title('Sinal Original x(t)');
% xlabel('Tempo (t)');
% ylabel('Amplitude');
% grid on;
% ylim([-2.5, 2.5]);
% 
% subplot(2,3,2);
% plot(t, y1_cont, 'r', 'LineWidth', 2);
% title(['y(t) = ', num2str(A1), ' \cdot x(t)']);
% xlabel('Tempo (t)');
% ylabel('Amplitude');
% grid on;
% ylim([-2.5, 2.5]);
% 
% subplot(2,3,3);
% plot(t, y3_cont, 'g', 'LineWidth', 2);
% title(['y(t) = ', num2str(A3), ' \cdot x(t)']);
% xlabel('Tempo (t)');
% ylabel('Amplitude');
% grid on;
% ylim([-2.5, 2.5]);
% 
% % SUBPLOT 2: Sinal Discreto
% subplot(2,3,4);
% stem(n, x_disc, 'b', 'LineWidth', 2, 'Marker', 'o');
% title('Sinal Original x[n]');
% xlabel('Amostras (n)');
% ylabel('Amplitude');
% grid on;
% ylim([-2.5, 2.5]);
% 
% subplot(2,3,5);
% stem(n, y1_disc, 'r', 'LineWidth', 2, 'Marker', 'o');
% title(['y[n] = ', num2str(A1), ' \cdot x[n]']);
% xlabel('Amostras (n)');
% ylabel('Amplitude');
% grid on;
% ylim([-2.5, 2.5]);
% 
% subplot(2,3,6);
% stem(n, y3_disc, 'g', 'LineWidth', 2, 'Marker', 'o');
% title(['y[n] = ', num2str(A3), ' \cdot x[n]']);
% xlabel('Amostras (n)');
% ylabel('Amplitude');
% grid on;
% ylim([-2.5, 2.5]);
% 
% %% PASSO 5: Adicionar título geral
% sgtitle('Amplitude Scaling: y(t) = A⋅x(t)  ou  y[n] = A⋅x[n]', 'FontSize', 14);
%%
