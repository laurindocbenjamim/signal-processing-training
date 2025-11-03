% 2n(u[+3])-([n-4])-8d[n-3]
[x,n]=stepseq(-3,-6,3);
x=x.*2.*n;

% Generate Dirac using Impseq
% [x2,n2]=impseq(3,-3,10);
% x2=x2.*-8;
% 
% [yfinal, nfinal]=sigadd(x,n,x2,n2);
% figure, stem(nfinal, yfinal);

% x2
% [x3,n3]=stepseq(-2,-2,0);
% x3=x3.*-2.*n;
% [x4,n4]=sigfold(x3,n3);
% 
% [yfinal2, nfinal2]=sigadd(x3,n3,x4,n4); 
% %figure, stem(nfinal2, yfinal2);

% %Applying convolution
% [y5,n5]=conv_m(yfinal, nfinal, yfinal2, nfinal2);
% 
% %3/2.x2[n-1].(x2[n+2]+x1[-n-3])
% 
% [x6,n6]==sigshift(yfinal2, nfinal2,1);
% x6=3/2.*x6;%3/2.x2[n-1]
% [x7,n7]=sigshift(yfinal2, nfinal2,-2);%x2[n+2]
% [x8,n8]=sigfold(yfinal, nfinal);
% [x9,n9]=sigshift(x8,n8,3); %x1[-n-3]
% 
% [x10, n10]=sigadd(x7,n7, x9,n9);%(x2[n+2]+
% [x11,n11]=sigmult(x10, n10, x6, n6);
% 
% figure, stem(n11, x11);