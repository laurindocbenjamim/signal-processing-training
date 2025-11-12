function [signal] = signal_normalization(S, signal, j)
    for i=1:tWindows:length(S{j})-tWindows
      if i==1
        signal = S{j}(i:i+tWindows-1);
      else
        signal=S{j}(i+1:i+tWindows);
      end
    end   
end

