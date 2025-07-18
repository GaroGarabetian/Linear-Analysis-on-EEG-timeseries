%% ---------- NRMSE FOR 1:10 STEPS AHEAD from the 6 optimal ARMA[p,q] (RQ3) -------

% INPUT:
%     - 6 OPTIMAL ARMA MODELS per segment     
%     - time steps ahead (default: Tmax = 10)
%     - need of functions nrmse.m, predictARMAmultistep.m, plotnrmse.m

%  Train on 60% of segment and test on 40% of segment

% OUTPUT:
%  - plot NRMSE using optimal model for each signal till 10 time steps ahead
%  - create NRMSE matrix for time prediction horizon of 10 steps for the 6 timeseries


% Names of signals - remove later due to repetition
signals = {'P120_pre', 'P120_post', 'P180_pre', 'P180_post', 'P240_pre', 'P240_post'};

% Assigning optimal ARMA parameters (p,q) per segment
model_orders = struct(...
    'P120_pre',  [4, 5], ... %
    'P120_post', [4, 5], ... %
    'P180_pre',  [3, 5], ... %
    'P180_post', [6, 6], ... %--
    'P240_pre',  [6, 4], ... %--
    'P240_post', [4, 2] ... % 
);

% Time Steps Aheaad
Tmax = 10;
q = numel(signals);
nrmseM = zeros(Tmax, q);
legtxtM = {
    '$PreTMS_{120}$', ...
    '$PostTMS_{120}$', ...
    '$PreTMS_{180}$', ...
    '$PostTMS_{180}$', ...
    '$PreTMS_{240}$', ...
    '$PostTMS_{240}$'
};
%legtxtM = char(signals);%str2mat(signals{:});  Reminder: version:----2025a ----

% Calculation of NRMSE for every signal
for i = 1:q
    sig_name = signals{i};
    x = eval(sig_name);  % Takes data from workspace, no clear
    pq = model_orders.(sig_name);
    p = pq(1); qval = pq(2); % qval για να μην συγκρούεται με μέγεθος πίνακα q!!!!

    % Determine number of test points (40% of segment length)
    nlast = round(0.4 * length(x)); 

    % Call predictARMAnrmse for every signal
    [nrmseV, ~, ~, ~] = predictARMAnrmse(x, p, qval, Tmax, nlast, sig_name);
    % Check documentation
    % len(half-episode) = 1450, 
    %      -->       Train Set -> first 60% (0.6*1450 = 870samples),
    %      -->       Test Set -> last 40% (580samples)
    % save it on the matrix
    nrmseM(:, i) = nrmseV;
end

% Plots with appropriate legends(needs improvement)
%          FUNCTION plotnrmse.m adjusted to latex legends

fig = figure;
plotnrmse(nrmseM, legtxtM);
%% for latex use
%exportTikzFigure(fig,'NRMSE_plot')
%% Saving figure.png or .tikz
%saveas(gcf, 'figures/nrmse_prediction_horizon.png')

%if ~exist('figures', 'dir')
   % mkdir('figures')
%end

% addpath(genpath('matlab2tikz'));
%{
% Export to .tikz for LaTeX
matlab2tikz('/figures/NRMSE_plot.tikz', ...
    'width', '\textwidth', ...
    'height', '0.5\textwidth', ...
    'showInfo', false, ...
    'interpretTickLabelsAsTex', false, ...
    'extraAxisOptions', {'title style={font=\small}', ...
                         'label style={font=\small}', ...
                         'tick label style={font=\small}'} ...
   );
fprintf('Plot exported to NRMSE_plot.tikz for LaTeX use.\n');
%}

%% best works (make a function)
%{
addpath(genpath('matlab2tikz'));
% Define output directory and filename
outputFolder = fullfile(pwd, 'figures');
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder); % Create 'figures' folder if it doesn't exist
end

filename = fullfile(outputFolder, 'NRMSE_plot.tikz');

% Export figure to TikZ
legend('Location', 'northwest'); 
matlab2tikz(filename, ...
    'width', '0.9\textwidth', ...
    'height', '0.5\textwidth', ...
    'showInfo', false, ...
    'interpretTickLabelsAsTex', false, ...
    'extraAxisOptions', { ...
        'title style={font=\small}', ...
        'label style={font=\small}', ...
        'tick label style={font=\small}', ...
        'legend style={at={(0.05,0.75)}, anchor=west}' ...
    });

% Print location in console
fprintf('TikZ figure saved to: %s\n', filename);
%}
