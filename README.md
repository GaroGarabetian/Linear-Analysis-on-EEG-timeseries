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

**Note on data:**  
Only data from **Patient 3** are retained. Steps A, B, and C were originally designed to handle multiple patients, but here only Patient 3 is used.  

**Important MAT file:**  
`nrmse_data_nonlinear.mat` – contains the extracted values from the MATS analysis, created by `mats_nrmse_prep.m` to transform the MATS output into the format needed for this workflow.  

**Results folder:**  
Contains the R script I made for further analysis.
