%% sig1 = -y[-n-2]
y=[1 2 1 2 1];
x=0:1:4;
[y7, n7]=sigfold(y, x);

figure, stem(n7, y7);
title('sig1 = -y[-n-2]');
hold on;

%% sig2 = 2y[n+1]

% [y9, n9] = sigshift(y, x, -1);
% figure, stem(n9, y9);
% title('sig2 = 2y[n+1]');
% hold on;