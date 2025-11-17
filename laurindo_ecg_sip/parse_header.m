function header = parse_header(hea_path)
% Parse WFDB .hea header

fid = fopen(hea_path,'r');
line1 = fgetl(fid);
tokens = split(line1);

header.record = tokens{1};
header.num_leads = str2double(tokens{2});
header.fs = str2double(tokens{3});
header.num_samples = str2double(tokens{4});

% Per-lead gains and baselines
gains = [];
bases = [];
for L = 1:header.num_leads
    Lline = fgetl(fid);
    t = split(Lline);
    gains(L) = str2double(t{3});
    bases(L) = str2double(t{4});
end

header.gain = gains;
header.baseline = bases;

fclose(fid);
