% ED detection from plots (sudden spikes - careful not to extract
%                           disturbances of brain activity)

% Call function for each Intensity -> Plots episodes with probable ED
plot_grouped_series(combined_P120, 'Episodes P120');
plot_grouped_series(combined_P180, 'Episodes P180');
plot_grouped_series(combined_P240, 'Episodes P240');

% EXCLUDED EPISODES DUE TO EPILEPTIFORM DISCHARGE
%%
% ----- UNCOMMENT this section for manual seletion of ED episodes -------
% === Ask Expert to Enter ED Episodes (for expert input) ===

% disp('Enter the episode numbers with ED (as a vector, e.g., [1 3 5])');
% excluded_P120 = input('Episodes with ED for P120: ');
% excluded_P180 = input('Episodes with ED for P180: ');
% excluded_P240 = input('Episodes with ED for P240: ');
% ====================================================================
%%
% Looking on plots and then picking the ED
excluded_P120 = [];   
excluded_P180 = [];      
excluded_P240 = [];   

% === Remove the excluded episodes ===
clean_P120 = combined_P120;
clean_P120(:, excluded_P120) = [];

clean_P180 = combined_P180;
clean_P180(:, excluded_P180) = [];

clean_P240 = combined_P240;
clean_P240(:, excluded_P240) = [];

% === Plot the clean episodes ===
plot_grouped_series(clean_P120, 'Clean Episodes P120');
plot_grouped_series(clean_P180, 'Clean Episodes P180');
plot_grouped_series(clean_P240, 'Clean Episodes P240');







% Function to plot time series in groups of 6 subplots vertically
function plot_grouped_series(data, label)
    numCols = size(data, 2);
    plotsPerFigure = 6;

    for i = 1:plotsPerFigure:numCols
        figure;
        for j = 0:min(plotsPerFigure - 1, numCols - i)
            subplot(plotsPerFigure, 1, j + 1);  % 6 rows, 1 column
            plot(data(:, i + j));
            title(sprintf('%s - Episode %d', label, i + j));
            xlabel('Time (samples)');
            ylabel('Amplitude');
            hold on;
            xline(1451, '--r');% TMS shot
        end
    end
end




% Improvement
% NOT Eyeballing the ED cases (extreme sudden behavior after TMS) might
% take away cases of brain dysfunction
%  Find a method to generalise finding ED or expert advice!
% ED bibliography