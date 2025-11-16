

%%
function header_info = parse_header(header_file)
% Reads WFDB-style .hea file manually (no WFDB toolbox)

    fid = fopen(header_file, 'r');
    if fid < 0
        error("Cannot open header file: %s", header_file);
    end

    header_info = struct();
    line_idx = 0;

    while ~feof(fid)
        line = fgetl(fid);
        line_idx = line_idx + 1;

        % Store all lines for debugging
        header_info.lines{line_idx} = line;
        
        % Try to parse known fields
        if contains(line, 'gain')
            tmp = regexp(line, 'gain\s+(\d+)', 'tokens');
            if ~isempty(tmp)
                header_info.gain = str2double(tmp{1}{1});
            end
        end

        if contains(line, 'baseline')
            tmp = regexp(line, 'baseline\s+(-?\d+)', 'tokens');
            if ~isempty(tmp)
                header_info.baseline = str2double(tmp{1}{1});
            end
        end

        if contains(line, 'Hz')
            tmp = regexp(line, '(\d+)\s*Hz', 'tokens');
            if ~isempty(tmp)
                header_info.fs = str2double(tmp{1}{1});
            end
        end
    end

    fclose(fid);
end


%%
function data_int = read_dat_file(dat_file, num_samples)
% Read .dat raw ECG file (int16 values)

    fid = fopen(dat_file, 'r');

    if fid < 0
        error("Cannot open .dat file: %s", dat_file);
    end

    % Read as int16, Unknown # of leads → MATLAB infers first dimension
    data_int = fread(fid, [inf, num_samples], 'int16')';

    fclose(fid);
end

%%
function [ECG_mV, t] = convert_raw_to_mV(data_int, lead_index, Gain, Baseline, Fs)

    ECG_raw = data_int(:, lead_index);

    % Convert ADC → millivolts
    ECG_mV = (ECG_raw - Baseline) / Gain;

    t = (0:length(ECG_mV)-1) / Fs;
end


%%
function visualize_ecg_leads(Signal_Name, header_info, data_int, Fs)
% Plot each lead in separate subplots

    num_leads = size(data_int, 2);
    t = (0:size(data_int,1)-1) / Fs;

    figure('Name', sprintf('ECG %s', Signal_Name), 'Color', 'w');

    for lead = 1:num_leads
        subplot(num_leads, 1, lead);
        plot(t, data_int(:, lead));
        grid on;
        title(sprintf("%s - Lead %d", Signal_Name, lead));
        xlabel("Time (s)");
        ylabel("ADC Counts");
    end

    sgtitle(sprintf("ECG Signal: %s (raw data)", Signal_Name), 'FontSize', 14);
end
