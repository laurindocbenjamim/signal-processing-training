function islinear(y,y1,y2)
diff = sum(abs(y - (y1 + y2)));

if (diff < 1e-5)
disp(' *** System is Linear *** ');
else
disp(' *** System is NonLinear *** ');
end
