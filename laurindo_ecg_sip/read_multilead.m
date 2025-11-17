function [t, X] = read_multilead(patient_path, signal_name, header)

dat_path = fullfile(patient_path, signal_name + ".dat");

fid = fopen(dat_path,'r');
raw = fread(fid, [header.num_leads, header.num_samples],'int16');
fclose(fid);

X = zeros(size(raw));

for L = 1:header.num_leads
    X(L,:) = (raw(L,:) - header.baseline(L)) ./ header.gain(L);
end

t = (0:header.num_samples-1)/header.fs;
