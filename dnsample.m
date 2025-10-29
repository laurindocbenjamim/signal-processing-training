
function [y ny]=dnsample(x,n,M)
%x is a sequence over indices specified by vector n,M is the downsampling factor.

param=n/M;
%generates the parameter vector.This vector will decide which input samples will be present in the output.

samp=fix(param)==param;
%only those output vectors corresponding to indices where samp==1 will be present in the output.

y=x(samp==1);
%generates the output sequence

ny=n(samp==1)/M;
%generates the indices of the output sequence

end