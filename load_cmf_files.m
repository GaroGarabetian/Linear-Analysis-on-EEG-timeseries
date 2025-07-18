% INPUT:  folder (default: current working directory)
%
%      - Need to have the Data (.mat) from patients
%      - e.g P01_HF_I036_P120_v3_V2022CL.mat (derives from Patient: 1, PowerIntensity: 120)            
%         -> contains cMF(3 dim matrix), badchannels(1 dim), cMS(3 dim matrix)
%                           
% OUTPUT: 
%         -Extracts the cMF files from all patients
%         -Gathers all bad channels and prints them
%         -Creates Objects Containing Patient ID and Intesity
            
function [unique_badchans,cMF_varname] = load_cmf_files(folder)
    % If no input, use current working directory
    if nargin < 1 || isempty(folder)
        folder = pwd;
    end

    % Recursively load .mat files and extract cMF_i and badchans_i
    files = dir(fullfile(folder, '**', '*.mat')); % Recursively search all .mat files
    all_badchans = [];  % Container for all bad channel indices

    for k = 1:length(files)
        filepath = fullfile(files(k).folder, files(k).name);
        try
            fileData = load(filepath);

            % Extract cMF and badchans variables
            cMF_i = [];
            badchans_i = [];
            fields = fieldnames(fileData);

            for f = 1:numel(fields)
                if contains(fields{f}, 'cMF')
                    cMF_i = fileData.(fields{f});
                elseif contains(fields{f}, 'badchans')
                    badchans_i = fileData.(fields{f});
                end
            end

            % Extract subject and intensity info from filename
            [~, fname, ~] = fileparts(filepath);
            subjectMatch = regexp(fname, 'P(\d{2})_', 'tokens', 'once');
            intensityMatch = regexp(fname, '_P(\d{3})', 'tokens', 'once'); 

            if isempty(subjectMatch) || isempty(intensityMatch)
                warning('Skipping %s: could not parse subject or intensity.', fname);
                continue;
            end

            subjectID = subjectMatch{1};   % e.g., '03'
            intensity = intensityMatch{1}; % e.g., '180'

            % Create variable names
            cMF_varname = sprintf('cMF_%s_P_%s', subjectID, intensity);
            badchans_varname = sprintf('badchans_%s_P_%s', subjectID, intensity);

            % Assign variables to base workspace
            if ~isempty(cMF_i)
                assignin('base', cMF_varname, cMF_i);
            end
            if ~isempty(badchans_i)
                assignin('base', badchans_varname, badchans_i);
                all_badchans = [all_badchans(:); badchans_i(:)];  % accumulate
            end

            fprintf('Loaded %s -> %s, %s\n', files(k).name, cMF_varname, badchans_varname);

        catch ME
            warning('Failed to load %s: %s', filepath, ME.message);
        end
    end

    % Save unique bad channels in base workspace
    unique_badchans = unique(all_badchans);
    assignin('base', 'badchans_all_unique', unique_badchans);
    fprintf('Total unique bad channels: %s\n', mat2str(unique_badchans));
end
