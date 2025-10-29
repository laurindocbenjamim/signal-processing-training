%*************************************************************************%

function [y ny]=upsampler(x,n,L)
%x is a sequence over indices specified by vector n,L is the upsampling factor.

ny=L*min(n):L*max(n);
%generates a vector over the expected indices of output

param=ny/L;
%generates a parameter vector,which decides where input samples will be appended in a longer output.

samp=fix(param)==param;
%The input samples will appear in output only where the corresponding entry in samp vector is 1.

y=zeros(1,length(ny));
%generates the zero output vector

y(samp==1)=x;
%appends input samples in the outut vector

end

%*************************************************************************%