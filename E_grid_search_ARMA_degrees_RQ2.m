%%=== GRID SEARCH ARMA(p,q) for the 6 timeseries (RQ2) ====

% Use of AIC for the orders and for diagnostic check Ljung-Box (residuals test for white noise)
% Make sure you have portmanteauLB.m Ljung Box

% INPUT:
%      - 6 timeseries pre and post TMS among 3 intesities
% OUTPUT:
%      - Plots based on the grid search for ARMA using AIC and Ljung-Box
%      - Check console for the decisions, saves

load('pre_post_episodes.mat')

% Grid search parameters
max_p = 6;
max_q = 6;
tmax = 30; % for the portmanteau test ljung -Box (documented as thesize parameter)
alpha = 0.05;

% Each cell contains [pre_segment, post_segment]
all_signals = {
    P120_pre,   P120_post;
    P180_pre,   P180_post;
    P240_pre,   P240_post;
};
intensities = [120, 180, 240];
% Initialize struct to save best models
best_models = struct();

for sig_i = 1:size(all_signals,1)
    intensity_label = sprintf('%d', intensities(sig_i));
    for seg_i = 1:2
        x_seg = all_signals{sig_i, seg_i};
        seg_label = 'Pre'; 
        if seg_i == 2, seg_label = 'Post'; end

        fprintf('\nGrid Search ARMA(p,q) for Intensity %s %s segment...\n', intensity_label, seg_label);

        % Initialize result matrices
        whiteness_matrix = NaN(max_p+1, max_q+1);  % Ljung-Box rejection count
        aic_matrix = NaN(max_p+1, max_q+1);        % AIC values

        for p = 0:max_p
            for q = 0:max_q
                try
                    % Fit ARMA model
                    [~, ~, ~, ~, aic, ~, ~, xpreM] = fitARMA(x_seg, p, q, 1);

                    % Residuals
                    residuals = x_seg - xpreM(:,1);

                    % Ljung-Box test
                    [hV, ~, ~, ~] = portmanteauLB(residuals, tmax, alpha, '');
                    whiteness_matrix(p+1, q+1) = sum(hV);  % rejections
                    aic_matrix(p+1, q+1) = aic;
                catch
                    fprintf('  Skipped ARMA(%d,%d) due to error.\n', p, q);
                end
            end
        end

        % Plot Ljung-Box Results
        figure; hold on;
        colors = lines(max_q+1);
        for q = 0:max_q
            plot(0:max_p, whiteness_matrix(:,q+1), '-o', ...
                'DisplayName', sprintf('q = %d', q), ...
                'Color', colors(q+1,:));
        end
        yline(round(0.1 * tmax), '--r', 'Max Acceptable Rejections');

        % Highlight best (p,q) by Ljung-Box
        [minVal, minIdx] = min(whiteness_matrix(:));
        [best_p, best_q] = ind2sub(size(whiteness_matrix), minIdx);
        best_p = best_p - 1; best_q = best_q - 1;

        plot(best_p, minVal, 'kp', 'MarkerSize', 10, ...
            'DisplayName', 'Best (min rejections)');

        xlabel('AR order (p)');
        ylabel(sprintf('Rejected Ljung-Box lags (tmax = %d)', tmax));
        title(sprintf('Grid Search ARMA(p,q) Ljung-Box Residual Test\nIntensity %s %s', intensity_label, seg_label));
        legend show; grid on;

        % Plot AIC
        figure; hold on;
        for q = 0:max_q
            plot(0:max_p, aic_matrix(:,q+1), '-o', ...
                'DisplayName', sprintf('q = %d', q), ...
                'Color', colors(q+1,:));
        end

        % Mark best AIC
        [minAIC, minAICIdx] = min(aic_matrix(:));
        [aic_p, aic_q] = ind2sub(size(aic_matrix), minAICIdx);
        aic_p = aic_p - 1; aic_q = aic_q - 1;

        plot(aic_p, minAIC, 'kp', 'MarkerSize', 10, ...
            'DisplayName', 'Best AIC');

        xlabel('AR order (p)');
        ylabel('AIC');
        title(sprintf('AIC Grid Search ARMA(p,q) \nIntensity %s %s', intensity_label, seg_label));
        legend show; grid on;

        % === Save best model info to struct ===
        best_models(sig_i).intensity = intensity_label;
        best_models(sig_i).segment(seg_i).name = seg_label;

        best_models(sig_i).segment(seg_i).best_p_LB = best_p;
        best_models(sig_i).segment(seg_i).best_q_LB = best_q;
        best_models(sig_i).segment(seg_i).minVal_LB = minVal;

        best_models(sig_i).segment(seg_i).best_p_AIC = aic_p;
        best_models(sig_i).segment(seg_i).best_q_AIC = aic_q;
        best_models(sig_i).segment(seg_i).minVal_AIC = minAIC;
    end
end

% Example of accessing the saved best models
fprintf('\nBest ARMA models summary with tmax = %d:\n', tmax);
for i = 1:length(best_models)
    fprintf('Intensity %s:\n', best_models(i).intensity);
    for s = 1:length(best_models(i).segment)
        fprintf('  Segment %s - Best by Ljung-Box: AR(%d), MA(%d), Rejections: %d\n', ...
            best_models(i).segment(s).name, ...
            best_models(i).segment(s).best_p_LB, ...
            best_models(i).segment(s).best_q_LB, ...
            best_models(i).segment(s).minVal_LB);
        fprintf('  Segment %s - Best by AIC: AR(%d), MA(%d), AIC: %.2f\n', ...
            best_models(i).segment(s).name, ...
            best_models(i).segment(s).best_p_AIC, ...
            best_models(i).segment(s).best_q_AIC, ...
            best_models(i).segment(s).minVal_AIC);
    end
end



%%%------ DECISION OF ARMA(p,q) models for the 6 timeseries -------
% Decision based on the best ARMA(p,q) models AIC wise plots and
%   diagnostic test:  Ljung Box Test (residuals being white noise) ->
%   appropriate model was selected on the combination of the two with
%   careful selection both AR part to be stationary and MA revertible.
% ------- HYPOTHESIS: TIMESERIES ALREADY STATIONARY
% % (found exceptions in other trials, that's why I included in the end the arima checks )
%Best ARMA models summary with tmax = 60:
%Intensity 120:
 % Segment Pre - Best by Ljung-Box: AR(5), MA(3), Rejections: 0
 % Segment Pre - Best by AIC: AR(5), MA(4), AIC: -9.06
 % Segment Post - Best by Ljung-Box: AR(4), MA(2), Rejections: 0
 % Segment Post - Best by AIC: AR(5), MA(5), AIC: -7.23
%Intensity 180:
 % Segment Pre - Best by Ljung-Box: AR(5), MA(0), Rejections: 0
 % Segment Pre - Best by AIC: AR(5), MA(4), AIC: -7.24
 % Segment Post - Best by Ljung-Box: AR(5), MA(4), Rejections: 10
 % Segment Post - Best by AIC: AR(5), MA(4), AIC: -10.40
%Intensity 240:
  %Segment Pre - Best by Ljung-Box: AR(5), MA(5), Rejections: 58
  %Segment Pre - Best by AIC: AR(5), MA(5), AIC: -10.73
  %Segment Post - Best by Ljung-Box: AR(4), MA(2), Rejections: 0
  %Segment Post - Best by AIC: AR(5), MA(4), AIC: -6.28

%%
% ==== Assign best ARMA(p,q) orders manually for each segment ==== %
% checking plots using AIC and Ljung Box 
% try to match best cases for the criterions and simple as possible model..
% Format: ARMA[p, q]
% CRITERIONS: MINIMUM AIC, SIMPLICITY ON ORDERS, LJUNG BOX
model_orders = struct(...
    'P120_pre',  [4, 5], ... %
    'P120_post', [4, 5], ... %
    'P180_pre',  [3, 5], ... %
    'P180_post', [6, 6], ... % 5,4 -10/30rej-------->6,6
    'P240_pre',  [6, 4], ... % PROBLEMATIC - 5CHECKED AGAIN INDIVIDUALY, diagnostic test 6,4 ~passed -------
    'P240_post', [4, 2] ... % 
);

% ==== Fit models using assigned orders ====%

% Store results in a structure for easy access later
fitted_models = struct();

% Loop through each field (timeseries name)
fields = fieldnames(model_orders);
for i = 1:numel(fields)
    ts_name = fields{i};               % E.g., 'P120_pre'
    pq = model_orders.(ts_name);       % [p, q]
    p = pq(1); q = pq(2);

    % Evaluate variable name to get the data (e.g., P120_pre)
    ts_data = eval(ts_name);

    try
        [~, ~, ~, ~, aic, ~, model, ~] = fitARMA(ts_data, p, q, 1);
        fitted_models.(ts_name) = struct( ...
            'p', p, ...
            'q', q, ...
            'aic', aic, ...
            'model', model ...
        );
        fprintf('Fitted ARMA(%d,%d) to %s | AIC = %.2f\n', p, q, ts_name, aic);
    catch ME
        warning('Failed to fit ARMA(%d,%d) to %s: %s', p, q, ts_name, ME.message);
    end
end
%%
% ==== Residual Diagnostic: Ljung-Box for Preferred ARMA Models ====

% Parameters
tmax_diag = 30;  % Can be different from the grid search
alpha_diag = 0.05;

fprintf('\n=== Residual Diagnostics: Ljung–Box Test ===\n');

for i = 1:numel(fields)
    ts_name = fields{i};
    pq = model_orders.(ts_name);  
    p = pq(1); q = pq(2);

    ts_data = eval(ts_name);  % Load original series
    model_struct = fitted_models.(ts_name);
    model = model_struct.model;

    % Predict 1-step-ahead
    [xpre, ~] = predict(model, ts_data);

    % Residuals
    residuals = ts_data - xpre;

    % Ljung–Box test using function
    [hVec, pVec, Qstat, critVal] = portmanteauLB(residuals, tmax_diag, alpha_diag, '');

    % Count rejected lags
    num_rejected = sum(hVec);
    
    % Store results
    fitted_models.(ts_name).ljung_rejected = num_rejected;
    fitted_models.(ts_name).ljung_pvals = pVec;

    % Print summary
    fprintf('ARMA(%d,%d) on %s | Ljung-Box: %d/%d lags rejected (α = %.2f)\n', ...
        p, q, ts_name, num_rejected, tmax_diag, alpha_diag);
end


%% separate quick checks
%{
data = P180_post;
%----data = P120_pre;
% Different trials on difficult cases where min(aic) wise selection does
% not provide robustness on the whiteness of the residuals

model = arima(5, 0, 5);  % for P240_pre -> AR(4)  d=0, q= 0
fit = estimate(model, data);

% Show model
disp(fit);

% Prediction / Residuals
res = infer(fit, data);

% Test for white noise on residuals using ACF
autocorr(res);  % ACF των υπολοίπων

%% ARIMA implementation and Econometrics Toolbox due to non stationarity on P240_pre(other episode)
% ==== Define ARIMA(p,d,q) orders manually for each segment ==== %
% Format: [p, d, q]
%model_orders = struct(...
%    'P120_pre',  [4, 0, 5], ...
%    'P120_post', [4, 0, 2], ...
%    'P180_pre',  [3, 0, 3], ...
%    'P180_post', [4, 0, 5], ... % 
%    'P240_pre',  [3, 0, 5], ...  % 
%    'P240_post', [4, 0, 2] ...
%);

% ==== Fit ARIMA models and test residuals ==== %
%fitted_models = struct();
%fields = fieldnames(model_orders);

%for i = 1:numel(fields)
 %   ts_name = fields{i};
  %  order = model_orders.(ts_name);  % [p, d, q]
   % p = order(1); d = order(2); q = order(3);

    %fprintf('\n--- Fitting ARIMA(%d,%d,%d) to %s ---\n', p, d, q, ts_name);

    % Get the time series
    %data = eval(ts_name);

    %try
        % Define model
     % model = arima(p, d, q);
      % Fit model
      % fit = estimate(model, data, 'Display', 'off');
       % Infer residuals
       % res = infer(fit, data);

        % Store result
      %  fitted_models.(ts_name) = struct( ...
       %     'model', fit, ...
       %     'residuals', res ...
       % );

        % Diagnostics: Residual ACF + Ljung-Box
        %figure('Name', ['Residual Diagnostics - ' ts_name]);
        %subplot(2,1,1);
        %autocorr(res, 'NumLags', 40);
        %title(['ACF of Residuals - ' ts_name]);

        %subplot(2,1,2);
        %[h, pVal] = lbqtest(res, 'Lags', 20);  % or change to 40, 60 if needed
        %stem(1:numel(pVal), pVal, 'filled');
        %yline(0.05, '--r', 'Significance Level 0.05');
        %xlabel('Lags'); ylabel('p-value');
        %title('Ljung-Box p-values for residuals');

        %fprintf('  Residuals Ljung-Box passed at lag 20: %s\n', ternary(~h, 'Yes', 'No'));
    %catch ME
     %   warning('Failed to fit ARIMA(%d,%d,%d) to %s: %s', p, d, q, ts_name, ME.message);
   % end
%end

% Helper ternary function --- if
%function out = ternary(cond, a, b)
  %  if cond
   %     out = a;
    %else
     %   out = b;
    %end%
%end
%}