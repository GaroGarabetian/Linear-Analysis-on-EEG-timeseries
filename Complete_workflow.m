%%  MATLAB version: ---- R2025a ---- 
% ==== Fully Integrated Analysis ===
% - documentation included in every script
% - need for the mentioned functions and data in this format:
%% Main Analysis Pipeline with Error Handling
% Ensure clean workspace and close figures
clear variables
close all
clc

%% Check Function Dependencies
requiredFunctions = {
    'A_exploration', 'load_cmf_files', ...
    'B_select_episodes', 'plot_grouped_tseries',...
    'C_ED_Exclusion_plot_grouped_tseries',...
    'D_split3_acf_pacf_RQ1', 'autocorrelation','acf2pacf',...
    'E_grid_search_ARMA_degrees_RQ2', 'fitARMA', 'portmanteauLB', ...
                                      'quick_arma_check', ... 
    'F_nrmse_opt_models_RQ3',...
    'G_nrmse_all_selected_linear.m',...
    'predictARMAnrmse', 'nrmse', 'plotnrmse',...
    'swtest',...
    'mats_nrmse_prep' % transforms the extracted data from MATS to our analysis here!!
    'S_stat_test_lin_nonlin','assumptions_anova','stat_tests_linear_nrmse'
};

requiredDataFiles = {
    'P03_HF_I040_P120_v3_V2022CL.mat';
    'P03_HF_I059_P180_v3_V2022CL.mat';
    'P03_HF_I079_P240_v3_V2022CL.mat';
    'nrmse_data_nonlinear.mat';
    'balanced_clean_episodes.mat' %clean from ED, channel 28, Patient 3
};

% Check functions
missingFunctions = {};
for i = 1:length(requiredFunctions)
    if isempty(which(requiredFunctions{i}))
        missingFunctions{end+1} = requiredFunctions{i};
    end
end

% Check data files
missingDataFiles = {};
for i = 1:length(requiredDataFiles)
    if ~exist(requiredDataFiles{i}, 'file')
        missingDataFiles{end+1} = requiredDataFiles{i};
    end
end

% Report status
if isempty(missingFunctions) && isempty(missingDataFiles)
    fprintf('All dependencies found:\n');
    fprintf('- %d required functions\n', length(requiredFunctions));
    fprintf('- %d data files\n', length(requiredDataFiles));
else
    if ~isempty(missingFunctions)
        fprintf('Missing functions:\n');
        fprintf('%s\n', missingFunctions{:});
    end
    if ~isempty(missingDataFiles)
        fprintf('Missing data files:\n');
        fprintf('%s\n', missingDataFiles{:});
    end
    error('Missing required dependencies');
end
%% Detailed documentation and directions are included in every step.
A_exploration

B_select_episodes
%% 
% Comment the specified lines, if you want to plot all the episodes 
% or manually select the EDs
C_ED_Exclusion_plot_grouped_tseries
%%
D_split3_acf_pacf_RQ1
E_grid_search_ARMA_degrees_RQ2 %( quick_arma_check.m for faster search)
F_nrmse_opt_models_RQ3
G_nrmse_all_selected_linear
S_stat_test_lin_nonlin % (mats_nrmse_prep, stat_tests_linear_nrmse)