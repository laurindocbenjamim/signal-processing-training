function [bins,np]=corrint(y,de,tau,nbins,nt,pretty)

% function [eps,cn]=corrint(y,de,tau,nbins,nt);
%
% compute correlation integral, nothing more.
%
%
%Michael Small
%3/3/2005

nout=nargout;

if nargin<6,
    pretty=[];
end;
if nargin<5,
    nt=0;
end;
if nargin<4,
    nbins=200;
end;
if nargin<3,
    tau=1;
end;
if nargin<2,
    de=2;
end;

if isempty(nt), nt=0; end;
if isempty(nbins), nbins=200; end;

nt=max(nt,1); %nt>=1
nde=length(de);

%parameters
maxn=2000; %maximum number of points to use
hcmin=0.25; %absolute minimum bandwidth
hcmax=3;   %absolute maximum bandwidth
if isempty(pretty),
    pretty=1;  %pictures?
end;

%data
y=y(:);
n=length(y);

%rescale to mean=0 & std=1
y=y-mean(y);
y=y./std(y);

%init
m=[];
d=[];
k=[];
s=[];
b=[];
gkim=[];
ssm=[];

%get bins : distributed logarithmically
binl=log(min(diff(unique(y))))-1;   %smallest diff 
%if isempty(binl),binl=eps;end;  %just in-case
binh=log(max(de)*(max(y)-min(y)))+1;%seems to work
%if isnan(binh),binh=log(max(de)*max(y))+1;end; %just in-case 
binstep=(binh-binl)./(nbins-1);
bins=binl:binstep:binh;
bins=exp(bins);

%disp
disp(['Correlation Integral (n=',int2str(n),'; tau=',int2str(tau),'; nbins=',int2str(nbins),'; nt=',int2str(nt),')']);
disp(['hcmin=',num2str(hcmin),' & hcmax=',num2str(hcmax)]);
disp('Computing histogram');

%estimate distribution of interpoint distances 
if n>2*maxn, %why sample with replacement when you could without?
  disp(['Using ',int2str(maxn),' reference points'])
  %distribution of interpoint distances
  %compute distrib. from maxn ref. points
  np=interpoint(y,de,tau,bins(1:(end-1)),maxn^2,nt);  
  %number of interpoint distances      
  ntot=maxn^2;                    
else,
  disp('Using all points');
  %distribution of interpoint distances
  %compute distrib. using all points
  np=interpoint(y,de,tau,bins(1:(end-1)),0,nt);
  %number of interpoint distances      
  ntot=n-(de(end)-1)*tau;
  if nt>0,
    ntot=(ntot-2*nt+2)*(ntot-2*nt+1)+2*(nt-1)*(ntot-nt+1)-(nt-1)*nt;
  else
    ntot=ntot^2;
  end;
end;

if pretty,
    figure(gcf);
    subplot(211);
    loglog(bins,np);
    xlabel('\epsilon');ylabel('C_N(\epsilon)');
    subplot(212);
    plot(log(bins(2:end)),diff(log(np))./diff(log(bins')));
    xlabel('log(\epsilon)');ylabel('\Delta(log(C_N(\epsilon)))/\Delta(log(\epsilon))');
end;

