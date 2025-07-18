% (Implementation from my R script)

%Decision Tree for Tests

%normality_assumption == T && Homoscedasticity <- T --- use one-way ANOVA 

%normality_assumption == T && Homoscedasticity <- F --- use ANOVA Welch's test 

%  normality_assumption == F (&& homoscedasticity <- F or T )--- Kruskal Wallis test

%PostHoc Tests Structure

    %-%One-way ANOVA normality_assumption == T && Homoscedasticity == T
    %Tukey test
    %Pairwise T-tests with Bonferroni Correction pool.sd = TRUE

    %-%ANOVA WITH UNEQUAl variance %normality_assumption == T && Homoscedasticity <- F 
    %Games - Howel

    %-% Kruskal Wallis test  normality_assumption == F (&& homoscedasticity <- F or T )
    %Dunn's approach  p.adjust.method = "bonferroni"
    %Pairwise comparisons using WilcoxMW's test with Bonferroni correction 
%load('nrmse_data_nonlinear.mat')
load('nrmse_data_linear.mat')
%% Step 4: Data Transformation for Normality
% Copy original scores for comparison
original_scores = nrmse_scores;
original_labels = group_labels;

% Initialize transformed versions
transformed_scores = nrmse_scores;
best_transformation = 'none';

% Try Box-Cox transformation
try
    [transformed_bc, lambda] = boxcox(nrmse_scores + eps); % Add eps to handle zeros
    % Test normality
    [~, p_bc] = swtest(transformed_bc);
    if p_bc > 0.05
        transformed_scores = transformed_bc;
        best_transformation = sprintf('Box-Cox (λ=%.2f)', lambda);
        fprintf('Box-Cox transformation successful (λ=%.2f)\n', lambda);
    end
catch ME
    warning('Box-Cox transformation failed: %s', ME.message);
end

% Try Gaussian transformation (inverse normal transform)
if strcmp(best_transformation, 'none')
    try
        transformed_gauss = norminv((rank(nrmse_scores)-0.5)/length(nrmse_scores));
        [~, p_gauss] = swtest(transformed_gauss);
        if p_gauss > 0.05
            transformed_scores = transformed_gauss;
            best_transformation = 'Gaussian';
            fprintf('Gaussian transformation successful\n');
        end
    catch ME
        warning('Gaussian transformation failed: %s', ME.message);
    end
end

% Try log transformation if still not normal
if strcmp(best_transformation, 'none')
    try
        transformed_log = log(nrmse_scores + eps);
        [~, p_log] = swtest(transformed_log);
        if p_log > 0.05
            transformed_scores = transformed_log;
            best_transformation = 'Log';
            fprintf('Log transformation successful\n');
        end
    catch ME
        warning('Log transformation failed: %s', ME.message);
    end
end

fprintf('\nBest transformation: %s\n', best_transformation);

%% Visualization Before/After Transformation
figure;
subplot(2,1,1);
histfit(original_scores);
title('Original NRMSE Scores');
subplot(2,1,2);
histfit(transformed_scores);
title(sprintf('Transformed NRMSE (%s)', best_transformation));

%% Step 5: Recheck Assumptions with Transformed Data
unique_groups = unique(original_labels);
normality_pvals = [];
valid_group_counts = [];

for g = 1:length(unique_groups)
    group_data = transformed_scores(strcmp(original_labels, unique_groups{g}));
    valid_group_counts(g) = numel(group_data);
    
    if valid_group_counts(g) >= 3
        [~, p] = swtest(group_data);
        normality_pvals(g) = p;
    else
        normality_pvals(g) = NaN;
    end
end

fprintf('\nNormality test after transformation:\n');
disp(table(unique_groups, normality_pvals', valid_group_counts', ...
    'VariableNames', {'Group', 'p_value', 'N'}));
%table2latex(table(unique_groups, normality_pvals', valid_group_counts', ...
%    'VariableNames', {'Group', 'p_value', 'N'}),'Normality test after
%    transformation') % for later use on latex!

% Homogeneity of variances
if all(valid_group_counts >= 2)
    [p_levene, ~] = vartestn(transformed_scores, original_labels, 'TestType', 'LeveneAbsolute');
    fprintf('\nLevene''s test on transformed data: p = %.4f\n', p_levene);
else
    p_levene = NaN;
end

%% Step 6: Run Appropriate Test
if all(normality_pvals > 0.05 | isnan(normality_pvals)) && (p_levene > 0.05 | isnan(p_levene))
    % Parametric ANOVA
    fprintf('\nRunning ANOVA on transformed data (%s transformation)\n', best_transformation);
    [p, tbl, stats] = anova1(transformed_scores, original_labels);
    title(sprintf('ANOVA: Transformed NRMSE (%s)', best_transformation));
    
    if p < 0.05
        figure;
        multcompare(stats);
        title(sprintf('Post-hoc (Tukey HSD) on %s-transformed data', best_transformation));
    end
else
    % Non-parametric Kruskal-Wallis
    fprintf('\nAssumptions still violated → Running Kruskal-Wallis on original data\n');
    [p_kw, tbl_kw, stats_kw] = kruskalwallis(original_scores, original_labels);
    title('Kruskal-Wallis: Original NRMSE Scores');
    
    if p_kw < 0.05
        figure;
        multcompare(stats_kw);
        title('Post-hoc (Dunn''s test) on original data');
    end
end

%% Additional Diagnostic Plots
figure;
% Q-Q plot of transformed data
subplot(1,2,1);
qqplot(transformed_scores);
title(sprintf('Q-Q Plot (%s Transformed)', best_transformation));

% Residuals plot if ANOVA was run
if exist('stats', 'var')
    subplot(1,2,2);
    scatter(stats.means, stats.resids);
    refline(0,0);
    xlabel('Group Means');
    ylabel('Residuals');
    title('Residuals vs. Group Means');
end