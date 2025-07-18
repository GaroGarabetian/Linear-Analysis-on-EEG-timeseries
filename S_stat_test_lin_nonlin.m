%%--------------- Load NRMSE Data for linear or nonlinear

    % For the non linear NRMSEs check out mats_nrmse_prep.m
    % Need to use MATS and it formats properly the data 
%INPUT: 
%       NRMSE, GROUP_LABELS
%OUTPUT:
%       Performs appropriate statistical testing on the research question
%      - (The R script is used for some insights)


 %% LINEAR NRMSE STATISTICAL COMPARISONS 
   
%% NON LINEAR 120 NRMSEs ARE EXTRACTED IN MATS
 %(mats can't handle .mat file with multiple saved objects, so we procced in this way.)
    % Check documentation on this
                 %mats_nrmse_prep formats properly the outcome from MATS
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


%% MANUAL Load Data
%load('nrmse_data_linear.mat');  % assumes nrmse_scores and group_labels
%load('nrmse_data_nonlinear.mat') % assumes nrmse_scores and group_labels

% Convert group_labels to categorical if not already
if ~iscategorical(group_labels)
    group_labels = categorical(group_labels);
end

% Create table for easier manipulation
T = table(nrmse_scores, group_labels, 'VariableNames', {'NRMSE', 'Group'});

% Extract all unique group names
groups = categories(T.Group);

% Optional: Preview data
disp(head(T));

%% Separate groups by label
% Expecting 6 labels like: 'P120_pre', 'P120_post', 'P180_pre', etc.
intensities = {'P120', 'P180', 'P240'};
NRMSE_pre = struct();
NRMSE_post = struct();

for i = 1:length(intensities)
    label = intensities{i};
    pre_label = [label '_pre'];
    post_label = [label '_post'];
    
    NRMSE_pre.(label) = T.NRMSE(T.Group == pre_label);
    NRMSE_post.(label) = T.NRMSE(T.Group == post_label);
end

%% 1. Paired t-tests for each intensity
fprintf('--- Paired Tests (Pre vs Post for each intensity) ---\n');
for i = 1:length(intensities)
    label = intensities{i};
    [p, ~] = ttest(NRMSE_pre.(label), NRMSE_post.(label));
    fprintf('%s: pre vs post p = %f\n', label, p);%%.5f
end

%% 2. ANOVA for Post-TMS comparisons
fprintf('\n--- ANOVA for Post-TMS NRMSE across intensities ---\n');
post_data = [];
post_groups = {};

for i = 1:length(intensities)
    label = intensities{i};
    n = length(NRMSE_post.(label));
    post_data = [post_data; NRMSE_post.(label)];
    post_groups = [post_groups; repmat({label}, n, 1)];
end

[p_post, ~, stats_post] = anova1(post_data, post_groups, 'off');
fprintf('ANOVA p-value (Post-TMS): %.4f\n', p_post);
if p_post < 0.05
    figure; multcompare(stats_post);
    title('Post-TMS NRMSE - Tukey HSD');
end

%% 3. ANOVA for Pre-TMS comparisons
fprintf('\n--- ANOVA for Pre-TMS NRMSE across intensities ---\n');
pre_data = [];
pre_groups = {};

for i = 1:length(intensities)
    label = intensities{i};
    n = length(NRMSE_pre.(label));
    pre_data = [pre_data; NRMSE_pre.(label)];
    pre_groups = [pre_groups; repmat({label}, n, 1)];
end

[p_pre, ~, stats_pre] = anova1(pre_data, pre_groups, 'off');
fprintf('ANOVA p-value (Pre-TMS): %.4f\n', p_pre);
if p_pre < 0.05
    figure; multcompare(stats_pre);
    title('Pre-TMS NRMSE - Tukey HSD');
end

%% 4. ANOVA on Delta (Post - Pre)
fprintf('\n--- ANOVA for ΔNRMSE (Post - Pre) across intensities ---\n');
delta_data = [];
delta_groups = {};

for i = 1:length(intensities)
    label = intensities{i};
    delta = NRMSE_post.(label) - NRMSE_pre.(label);
    n = length(delta);
    delta_data = [delta_data; delta];
    delta_groups = [delta_groups; repmat({label}, n, 1)];
end

[p_delta, ~, stats_delta] = anova1(delta_data, delta_groups, 'off');
fprintf('ANOVA p-value (ΔNRMSE): %.4f\n', p_delta);
if p_delta < 0.05
    figure; multcompare(stats_delta);
    title('ΔNRMSE - Tukey HSD');
end

%% Optional: Boxplot comparison
figure;
for i = 1:length(intensities)
    label = intensities{i};
    subplot(1,3,i);
    boxplot([NRMSE_pre.(label), NRMSE_post.(label)], {'Pre','Post'});
    title(label);
end
sgtitle('NRMSE Comparison: Pre vs Post per Intensity');



     
    %% automate the procedure needs improvement/doublecheck... warnings
 %{
% Loop-Based Normality + Testing (Pre vs Post) with Non-Parametric Switch
fprintf('--- Paired Tests (Pre vs Post) with Normality Check ---\n');
for i = 1:length(intensities)
    label = intensities{i};
    pre = NRMSE_pre.(label);
    post = NRMSE_post.(label);
    delta = post - pre;

    % Normality test for delta
    [h_norm, p_norm] = lillietest(delta);

    if h_norm == 0  % Normally distributed
        [~, p] = ttest(pre, post);
        test_used = 'Paired t-test';
    else
        p = signrank(pre, post);
        test_used = 'Signrank (non-parametric)';
    end

    fprintf('%s: %s p = %.4f (Normality p = %.4f)\n', label, test_used, p, p_norm);
end

%% ANOVA or Kruskal-Wallis (Post-TMS)
fprintf('\n--- Intensity Comparison (Post-TMS) ---\n');

post_data = [];
post_groups = {};
normal_flags = zeros(length(intensities), 1);  % Track normality results

for i = 1:length(intensities)
    label = intensities{i};
    d = NRMSE_post.(label);
    
    post_data = [post_data; d];  % Aggregate post-TMS data
    post_groups = [post_groups; repmat({label}, length(d), 1)];
    
    [h, p_norm] = lillietest(d);  % Normality test
    normal_flags(i) = ~h;  % Store normality result

    % Display normality status
    if h == 0
        fprintf('%s: Normality p = %.4f => Normal\n', label, p_norm);
    else
        fprintf('%s: Normality p = %.4f => Not normal\n', label, p_norm);
    end
end

% Choose appropriate test based on normality
if all(normal_flags)
    [p_post, ~, stats_post] = anova1(post_data, post_groups, 'off');
    test_type = 'ANOVA';
else
    [p_post, ~, stats_post] = kruskalwallis(post_data, post_groups, 'off');
    test_type = 'Kruskal-Wallis';
end

fprintf('%s p-value (Post-TMS): %.4f\n', test_type, p_post);

% Post-hoc test if overall result is significant
if p_post < 0.05
    figure;
    multcompare(stats_post);
    title(['Post-TMS NRMSE - ' test_type]);
else
    fprintf('No significant difference found (p = %.4f). Plotting skipped.\n', p_post);
end


%% Repeat for Pre-TMS
fprintf('\n--- Intensity Comparison (Pre-TMS) ---\n');
pre_data = [];
pre_groups = {};
normal_flags = zeros(length(intensities), 1);

for i = 1:length(intensities)
    label = intensities{i};
    d = NRMSE_pre.(label);
    pre_data = [pre_data; d];
    pre_groups = [pre_groups; repmat({label}, length(d), 1)];
    
    [h, ~] = lillietest(d);
    normal_flags(i) = ~h;
end

if all(normal_flags)
    [p_pre, ~, stats_pre] = anova1(pre_data, pre_groups, 'off');
    test_type = 'ANOVA';
else
    [p_pre, ~, stats_pre] = kruskalwallis(pre_data, pre_groups, 'off');
    test_type = 'Kruskal-Wallis';
end

fprintf('%s p-value (Pre-TMS): %.4f\n', test_type, p_pre);
if p_pre < 0.05
    figure; multcompare(stats_pre);
    title(['Pre-TMS NRMSE - ' test_type]);
end

%% Repeat for ΔNRMSE (Post - Pre)


 fprintf('\n--- Intensity Comparison (ΔNRMSE) ---\n');
delta_data = [];
delta_groups = {};
normal_flags = zeros(length(intensities), 1);

for i = 1:length(intensities)
    label = intensities{i};
    delta = NRMSE_post.(label) - NRMSE_pre.(label);
    delta_data = [delta_data; delta];
    delta_groups = [delta_groups; repmat({label}, length(delta), 1)];
    
    [h, ~] = lillietest(delta);
    normal_flags(i) = ~h;
end

if all(normal_flags)
    [p_delta, ~, stats_delta] = anova1(delta_data, delta_groups, 'off');
    test_type = 'ANOVA';
else
    [p_delta, ~, stats_delta] = kruskalwallis(delta_data, delta_groups, 'off');
    test_type = 'Kruskal-Wallis';
end

fprintf('%s p-value (ΔNRMSE): %.4f\n', test_type, p_delta);
if p_delta < 0.05
    figure; multcompare(stats_delta);
    title(['ΔNRMSE - ' test_type]);
end
%}