% uses swtest! (more descriptive) WORKS ONLY FOR LINEAR
%% NRMSE Data Loader: Choose Linear or Nonlinear
clear;
choice = lower(input('Load NRMSE data: type "linear" or "nonlinear": ', 's'));

switch choice
    case 'linear'
        disp('Loading linear NRMSE data...');
        load('nrmse_data_linear.mat');  % Assumes nrmse_scores, group_labels
        
    case 'nonlinear'
        disp('Loading nonlinear NRMSE data...');
        load('nrmse_data_nonlinear.mat');  % Make sure this is structured correctly
        
    otherwise
        error('Invalid choice. Please type "linear" or "nonlinear".');
end

%% ASSUMPTIONS SCRIPT works


% --- Assumption 1: Normality (Shapiro-Wilk test) ---
% Check normality only for groups with ≥3 samples
unique_groups = unique(group_labels);
normality_pvals = [];
valid_group_counts = [];

for g = 1:length(unique_groups)
    group_data = nrmse_scores(strcmp(group_labels, unique_groups{g}));
    valid_group_counts(g) = numel(group_data);
    
    if valid_group_counts(g) >= 3
        [~, p] = swtest(group_data); % Requires >=3 samples
        normality_pvals(g) = p;
    else
        normality_pvals(g) = NaN; % Mark as invalid
        warning('Group %s has <3 observations. Skipping normality test.', unique_groups{g});
    end
end

fprintf('Normality test (Shapiro-Wilk) p-values per group:\n');
disp(table(unique_groups, normality_pvals', valid_group_counts', ...
    'VariableNames', {'Group', 'p_value', 'N'})); %--- table2latex

% --- Assumption 2: Homogeneity of variances (Levene's test) ---
% Only run if all groups have ≥2 samples
if all(valid_group_counts >= 2)
    [p_levene, stats_levene] = vartestn(nrmse_scores, group_labels, 'TestType', 'LeveneAbsolute');
    fprintf('\nLevene s test for homogeneity of variances: p = %.4f\n', p_levene);
else
    p_levene = NaN;
    warning('Some groups have <2 observations. Skipping Levene s test.');
end

% --- Decide which test to run ---
if all(normality_pvals > 0.05 | isnan(normality_pvals)) && (p_levene > 0.05 | isnan(p_levene))
    % If normality/homoscedasticity assumptions are met (or skipped due to small N)
    fprintf('\nRunning standard ANOVA (assumptions met or N too small to check).\n');
    [p, tbl, stats] = anova1(nrmse_scores, group_labels);
    title('ANOVA: Comparing NRMSE across signal categories');
    
    % Post-hoc test if ANOVA is significant
    if p < 0.05
        figure;
        multcompare(stats);
        title('Post-hoc comparisons (Tukey HSD)');
    end
else
    % Non-parametric alternative (Kruskal-Wallis)
    fprintf('\nAssumptions violated (or N too small) → Running Kruskal-Wallis test.\n');
    [p_kw, tbl_kw, stats_kw] = kruskalwallis(nrmse_scores, group_labels);
    title('Kruskal-Wallis: Comparing NRMSE across signal categories');
    
    if p_kw < 0.05
        figure;
        multcompare(stats_kw);
        title('Post-hoc comparisons (Dunn s test)');
    end
end
%%
% Step 4: Run ANOVA
validIdx = ~isnan(nrmse_scores);
nrmse_scores = nrmse_scores(validIdx);
group_labels = group_labels(validIdx);

[p, tbl, stats] = anova1(nrmse_scores, group_labels);
title('ANOVA: Comparing NRMSE across signal categories');

% Optional: post-hoc test
if p < 0.05
    figure;
    multcompare(stats);
end

%% Testing the compact results for tt

load('nrmse_data_linear.mat');  % Contains: nrmse_scores (120x1), group_labels (120x1)

if ~iscategorical(group_labels)
    group_labels = categorical(group_labels);
end

T = table(nrmse_scores, group_labels, 'VariableNames', {'NRMSE', 'Group'});
groups = categories(T.Group);
intensities = {'P120', 'P180', 'P240'};

% Separate into pre/post using containers.Map
NRMSE_pre = containers.Map();
NRMSE_post = containers.Map();

for i = 1:length(intensities)
    int = intensities{i};
    NRMSE_pre(int)  = T.NRMSE(T.Group == [int '_pre']);
    NRMSE_post(int) = T.NRMSE(T.Group == [int '_post']);
end

%% Section 1: Paired Tests with Normality Check
fprintf('--- Paired Tests with Normality Check ---\n');
for i = 1:length(intensities)
    int = intensities{i};
    pre = NRMSE_pre(int);
    post = NRMSE_post(int);
    delta = post - pre;

    try
        [h_norm, p_norm] = lillietest(delta);
    catch
        warning('Lillietest failed. Setting NaN for %s.', int);
        h_norm = 1;
        p_norm = NaN;
    end

    if h_norm == 0
        [~, p_val] = ttest(pre, post);
        test_used = 'Paired t-test';
        normal_text = sprintf('Normal (p = %.4f)', p_norm);
    else
        p_val = signrank(pre, post);
        test_used = 'Signrank (non-parametric)';
        normal_text = sprintf('Not normal (p = %.4f)', p_norm);
    end

    fprintf('%s: %s | p = %.4f | %s\n', int, test_used, p_val, normal_text);
end

%% Section 2: Group Comparisons (Pre, Post, Delta) with Normality Check
fprintf('\n--- Group Comparisons with Normality Check ---\n');
sets = {'Pre-TMS', 'Post-TMS', 'Delta'};
data_map = containers.Map();
group_map = containers.Map();

for s = 1:length(sets)
    set = sets{s};
    all_data = [];
    all_groups = {};
    normal_flags = [];

    for i = 1:length(intensities)
        int = intensities{i};

        if strcmp(set, 'Pre-TMS')
            data = NRMSE_pre(int);
        elseif strcmp(set, 'Post-TMS')
            data = NRMSE_post(int);
        else  % Delta
            data = NRMSE_post(int) - NRMSE_pre(int);
        end

        all_data = [all_data; data];
        all_groups = [all_groups; repmat({int}, length(data), 1)];

        try
            [h, p] = lillietest(data);
        catch
            warning('Lillietest failed for %s (%s).', set, int);
            h = 1;
            p = NaN;
        end

        normal_flags(end+1) = ~h;
        if h == 0
            fprintf('%s - %s: Normal (p = %.4f)\n', set, int, p);
        else
            fprintf('%s - %s: Not normal (p = %.4f)\n', set, int, p);
        end
    end

    % Choose test
    if all(normal_flags)
        [pval, ~, stats] = anova1(all_data, all_groups, 'off');
        test_type = 'ANOVA';
    else
        [pval, ~, stats] = kruskalwallis(all_data, all_groups, 'off');
        test_type = 'Kruskal-Wallis';
    end

    fprintf('%s comparison: %s p = %.4f\n', set, test_type, pval);

    if pval < 0.05
        figure;
        multcompare(stats);
        title([set ' NRMSE - ' test_type]);
    end

    % Store for plotting
    data_map(set) = all_data;
    group_map(set) = all_groups;
end

%% Section 3: Density Plots per Group
fprintf('\n--- Plotting Density Estimates ---\n');
figure;
for s = 1:length(sets)
    set = sets{s};
    data = data_map(set);
    groups = group_map(set);

    subplot(1, length(sets), s);
    hold on;
    legends = {};

    for i = 1:length(intensities)
        int = intensities{i};
        x = data(strcmp(groups, int));
        [f, xi] = ksdensity(x);
        plot(xi, f, 'LineWidth', 1.5);
        legends{end+1} = int;
    end

    title([set ' Density']);
    xlabel('NRMSE');
    ylabel('Density');
    legend(legends, 'Location', 'Best');
    grid on;
end
sgtitle('NRMSE Density Comparison Across Intensities');
