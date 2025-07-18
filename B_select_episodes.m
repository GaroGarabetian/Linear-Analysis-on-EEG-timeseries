%     ----- (STEP2) -------
% SELECTING AND COMBINING

%  Set random seed for reproducibility
seed = 28;  % Set this to a fixed value for reproducible results (NOTICE FOR ED EXCLUSION!!)
rng(seed);
                    % IF MULTIPLE PATIENTS ARE SELECTED.
                    %  Randomly selecting N columns 
                    %    from each Patient and each Intensity(% of Stimulation)
                    %     ->   equal probability of selection a patient (p = 1/4)-- 
                    %    Dependent on patients Randomised Episodes balanced on patients and intensities
                    %     4(Patients)* 3 Intesities * N(selected number: 10) = 120 episodes 
% FOR ONE PATIENT.
% 
% N: number of columns(episodes) to select from each intensity
%
% OUTPUT: Combines the data for every intesity among patients
% e.g N= 30 , 1 patients, 3 Intensities and Length of episode (2 sec = 2901 samples)
% - combined_P120 (2901 x 30)
% - combined_P180 (2901 x 30)
% - combined_P240 (2901 x 30)
% Total: 90 episodes (contains rare ED cases)


% ==========================================
%uncomment for seperate use and reselecting N
%clear;
load('channel28_all.mat');
all_vars = evalin('base', "who('channel28_*_P_*')");
%
N = 30; 
%==========================================
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

fprintf('Total Episodes selected with probable parasites(EDs) are %d.\n', N * length(all_vars));

% Initialize containers for each P group (all refer to CHANNEL 28)
combined_P120 = [];
combined_P180 = [];
combined_P240 = [];

% Get all field names (channel28_j_P_i, j = patients, i =  intensity)
fields = fieldnames(selected_data);

for i = 1:length(fields)
    varname = fields{i};
    data_subset = selected_data.(varname);
    
    % Check suffix and concatenate accordingly
    if contains(varname, '_P_120')
        combined_P120 = [combined_P120, data_subset];  % concatenate horizontally
    elseif contains(varname, '_P_180')
        combined_P180 = [combined_P180, data_subset];
    elseif contains(varname, '_P_240')
        combined_P240 = [combined_P240, data_subset];
    end
end

% Display sizes
fprintf('Combined size for P_120: %dx%d\n', size(combined_P120,1), size(combined_P120,2));
fprintf('Combined size for P_180: %dx%d\n', size(combined_P180,1), size(combined_P180,2));
fprintf('Combined size for P_240: %dx%d\n', size(combined_P240,1), size(combined_P240,2));





