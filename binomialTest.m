%% =========================================================
% BIMODALITY ANALYSIS OF NEURAL CORRELATIONS
% =========================================================
% This section assumes the following variables already exist:
%   r_obs      : observed pre/post CoM correlations
%   r_null_med : per-event shuffled median
%   delta      : paired difference (r_obs - r_null_med)
% =========================================================

fprintf('\n========================================\n');
fprintf('BIMODALITY ANALYSIS\n');
fprintf('========================================\n');

%% -------- CLEAN DATA --------
r_obs_clean = r_obs(isfinite(r_obs));
delta_clean = delta(isfinite(delta));

Nobs   = numel(r_obs_clean);
Ndelta = numel(delta_clean);

fprintf('Number of CoM events (observed) = %d\n', Nobs);
fprintf('Number of CoM events (delta)    = %d\n\n', Ndelta);

%% =========================================================
% 1) HARTIGAN DIP TEST (UNIMODALITY)
%% =========================================================
% Requires hartigansdiptest.m on MATLAB path

try
    [dip_obs, p_dip_obs] = hartigansdiptest(r_obs_clean);
    [dip_del, p_dip_del] = hartigansdiptest(delta_clean);

    fprintf('Hartigan Dip Test (Observed r):\n');
    fprintf('  Dip statistic = %.4f\n', dip_obs);
    fprintf('  p-value       = %.4g\n\n', p_dip_obs);

    fprintf('Hartigan Dip Test (Delta r):\n');
    fprintf('  Dip statistic = %.4f\n', dip_del);
    fprintf('  p-value       = %.4g\n\n', p_dip_del);

catch
    warning('hartigansdiptest not found. Skipping Dip test.');
end

%% =========================================================
% 2) GAUSSIAN MIXTURE MODEL (1 vs 2 COMPONENTS)
%% =========================================================
opts = statset('MaxIter',1000);

% ----- Observed correlations -----
gm1_obs = fitgmdist(r_obs_clean,1,'Options',opts,'RegularizationValue',1e-6);
gm2_obs = fitgmdist(r_obs_clean,2,'Options',opts,'RegularizationValue',1e-6);

fprintf('GMM BIC comparison (Observed r):\n');
fprintf('  BIC (1 component) = %.1f\n', gm1_obs.BIC);
fprintf('  BIC (2 components)= %.1f\n', gm2_obs.BIC);

if gm2_obs.BIC < gm1_obs.BIC - 10
    fprintf('  → Strong evidence for bimodality (Observed)\n\n');
else
    fprintf('  → Unimodal model sufficient (Observed)\n\n');
end

% ----- Paired differences -----
gm1_del = fitgmdist(delta_clean,1,'Options',opts,'RegularizationValue',1e-6);
gm2_del = fitgmdist(delta_clean,2,'Options',opts,'RegularizationValue',1e-6);

fprintf('GMM BIC comparison (Delta r):\n');
fprintf('  BIC (1 component) = %.1f\n', gm1_del.BIC);
fprintf('  BIC (2 components)= %.1f\n', gm2_del.BIC);

if gm2_del.BIC < gm1_del.BIC - 10
    fprintf('  → Strong evidence for bimodality (Delta)\n');
else
    fprintf('  → Unimodal model sufficient (Delta)\n');
end

fprintf('========================================\n');
