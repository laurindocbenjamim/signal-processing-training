function [x,n] = impseq (n0,n1,n2)
%Gerar x(n)=delta(n-n0); n1<=n <=2

n=[n1:n2]; x = [(n-n0) == 0];