%%
%{
DO NOT RUN IT ALL, USE MATS AT SOME POINT ON THE SCRIPT

OUTPUT:
- preferable format for the nrmse produced from the optimal 
  nonlinear model using MATS
%}


% Load the original file
load('balanced_clean_episodes.mat');

% Split into pre and post
balanced_P120_pre  = balanced_P120(1:1450, :);
balanced_P120_post = balanced_P120(1451:end, :);

balanced_P180_pre  = balanced_P180(1:1450, :);
balanced_P180_post = balanced_P180(1451:end, :);

balanced_P240_pre  = balanced_P240(1:1450, :);
balanced_P240_post = balanced_P240(1451:end, :);

% Save each segment separately
save('balanced_P120_pre.mat',  'balanced_P120_pre');
save('balanced_P120_post.mat', 'balanced_P120_post');

save('balanced_P180_pre.mat',  'balanced_P180_pre');
save('balanced_P180_post.mat', 'balanced_P180_post');

save('balanced_P240_pre.mat',  'balanced_P240_pre');
save('balanced_P240_post.mat', 'balanced_P240_post');

%% Run the optimal non-linear model ON LOCAL MATS VERSION 2022b
%Extract the table of measure on matlab and save it like this.

%nrmse_non_linear = Table_of_Measures;
%save('nrmse_non_linear.mat','nrmse_non_linear');
load('nrmse_non_linear.mat')

% And that it's a 2x121 cell array
% Remove the first column (model name)
nrmse_non_linear = nrmse_non_linear(:, 2:end);

%% wide to long format
% Ensure labels are categorical
group_labels = categorical(nrmse_non_linear(1, :)');   % 120x1
nrmse_scores = cell2mat(nrmse_non_linear(2, :)');      % Convert to numeric if needed


original_labels = nrmse_non_linear(1, :)';  % Cell array of original labels (120x1)

% Preallocate cell array for new simplified labels
simplified_labels = cell(size(original_labels));

for i = 1:length(original_labels)
    str = original_labels{i};

    % Extract intensity (P120, P180, P240)
    intensity_match = regexp(str, 'P\d{3}', 'match', 'once');

    % Determine pre/post
    if contains(str, 'pre', 'IgnoreCase', true)
        phase = 'pre';
    elseif contains(str, 'post', 'IgnoreCase', true)
        phase = 'post';
    else
        phase = 'unknown';
    end

    % Combine to form simplified label
    simplified_labels{i} = [intensity_match '_' phase];
end

% Convert to categorical
group_labels = categorical(simplified_labels);

% Convert NRMSE scores to numeric
nrmse_scores = cell2mat(nrmse_non_linear(2, :)');

% Combine into a table
T = table(nrmse_scores, group_labels, 'VariableNames', {'NRMSE', 'Group'});

% Preview table
disp(head(T));

% Save as .mat file
save('nrmse_data_nonlinear.mat', 'nrmse_scores','group_labels');
%% this is used for the R script in folder Results
% Optional: save as .csv file too
writetable(T, 'results/nrmse_data_nonlinear.xlsx');

