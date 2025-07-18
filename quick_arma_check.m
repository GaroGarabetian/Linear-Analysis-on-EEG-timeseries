%% Used as a sumplementary to E_grid_search_ARMA_degrees_RQ2
% Plots for the report and quicker check the orders
% Includes seperate individual check for strange cases
% Run section
clear;
load('pre_post_episodes.mat')
% Grid search parameters
max_p = 6;
max_q = 6;
tmax = 30;
alpha = 0.05;

% Each cell contains [pre_segment, post_segment]
all_signals = {
    P120_pre,   P120_post;
    P180_pre,   P180_post;
    P240_pre,   P240_post;
};
intensities = [120, 180, 240];


% At the start of the outer loop (per intensity)
for sig_i = 1:size(all_signals,1)
    intensity_label = sprintf('%d', intensities(sig_i));

    % Initialize matrices to hold results for both segments
    whiteness_all = NaN(max_p+1, max_q+1, 2);  % 3D: p, q, segment
    aic_all = NaN(max_p+1, max_q+1, 2);

    for seg_i = 1:2
        x_seg = all_signals{sig_i, seg_i};
        seg_label = 'Pre'; 
        if seg_i == 2, seg_label = 'Post'; end

        fprintf('\nGrid Search ARMA(p,q) for Intensity %s %s segment...\n', intensity_label, seg_label);

        whiteness_matrix = NaN(max_p+1, max_q+1);
        aic_matrix = NaN(max_p+1, max_q+1);

        for p = 0:max_p
            for q = 0:max_q
                try
                    [~, ~, ~, ~, aic, ~, ~, xpreM] = fitARMA(x_seg, p, q, 1);
                    residuals = x_seg - xpreM(:,1);
                    [hV, ~, ~, ~] = portmanteauLB(residuals, tmax, alpha, '');
                    whiteness_matrix(p+1, q+1) = sum(hV);
                    aic_matrix(p+1, q+1) = aic;
                catch
                    fprintf('  Skipped ARMA(%d,%d) due to error.\n', p, q);
                end
            end
        end

        % Store results in the combined matrices
        whiteness_all(:,:,seg_i) = whiteness_matrix;
        aic_all(:,:,seg_i) = aic_matrix;
    end

    % Now plot Ljung-Box for both segments on same figure
    figure; hold on;
    colors = lines(max_q+1);
    markers = {'-o', '--s'}; % solid for Pre, dashed for Post

    for seg_i = 1:2
        seg_label = 'Pre'; if seg_i == 2, seg_label = 'Post'; end
        for q = 0:max_q
            plot(0:max_p, whiteness_all(:,q+1,seg_i), ...
                markers{seg_i}, 'Color', colors(q+1,:), ...
                'DisplayName', sprintf('%s segment, q = %d', seg_label, q));
        end
    end

    yline(round(0.1 * tmax), '--r', 'Max Acceptable Rejections');

    % Highlight best (p,q) from both segments combined 
    [minVal, minIdx] = min(whiteness_all(:));
    [best_p, best_q, best_seg] = ind2sub(size(whiteness_all), minIdx);
    best_p = best_p - 1; best_q = best_q - 1;

    plot(best_p, minVal, 'kp', 'MarkerSize', 12, 'MarkerFaceColor', 'k', ...
        'DisplayName', sprintf('Best (min rejections) %s', ...
        ternary(best_seg==1,'Pre','Post')));

    xlabel('AR order (p)');
    ylabel(sprintf('Rejected Ljung-Box lags (tmax = %d)', tmax));
    title(sprintf('Grid Search Ljung-Box Residual Test\nIntensity %s', intensity_label));
    legend show; grid on;

    % Plot AIC similarly
    figure; hold on;
    for seg_i = 1:2
        seg_label = 'Pre'; if seg_i == 2, seg_label = 'Post'; end
        for q = 0:max_q
            plot(0:max_p, aic_all(:,q+1,seg_i), ...
                markers{seg_i}, 'Color', colors(q+1,:), ...
                'DisplayName', sprintf('%s segment, q = %d', seg_label, q));
        end
    end

    [minAIC, minAICIdx] = min(aic_all(:));
    [aic_p, aic_q, aic_seg] = ind2sub(size(aic_all), minAICIdx);
    aic_p = aic_p - 1; aic_q = aic_q - 1;

    plot(aic_p, minAIC, 'kp', 'MarkerSize', 12, 'MarkerFaceColor', 'k', ...
        'DisplayName', sprintf('Best AIC %s', ternary(aic_seg==1,'Pre','Post')));

    xlabel('AR order (p)');
    ylabel('AIC');
    title(sprintf('AIC Grid Search\nIntensity %s', intensity_label));
    legend show; grid on;
end

function out = ternary(cond, valTrue, valFalse)
    if cond
        out = valTrue;
    else
        out = valFalse;
    end
end



% %% - Individual test using Econometrics Toolbox
% %load('pre_post_episodes.mat')
% autocorr(P240_pre);
% partialcorr(P240_pre);
% %%
% %data = P240_pre;
% data = P120_pre;
% % Different trials on difficult cases where min(aic) wise selection does
% % not provide robustness on the whiteness of the residuals
% 
% model = arima(4, 1, 4);  % for P240_pre -> AR(4)  d=0, q= 0
% fit = estimate(model, data);
% 
% % Show model
% disp(fit);
% 
% % Prediction / Residuals
% res = infer(fit, data);
% 
% % Test for white noise on residuals using ACF
% autocorr(res);  % ACF των υπολοίπων
% 
% %% caution on overfitting
% % Calculate and display the residuals
% figure;
% plot(res);
% xlabel('Time');
% ylabel('Residuals');
% title('Residuals from AR(4) Model Fit - P120 Pre TMS');
% grid on;
% 
% %%
% % === Set time series ===
% data = P120_pre;
% 
% % === Define search grid ===
% max_p = 7;
% max_d = 0;  % 0 or 1, avoid overdifferencing
% max_q = 7;
% 
% % === Preallocate result containers ===
% results = [];
% tmax = 40; % or 60/70 depending on your need
% alpha = 0.05;
% 
% fprintf('Grid Search ARIMA(p,d,q) on P240_pre...\n');
% 
% for p = 0:max_p
%     for d = 0:max_d
%         for q = 0:max_q
%             try
%                 model = arima(p, d, q);
%                 fit = estimate(model, data, 'Display', 'off');
% 
%                 % Compute residuals
%                 res = infer(fit, data);
% 
%                 % Check whiteness via Ljung-Box
%                 [h, ~] = lbqtest(res, 'Lags', tmax, 'Alpha', alpha);
% 
%                 % Store: [p d q AIC h]
%                 results(end+1, :) = [p, d, q, aicbic(fit.LogLikelihood, p+q+1), h];
% 
%                 fprintf('ARIMA(%d,%d,%d): AIC = %.2f | White? %s\n', ...
%                     p, d, q, results(end,4), ternary(~h, 'Yes', 'No'));
%             catch ME
%                 fprintf('Failed ARIMA(%d,%d,%d): %s\n', p, d, q, ME.message);
%             end
%         end
%     end
% end
% 
% % === Show best models (sorted by AIC) ===
% [~, idx] = sort(results(:,4)); % sort by AIC
% best_models = results(idx, :);
% disp('Top ARIMA models (lowest AIC first):');
% disp(array2table(best_models(1:10,:), ...
%     'VariableNames', {'p', 'd', 'q', 'AIC', 'WhiteNoisePassed'}));
