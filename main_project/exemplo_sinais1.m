% SCRIPT DE EXEMPLO: exemplo_sinais.m
% -------------------------------------------------------------------------
% Demonstra a geração, transformação e plotagem dos sinais usando a classe
% ManipuladorSinais.m.

% 1. Instanciar a classe
sig = ManipuladorSinais1();
t = sig.t;
n = sig.n;

fprintf('Iniciando a plotagem dos sinais. %d gráficos serão gerados.\n', 17);

% =================================================================
% GRUPO 1: SINAIS CONTÍNUOS BASEADOS em x(t) = cos(pi*t)
% =================================================================
disp('--- Grupo 1: Sinais Contínuos ---');
[x_t, eq_x_t] = sig.sinalSenoidalCT();

sig.plotaSinal(t, x_t, eq_x_t, 'CT'); % x(t) original

% x(-t) (Reflexão Temporal)
x_menos_t = cos(pi * (-t));
eq_x_menos_t = 'x(-t)';
sig.plotaSinal(t, x_menos_t, eq_x_menos_t, 'CT');

% 2x(t) (Escalamento de Amplitude)
dois_x_t = 2 * x_t;
eq_dois_x_t = '2x(t)';
sig.plotaSinal(t, dois_x_t, eq_dois_x_t, 'CT');


% =================================================================
% GRUPO 2: SINAIS DISCRETOS BASEADOS em y[n] = (1/2)^n * u[n]
% =================================================================
disp('--- Grupo 2: Sinais Discretos (y[n]) ---');
[y_n, eq_y_n] = sig.sinalDiscretoBase();
u_n = (n >= 0); % u[n]

sig.plotaSinal(n, y_n, eq_y_n, 'DT'); % y[n] original

% y[n+2] (Avanço de tempo em 2 unidades)
y_n_mais_dois = sig.transformaDT(y_n, n + 2);
eq_y_n_mais_dois = 'y[n+2]';
sig.plotaSinal(n, y_n_mais_dois, eq_y_n_mais_dois, 'DT');

% 2y[-n+2] (Reversão, Avanço e Escalamento)
dois_y_menos_n_mais_dois = 2 * sig.transformaDT(y_n, -n + 2);
eq_y_transformado1 = '2y[-n+2]';
sig.plotaSinal(n, dois_y_menos_n_mais_dois, eq_y_transformado1, 'DT');

% 2y[2n-2] (Compressão/Decimação, Atraso e Escalamento)
dois_y_2n_menos_dois = 2 * sig.transformaDT(y_n, 2*n - 2);
eq_y_transformado2 = '2y[2n-2]';
sig.plotaSinal(n, dois_y_2n_menos_dois, eq_y_transformado2, 'DT');

% -y[2n+2] (Compressão/Decimação, Avanço e Reflexão de Amplitude)
menos_y_2n_mais_dois = -1 * sig.transformaDT(y_n, 2*n + 2);
eq_y_transformado3 = '-y[2n+2]';
sig.plotaSinal(n, menos_y_2n_mais_dois, eq_y_transformado3, 'DT');

% -y[2n+2]*2y[n]*2y[n-2] (Multiplicação de Sinais)
y_n_menos_dois = sig.transformaDT(y_n, n - 2);
sinal_multiplicado = menos_y_2n_mais_dois .* (2*y_n) .* (2*y_n_menos_dois);
eq_y_multiplicado = '-y[2n+2] \cdot 2y[n] \cdot 2y[n-2]';
sig.plotaSinal(n, sinal_multiplicado, eq_y_multiplicado, 'DT');

% y[2n+2]+2y[n]+2y[n-2] (Soma de Sinais)
y_2n_mais_dois_puro = sig.transformaDT(y_n, 2*n + 2);
sinal_somado = y_2n_mais_dois_puro + (2*y_n) + (2*y_n_menos_dois);
eq_y_somado = 'y[2n+2] + 2y[n] + 2y[n-2]';
sig.plotaSinal(n, sinal_somado, eq_y_somado, 'DT');


% =================================================================
% GRUPO 3: SINAIS DE DEGRAU DE TEMPO CONTÍNUO (u(t))
% =================================================================
disp('--- Grupo 3: Sinais de Degrau Contínuo ---');
[u_t, eq_u_t] = sig.sinalDegrauCT();

sig.plotaSinal(t, u_t, eq_u_t, 'CT'); % x(t) = u(t)

% x(-t) = u(-t)
u_menos_t = (-t >= 0);
eq_u_menos_t = 'u(-t)';
sig.plotaSinal(t, u_menos_t, eq_u_menos_t, 'CT');

% 2x(t-2) = 2u(t-2) (Atraso e Escalamento)
dois_u_t_menos_dois = 2 * (t-2 >= 0);
eq_dois_u_t_menos_dois = '2u(t-2)';
sig.plotaSinal(t, dois_u_t_menos_dois, eq_dois_u_t_menos_dois, 'CT');

% 2x(t-2) + x(t) + 2x(t-2) (Soma)
sinal_soma_u = dois_u_t_menos_dois + u_t + dois_u_t_menos_dois;
eq_soma_u = '2u(t-2) + u(t) + 2u(t-2)';
sig.plotaSinal(t, sinal_soma_u, eq_soma_u, 'CT');


% =================================================================
% GRUPO 4: SINAIS DE DEGRAU DE TEMPO DISCRETO (u[n])
% =================================================================
disp('--- Grupo 4: Sinais de Degrau Discreto ---');
[u_n_dt, eq_u_n_dt] = sig.sinalDegrauDT();

sig.plotaSinal(n, u_n_dt, eq_u_n_dt, 'DT'); % u[n] original

% u[-n] (Reflexão)
u_menos_n = (-n >= 0);
eq_u_menos_n = 'u[-n]';
sig.plotaSinal(n, u_menos_n, eq_u_menos_n, 'DT');

% 2u[n-2] + 1/2u[n-1] (Atraso e Soma)
u_n_menos_dois_dt = (n-2 >= 0);
u_n_menos_um_dt = (n-1 >= 0);
sinal_soma_u_dt = 2*u_n_menos_dois_dt + (0.5)*u_n_menos_um_dt;
eq_soma_u_dt = '2u[n-2] + \frac{1}{2}u[n-1]';
sig.plotaSinal(n, sinal_soma_u_dt, eq_soma_u_dt, 'DT');


% =================================================================
% GRUPO 5: SINAIS SIMÉTRICOS (Baseados no Sinal Discreto Base y[n])
% =================================================================
disp('--- Grupo 5: Sinais Simétricos (Baseados em y[n]) ---');

% y[-n] (Reversão/Simetria)
y_menos_n_sim = sig.transformaDT(y_n, -n);
eq_y_menos_n = 'y[-n]';
sig.plotaSinal(n, y_menos_n_sim, eq_y_menos_n, 'DT');

% y[-n+2] (Reversão e Avanço de 2)
y_menos_n_mais_dois_sim = sig.transformaDT(y_n, -n + 2);
eq_y_menos_n_mais_dois = 'y[-n+2]';
sig.plotaSinal(n, y_menos_n_mais_dois_sim, eq_y_menos_n_mais_dois, 'DT');

% -2y[-n+2] + 2y[-n+2] (Soma Trivial)
soma_simetrica = -2*y_menos_n_mais_dois_sim + 2*y_menos_n_mais_dois_sim;
eq_soma_simetrica = '-2y[-n+2] + 2y[-n+2]';
sig.plotaSinal(n, soma_simetrica, eq_soma_simetrica, 'DT');