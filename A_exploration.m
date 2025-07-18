%                     -----(STEP 1)-----
% --- Directions for general use -------
%   - Make sure you have load_cmf_files() FUNCTION
%   - Choose accordingly the Preferred_channel (default: 28)
%   - Make sure you have the data for the preferred patient (default: 2) 
%        - Format: P03_HF_I040_P120_v3_V2022CL.mat
%        - Check documentation load_cmf_files() (works for multiple patients as well)
%        - In our analysis, we want ONE patient so 3 .mat files for every intensity
%   - Assign the N: number of episodes picked from one patient (it can be used from each patient as well)
%                   for all intensities (default: 10)
%
%   - Optional: Make sure to comment (clear;) in the script for
%               detailed workspace (default: efficient )
%
%   OUTPUT: CREATES objects:
%                   -channel{Preferred_channel}_{PatientID}_P{Intensity}
%                               (Length of Episode x N)
%                   -global save file: channel{Preferred_channel}_all.mat
%

clear;
%% Loads files in the workspace and keeping only cMF and 
% (showing all unique badchannels, if multiple patients)
load_cmf_files(); % -> Bad channels: [15;16;17;22;23;24;25;26;29;33;45;53;60] (these are for all 4 patients)

%cMF(time, channel, TMS)
%e.g size: 2901 x 60 x 89

%%
% Selection of channel (badchannels: different for each patient)
Preferred_channel = 28; % 28 is not included in the badchannels

% Get all variable names matching cMF_* from the base workspace
% Sqeeze the dimention of K: channels
cmf_vars = evalin('base', "who('cMF_*')");

for i = 1:length(cmf_vars)
    varname = cmf_vars{i};
    cMF = evalin('base', varname);
    
    % Extract and squeeze the 28th channel
    channel_data = squeeze(cMF(:, Preferred_channel, :));
    
    % Create new variable name, e.g., channel28_01_P_120
    new_varname = strrep(varname, 'cMF', 'channel28');
    
    % Assign to base workspace
    assignin('base', new_varname, channel_data);
    
    fprintf('Extracted channel 28 -> %s\n',new_varname);
end


% Plot example time serie specific episode
%plot(channel28_04_P_240(:,40));
%xlabel('Time (samples)');
%ylabel('Amplitude');
%title('Channel 28 - Episode 40');

% Saving the time series of the preferred channel 
% Get all variables that start with 'channel28_'
vars_to_save = evalin('base', "who('channel28_*')");

% Save them into a .mat file (GLOBAL)
save('channel28_all.mat', vars_to_save{:});


clear; % Comment this line if you want to keep all objects in Workspace
load('channel28_all.mat');
all_vars = evalin('base', "who('channel28_*_P_*')");

% Eyeballing the ED cases on plot_grouped_tseries or find a method to generalise finding ED
% ED bibliography

%%%%% select_episodes.m
N = 30;  % number of episodes to select from each Intenisy (120,180,240)
selected_data = struct();

for i = 1:length(all_vars)
    varname = all_vars{i};
    data = evalin('base', varname);
    
    [rows, K] = size(data);
    if N > K
        error('N is greater than the number of columns in %s', varname);
    end
    
    cols_idx = randperm(K, N);
    selected_subset = data(:, cols_idx);
    
    selected_data.(varname) = selected_subset;
    
    fprintf('Selected %d columns from %s\n', N, varname);
end

% Optionally assign back to base workspace
fields = fieldnames(selected_data);
for i = 1:length(fields)
    assignin('base', fields{i}, selected_data.(fields{i}));
end



