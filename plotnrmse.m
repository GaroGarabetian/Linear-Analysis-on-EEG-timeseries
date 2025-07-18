function plotnrmse(nrmseM,legtxtM)
% plotnrmse(nrmseM,legtxtM)
% PLOTNRMSE plots the NRMSE(T) for a range of prediction times T and 
% for a number of models
% INPUTS:
%  nrmseM  : the matrix of size Tmax x q of NRMSE for prediction times
%            T=1...Tmax and q different models 
%  legtxtM : a string matrix of the legends for each prediction model at 
%            the column order in 'nrmseM'.
%      legtxtM  : Cell array of legend labels, one for each signal (length q)

[Tmax, q] = size(nrmseM);
TV = (1:Tmax)';

% Use distinguishable colors
colors = lines(q);  % Default color set
hold on;

% Preallocate line handles for legend
lineHandles = gobjects(q, 1);

for i = 1:q
    % Plot solid line and get handle
    lineHandles(i) = plot(TV, nrmseM(:,i), '-', ...
        'Color', colors(i,:), 'LineWidth', 1.5);
    
    % Add corresponding dots (visual only, not in legend)
    plot(TV, nrmseM(:,i), '.', ... %'o'
        'Color', colors(i,:), 'MarkerSize', 10);
end

% Add legend based on lines only
legend(lineHandles, legtxtM, 'Location', 'best', 'Interpreter', 'latex');

% Labels and title
xlabel('Prediction Horizon $T$', 'Interpreter', 'latex');
ylabel('NRMSE$(T)$', 'Interpreter', 'latex');
title('NRMSE vs Prediction Horizon', 'Interpreter', 'latex');

% Aesthetics
grid on;
box on;
%ylim padded;  
 ylim([min(nrmseM(:)) - 0.01, max(nrmseM(:)) + 0.01]);  % Zoom to data range

%set(gca, 'FontSize', 12);
set(gcf, 'Position', [100, 100, 800, 500]); % Resize figure
set(gca, 'TickLabelInterpreter', 'latex'); % LaTeX ticks too
