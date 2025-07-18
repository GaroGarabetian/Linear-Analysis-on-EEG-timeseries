%% ------------ PILOT SEARCH (RQ1) ----------
%  The 3 Randomly Selected Time-Series (Episodes) of different intesity.
%  - Splitting on TMS to PreTMS and PostTMS (split_point = 1450)
%  Shows the ACF and PACF of 6 half-episodes (3 Intesities * 2 segments)
%  - for sufficient lags (tmax = 50,70,100), used larger lags as well because of long memory for acf.
%   (default tmax = 60)
%  Make sure you have the functions autocorrelation.m and acf2pacf.m


load('balanced_clean_episodes.mat')
load('kept_episode_indices.mat')  % contains kept_idx_P120, kept_idx_P180, kept_idx_P240

% Set a seed for reproducibility
rng(28);  
% Get random indices from the balanced datasets
idx120 = randi(size(balanced_P120, 2));
idx180 = randi(size(balanced_P180, 2));
idx240 = randi(size(balanced_P240, 2));

% Extract one random episode from each
P120_ = balanced_P120(:, idx120);
P180_ = balanced_P180(:, idx180);
P240_ = balanced_P240(:, idx240);

% Map back to original episode indices (in combined_Pxxx)
original_idx_P120 = kept_idx_P120(idx120);
original_idx_P180 = kept_idx_P180(idx180);
original_idx_P240 = kept_idx_P240(idx240);

% Display results
fprintf('Selected balanced episode indices: P120 = %d, P180 = %d, P240 = %d\n', idx120, idx180, idx240);
fprintf('Corresponding original episode indices: P120 = %d, P180 = %d, P240 = %d\n', ...
    original_idx_P120, original_idx_P180, original_idx_P240);

%% Plot them
fig = figure;
t = tiledlayout(3, 1, 'TileSpacing', 'loose', 'Padding', 'loose');  % You can also try 'loose' for more space

% P120 subplot
nexttile;
plot(P120_);
title(sprintf('Episode %d from P120 Intensity', original_idx_P120));
xline(1451, '--r');
ylabel('EEG');

% P180 subplot
nexttile;
plot(P180_);
title(sprintf('Episode %d from P180 Intensity', original_idx_P180));
xline(1451, '--r');
ylabel('EEG');

% P240 subplot
nexttile;
plot(P240_);
title(sprintf('Episode %d from P240 Intensity', original_idx_P240));
xline(1451, '--r');
xlabel('Time (samples)');
ylabel('EEG');

% Export to TikZ
%exportTikzFigure(fig, '3episodes');


%%
% Create dynamic variable names inside a struct
episodes = struct();
episodes.(sprintf('P120_%d', idx120)) = P120_;
episodes.(sprintf('P180_%d', idx180)) = P180_;
episodes.(sprintf('P240_%d', idx240)) = P240_;

% Save the struct's fields as variables in the .mat file
save('selected_3episodes.mat', '-struct', 'episodes');


%% IMMUNE TO DIFFERENT INDECES FOR LATER GENERALISATION
% Load all variables from .mat file
vars = load('selected_3episodes.mat');

% Initialize empty cell array for signals
signals = {};

% Loop through expected intensities
intensities = {'P120', 'P180', 'P240'};

for i = 1:length(intensities)
    prefix = intensities{i};

    % Find the field that starts with the given prefix (e.g., 'P120_')
    match = startsWith(fieldnames(vars), [prefix '_']);
    
    matched_vars = fieldnames(vars);
    matched_var = matched_vars{match};

    % Store the signal and its label
    signals{i, 1} = vars.(matched_var);
    signals{i, 2} = prefix;
end

%%

% SPLIT point TMS on 1 sec (1450 samples)
split_point = 1450;  % Define cutoff for pre/post segmentation


% Loop through each signal, segment and save 
for i = 1:size(signals, 1)
    x = signals{i,1};
    label = signals{i,2};

    % Split into preTMS and postTMS
    x_pre = x(1:split_point);
    x_post = x(split_point+1:end);

    % Create variable names dynamically
    pre_varname = sprintf('%s_pre', label);
    post_varname = sprintf('%s_post', label);

    % Assign to workspace variables
    eval([pre_varname ' = x_pre;']);
    eval([post_varname ' = x_post;']);

    % Save to corresponding files
    %save([pre_varname '.mat'], pre_varname);
    %save([post_varname '.mat'], post_varname);

    %fprintf('Saved %s.mat and %s.mat\n', pre_varname, post_varname);
end


% Max lag for ACF/PACF
tmax = 60; % sufficient number of lags

% The segmentation is included in the loop, if we later on want to check
% more episodes
for i = 1:size(signals, 1)
    x = signals{i,1};
    label = signals{i,2};

    % Split into before and after
    x_pre = x(1:split_point);
    x_post = x(split_point+1:length(x));

    N_pre = length(x_pre);
    N_post = length(x_post);
    CI_pre = 1.96 / sqrt(N_pre); % 95% Confidence Interval
    CI_post = 1.96 / sqrt(N_post);

    %% --- ACF Plot ---
    acf_pre = autocorrelation(x_pre, tmax, '', 'b');
    acf_post = autocorrelation(x_post, tmax, '', 'b');

    figure;
    subplot(2,1,1);
    plot(acf_pre(:,1), acf_pre(:,2), 'b', 'LineWidth', 1.5); hold on;
    plot(acf_post(:,1), acf_post(:,2), 'r', 'LineWidth', 1.5);
    yline(0, 'k-');
    yline(CI_pre, 'b--', 'LineWidth', 1);
    yline(-CI_pre, 'b--', 'LineWidth', 1);
    yline(CI_post, 'r--', 'LineWidth', 1);
    yline(-CI_post, 'r--', 'LineWidth', 1);
    ylim([-1 1]);
    title(['ACF - ', label]);
    xlabel('Lag');
    ylabel('Autocorrelation');
    legend('Pre-TMS', 'Post-TMS', 'Location', 'best');

    %% --- PACF Plot ---
    pacf_pre = acf2pacf(acf_pre(2:end,2), 0);
    pacf_post = acf2pacf(acf_post(2:end,2), 0);

    subplot(2,1,2);
    stem(1:length(pacf_pre), pacf_pre, 'b', 'filled'); hold on;
    stem(1:length(pacf_post), pacf_post, 'r', 'filled');
    yline(0, 'k-');
    yline(CI_pre, 'b--', 'LineWidth', 1);
    yline(-CI_pre, 'b--', 'LineWidth', 1);
    yline(CI_post, 'r--', 'LineWidth', 1);
    yline(-CI_post, 'r--', 'LineWidth', 1);
    ylim([-1 1]);
    title(['PACF - ', label]);
    xlabel('Lag');
    ylabel('Partial Autocorrelation');
    legend('Pre-TMS', 'Post-TMS', 'Location', 'best');

    % datacursor and save
    datacursormode on;
end
% Comment to show the figures acf/pacf among intensities
%close all;

% Save them separately
save('pre_post_episodes.mat', 'P120_pre','P120_post','P180_pre','P180_post','P240_pre','P240_post');
fprintf('The 6 pre-TMS and post-TMS episodes are saved to pre_post_episodes.mat \n');

 %% MATS CAN ONLY RECOGNISE THEM AS A MATRIX 1450x6
% P120_post = P120_post(1:1450);%need to have them same size
% P180_post = P180_post(1:1450);
% P240_post = P240_post(1:1450);
% all_pre_post = [P120_pre(:), P120_post(:), ...
%                 P180_pre(:), P180_post(:), ...
%                 P240_pre(:), P240_post(:)];
% save('pre_post_episodes_matrix.mat', 'all_pre_post');
 %% SEPARATE SAVE FOR PILOT NON LINEAR ANALYSIS IN MATS
% save('P120_pre.mat', 'P120_pre');
% save('P120_post.mat', 'P120_post');
% save('P180_pre.mat', 'P180_pre');
% save('P180_post.mat', 'P180_post');
% save('P240_pre.mat', 'P240_pre');
% save('P240_post.mat', 'P240_post');
% 
% fprintf('Each signal has been saved to its own .mat file.\n');
%%
%% Plot all 6 ACFs in one figure and mark first insignificant lag
figure;
hold on;

% Load the pre/post segments if not already loaded
if ~exist('P120_pre', 'var') || ~exist('P120_post', 'var')
    load('pre_post_episodes.mat');
end

% Define parameters
tmax = 40;  % Number of lags to show
intensities = {'P120', 'P180', 'P240'};
segment_names = {'pre', 'post'};
colors = {[0 0.4470 0.7410], [0.8500 0.3250 0.0980], [0.9290 0.6940 0.1250]}; % Distinct colors for each intensity
line_styles = {'-', '--'}; % Solid for pre, dashed for post
markers = {'o', 's'}; % Circle for pre, square for post

% Create a cell array of all signals
signals = {
    P120_pre, P120_post;
    P180_pre, P180_post;
    P240_pre, P240_post
};

% Prepare legend entries
legend_entries = {};
h = []; % Handles for legend

% Plot each ACF and find first insignificant lag
for i = 1:3  % For each intensity
    for j = 1:2  % For each segment (pre/post)
        x = signals{i,j};
        N = length(x);
        CI = 1.96 / sqrt(N);  % 95% confidence interval
        
        % Compute ACF
        acf = autocorrelation(x, tmax, '', 'k');
        lags = acf(:,1);
        acf_values = acf(:,2);
        
        % Plot ACF
        line_handle = plot(lags, acf_values, ...
            'Color', colors{i}, ...
            'LineStyle', line_styles{j}, ...
            'Marker', markers{j}, ...
            'MarkerIndices', 1:2:length(lags), ...
            'MarkerSize', 4, ...
            'LineWidth', 1.5);
        h = [h, line_handle];
        
        % Find first insignificant lag (where ACF crosses CI boundary)
        first_insig = find(abs(acf_values) < CI, 1);
        if ~isempty(first_insig)
            % Mark the first insignificant lag with a star
            plot(lags(first_insig), acf_values(first_insig), 'kp', ...
                'MarkerSize', 10, 'LineWidth', 1.5);
            text(lags(first_insig), acf_values(first_insig), ...
                sprintf(' %d', first_insig), ...
                'VerticalAlignment', 'bottom', 'FontWeight', 'bold');
        end
        
        % Add to legend
        legend_entries{end+1} = sprintf('%s %s-TMS', intensities{i}, segment_names{j});
    end
end

% Plot confidence intervals
for i = 1:3
    for j = 1:2
        x = signals{i,j};
        N = length(x);
        CI = 1.96 / sqrt(N);
        plot([0 tmax], [CI CI], ':', 'Color', colors{i}, 'LineWidth', 0.5);
        plot([0 tmax], [-CI -CI], ':', 'Color', colors{i}, 'LineWidth', 0.5);
    end
end

% Add zero line
yline(0, 'k-', 'LineWidth', 1);

% Formatting
xlim([0 tmax]);
ylim([-1 1]);
xlabel('Lag');
ylabel('Autocorrelation');
title('ACF for All Segments with First Insignificant Lag Marked');
grid on;

% Create legend
legend(h, legend_entries, 'Location', 'eastoutside', 'NumColumns', 1);

% Add annotation for the stars
annotation('textbox', [0.8 0.1 0.1 0.1], 'String', '★ = first insignificant lag', ...
    'FitBoxToText', 'on', 'EdgeColor', 'none', 'FontSize', 10);