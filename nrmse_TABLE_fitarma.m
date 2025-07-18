% Επιλογή χρονικού βήματος πρόβλεψης
T_selected = 10;

% Προετοιμασία πίνακα NRMSE
NRMSE_Table = table('Size', [0 5], ...
    'VariableTypes', {'string', 'string', 'double', 'double', 'double'}, ...
    'VariableNames', {'Intensity', 'Segment', 'AR_Order', 'MA_Order', 'NRMSE'});

% === Loop through all segments ===
for sig_i = 1:size(all_signals,1)
    for seg_i = 1:2
        x_seg = all_signals{sig_i, seg_i};
        seg_label = 'Pre'; if seg_i == 2, seg_label = 'Post'; end
        intensity_label = sprintf('%d', intensities(sig_i));
        n = length(x_seg);

        % Initialize results
        aic_matrix = NaN(max_p+1, max_q+1);
        ljung_matrix = NaN(max_p+1, max_q+1);
        best_nrmse = NaN;

        for p = 2:max_p
            for q = 2:max_q
                try
                    [nrmseV, ~, ~, ~, aicS, ~, ~, xpreM] = fitARMA(x_seg, p, q, T_selected);
                    residuals = x_seg - xpreM(:,T_selected);
                    [hV, ~, ~, ~] = portmanteauLB(residuals, tmax, alpha, '');
                    aic_matrix(p+1, q+1) = aicS;
                    ljung_matrix(p+1, q+1) = sum(hV);

                    % Καταγραφή NRMSE για το T-selected βήμα
                    if ~isnan(nrmseV(T_selected)) && (isnan(best_nrmse) || nrmseV(T_selected) < best_nrmse)
                        best_nrmse = nrmseV(T_selected);
                        best_p = p;
                        best_q = q;
                    end
                catch
                    % Skip on error
                end
            end
        end

        % Εισαγωγή στη δομή πίνακα
        NRMSE_Table = [NRMSE_Table; {
            intensity_label, seg_label, best_p, best_q, best_nrmse
        }];
    end
end

% === Εμφάνιση πίνακα NRMSE ===
fprintf('>> NRMSE Table (T = %d step prediction)\n', T_selected);
disp(NRMSE_Table);
