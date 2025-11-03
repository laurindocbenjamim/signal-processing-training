
y=[1 2 1 2 1];
n=0:1:4;

%% sig1 = -y[-n-2]
[y1, n1]=sigfold(y, n);

figure, stem(n1, y1);
xlabel('X-axis');
ylabel('Y-ax is');
title('Plot of Y vs X');
hold on;

%%
%[y8, n8]=sigshift(y7, n7, 2);
%y8=y8.*-1;