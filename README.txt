Run complete_workflow.m 
(check documentation there, then from the main functions and later the rest included)
GENERAL STANDALONE RUN

 STRUCTURE:
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
S_stat_test_lin_nonlin





Keep only data from Patient 3 (the A B C were working for more patients as well)
and important mat file is the nrmse_data_nonlinear as it has the extracted values from mats.
(created by 'mats_nrmse_prep' -> transforms the extracted data from MATS to our analysis here!!)

Results folder just contains the R script I made and that I was referring to.