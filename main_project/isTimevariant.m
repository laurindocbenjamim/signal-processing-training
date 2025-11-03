function isTimevariant(y,x,u,n)
[y1,ny1] = sigshift(y,n,1); [x1,nx1] = sigshift(x,n,1);
[y2,ny2] = sigmult(x1,nx1,u,n); [diff,ndiff] = sigadd(y1,ny1,-y2,ny2);
diff = sum(abs(diff));
if (diff < 1e-5)
disp('*** System-1 is Time-Invariant ***');
else
disp('*** System-1 is Time-Varying ***');
end
