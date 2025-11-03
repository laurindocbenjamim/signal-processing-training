% creating th function u[n-2]

%[x,n]=stepseq(n0,n1,n2);
%Starts lon range from 0 to 50
% [x,n]=stepseq(2,0,50);
% 
% %Plot it
% stem(n, x);

% Ilustrate a wave tnhat begin on -3 u[n-3]
% [x,n]=stepseq(-3,-3,3);
% x=x.*n;
% stem(n, x);

% Illustrate a wave that begins on -2 u[n-2]
% [x,n] = stepseq(-3, -4, 3);
% x =x.*n;
% stem(n,x);



% 
% [x,n] = impseq(-2,-2, 3);
% x=x.*2;
% figure, stem(n, x);

[x,n] = impseq(-2,-2, 3);
x=x.*2;
figure, stem(n, n);

[x2,n2] = impseq(-3,-2, 3);
x2=x2.*-1;
%stem(n2,x2)


[x3,n3] = sigadd(x, n, x2, n2);
figure, stem(x3, n3)
