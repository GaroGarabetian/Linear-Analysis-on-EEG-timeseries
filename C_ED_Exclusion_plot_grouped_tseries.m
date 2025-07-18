% ED detection from plots (sudden spikes - careful not to extract
%                           disturbances of brain activity, even though it is not related.)

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
% Call function for each Intensity -> Plots episodes with probable ED
plot_grouped_series(combined_P120, 'Episodes P120');
plot_grouped_series(combined_P180, 'Episodes P180');
plot_grouped_series(combined_P240, 'Episodes P240');

% comment next line to check the plots
close all;

%========= EXCLUDED EPISODES DUE TO EPILEPTIFORM DISCHARGE ===========

%% ----- UNCOMMENT this section for manual seletion of ED episodes -------
% Ask Expert to Enter ED Episodes (for expert input) 

% disp('Enter the episode numbers with ED (as a vector, e.g., [17 39])');
% excluded_P120 = input('Episodes with ED for P120: ');
% excluded_P180 = input('Episodes with ED for P180: ');
% excluded_P240 = input('Episodes with ED for P240: ');
% ====================================================================
%% Looking on plots and then picking the ED
excluded_P120 = [1,3,6, 17,18,9, 16,19,22,28];   
excluded_P180 = [3,8,17,29,20,25];      
excluded_P240 = [2,7,8,12,21];   
%% Remove the excluded episodes 
clean_P120 = combined_P120;
clean_P120(:, excluded_P120) = [];

clean_P180 = combined_P180;
clean_P180(:, excluded_P180) = [];

clean_P240 = combined_P240;
clean_P240(:, excluded_P240) = [];

%  Plot the clean episodes 
plot_grouped_series(clean_P120, 'Clean Episodes P120');
plot_grouped_series(clean_P180, 'Clean Episodes P180');
plot_grouped_series(clean_P240, 'Clean Episodes P240');
% comment next line to verify the episodes (extracted parasites)
 close all
%% Display sizes
fprintf('Cleaned size for P_120: %dx%d\n', size(clean_P120,1), size(clean_P120,2));
fprintf('Cleaned size for P_180: %dx%d\n', size(clean_P180,1), size(clean_P180,2));
fprintf('Cleaned size for P_240: %dx%d\n', size(clean_P240,1), size(clean_P240,2));
%% ---------- BALANCE BETWEEN THE INTENSITIES ---------
% Calling the function to balance out the sizes of the episodes in
% different intensities with regard to the smallest, we omit randomly some
% episodes from the intesities with more episodes.

% Get the number of episodes in each clean set
n120 = size(clean_P120, 2);
n180 = size(clean_P180, 2);
n240 = size(clean_P240, 2);

% Find the minimum count
min_count = min([n120, n180, n240]); %keeping 20 episodes for each intesity

% Set a seed for reproducibility
rng(28);  
%% Need to keep the original indeces as well!
% Get original episode indices after ED removal
original_idx_P120 = setdiff(1:size(combined_P120, 2), excluded_P120);
original_idx_P180 = setdiff(1:size(combined_P180, 2), excluded_P180);
original_idx_P240 = setdiff(1:size(combined_P240, 2), excluded_P240);

% Randomly select min_count columns from each cleaned set
rand_idx120 = randperm(length(original_idx_P120), min_count);
rand_idx180 = randperm(length(original_idx_P180), min_count);
rand_idx240 = randperm(length(original_idx_P240), min_count);

% Map back to original episode indices
kept_idx_P120 = original_idx_P120(rand_idx120);
kept_idx_P180 = original_idx_P180(rand_idx180);
kept_idx_P240 = original_idx_P240(rand_idx240);

% Subset the actual data
balanced_P120 = combined_P120(:, kept_idx_P120);
balanced_P180 = combined_P180(:, kept_idx_P180);
balanced_P240 = combined_P240(:, kept_idx_P240);

% % Randomly select min_count columns from each
% idx120 = randperm(n120, min_count);
% idx180 = randperm(n180, min_count);
% idx240 = randperm(n240, min_count);
%
% % Subset the data
% balanced_P120 = clean_P120(:, idx120);
% balanced_P180 = clean_P180(:, idx180);
% balanced_P240 = clean_P240(:, idx240);
%
% Display final sizes
fprintf('\nBalanced data size: %d episodes per intensity\n', min_count);
fprintf('Size of balanced_P120: %dx%d\n', size(balanced_P120));
fprintf('Size of balanced_P180: %dx%d\n', size(balanced_P180));
fprintf('Size of balanced_P240: %dx%d\n', size(balanced_P240));
%% Save balanced datasets
save('balanced_clean_episodes.mat', 'balanced_P120', 'balanced_P180', 'balanced_P240');
fprintf('Balanced datasets saved to balanced_clean_episodes.mat\n');
fprintf('Total Cleaned and Balanced Episodes from all intensities:  %d \n',size(balanced_P120,2)+size(balanced_P180,2)+size(balanced_P240,2));
%%
disp('Original episode indices kept (P120):'); disp(kept_idx_P120);
disp('Original episode indices kept (P180):'); disp(kept_idx_P180);
disp('Original episode indices kept (P240):'); disp(kept_idx_P240);

% Save for reference
save('kept_episode_indices.mat', 'kept_idx_P120', 'kept_idx_P180', 'kept_idx_P240');



% Improvement
% NOT Eyeballing the ED cases (extreme sudden behavior after TMS) 
% 
%  Find a method to generalise finding ED or expert advice!
% Check ED bibliography