%% LINEAR MEASURE SELECTION FOR ALL SELECTED EPISODES + ANOVA (& ASSUMPTION OR APPROPRIATE)
clear;
load('balanced_clean_episodes.mat')

% SPLIT point TMS on 1 sec (1450 samples)
split_point = 1450;

% Datasets and labels
datasets = {'balanced_P120', 'balanced_P180', 'balanced_P240'};
labels   = {'P120', 'P180', 'P240'};

% Loop through each dataset
for d = 1:length(datasets)
    data = eval(datasets{d});  % e.g., balanced_P120
    label = labels{d};

    for i = 1:size(data, 2)  % loop over columns (signals)
        x = data(:, i);       % one full signal (2901x1)

        x_pre = x(1:split_point);
        x_post = x(split_point+1:end);

        % Create variable names and store in cell arrays
        eval(sprintf('%s_pre{%d} = x_pre;', label, i));
        eval(sprintf('%s_post{%d} = x_post;', label, i));
    end
end

% Step 2: Setup ARMA model parameters
model_orders = struct(...
    'P120_pre',  [4, 5], ... %
    'P120_post', [4, 5], ... %
    'P180_pre',  [3, 5], ... %
    'P180_post', [6, 6], ... %--
    'P240_pre',  [6, 4], ... %--
    'P240_post', [4, 2] ... % 
);
categories = fieldnames(model_orders);
Tmax = 10;
nlast = 580;

nrmse_scores = [];
group_labels = {};

% Impotant improvement Step : Compute NRMSE for each segment (with weighted mean)
% instead of the simplest mean for 10 steps prediction.
% Using the weighted mean gives less weight to further we go, so it makes 
% the H0 stronger, because the differences are seen more at the the end,
% but weighted mean seems better valid aproach.

%a1 = 0.2; % Decay factor (adjust as needed, 0 < a < 1)
            %a =~ 0 → Nearly equal weights (similar to regular mean).
            %a =~ 1 → Only the first few steps matter.

% Step 3: Compute NRMSE for each segment
for c = 1:length(categories)
    cname = categories{c};
    pq = model_orders.(cname);
    p = pq(1); q = pq(2);
    signals = eval(cname);  % cell array of time series

    for i = 1:length(signals)
        x = signals{i};
        try
            [nrmseV, ~, ~, ~] = predictARMAnrmse(x, p, q, Tmax, nlast, '');
            %(later improvement) Compute weighted mean (a*(1-a)^j weights) ---> need to keep
            % all the values and then recalculate!
            %l = length(nrmseV); % l = Tmax 
            %weights = a1 * (1 - a1).^(0:Tmax-1); % Geometric decay
            %weights = weights / sum(weights); % Normalize to sum to 1
            %weighted_mean = sum(weights .* nrmseV); % Weighted mean

            nrmse_scores(end+1,1) = mean(nrmseV);%weighted_mean; % Store weighted mean.
                                    %  % different interpretation for the 10 steps(simplest: mean(nrmseV) )
            group_labels{end+1,1} = cname;
        catch ME
            warning('Error in %s #%d: %s', cname, i, ME.message);
            nrmse_scores(end+1,1) = NaN;
            group_labels{end+1,1} = cname;
        end
    end
end
% global save the nrmse scores and group labels
save('nrmse_data_linear.mat', 'nrmse_scores', 'group_labels');
%% SAVE IT AS CSV FOR R script -> / assumptions / statistical tests / post hoc.

% Combine data into a table
T = table(nrmse_scores, group_labels, 'VariableNames', {'NRMSE', 'Group'});

% Create results folder if it doesn't exist
resultsFolder = fullfile(pwd, 'results');
if ~exist(resultsFolder, 'dir')
    mkdir(resultsFolder);
end

% Define full CSV filename
csvFilename = fullfile(resultsFolder, 'nrmse_data_linear.xlsx');

% Write table to CSV
writetable(T, csvFilename);

fprintf('NRMSE scores and labels saved to CSV: %s\n', csvFilename);


%%
