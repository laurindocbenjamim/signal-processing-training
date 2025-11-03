x=[1 8 2 8 3 8 4 8];
n=0:7;
[y ny]=dnsample(x,n,2)

figure, stem(ny, y);