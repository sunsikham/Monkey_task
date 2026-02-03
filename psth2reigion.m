%% =========================================================
% PRE vs POST CoM NEURAL BARCODE ANALYSIS
% =========================================================

clear; clc;

%% ===== PATHS =====
dataDir = '/Users/hasti/Desktop/Maze SK';

%% ===== REGIONS (NEW) =====
regions = {'RSC','OFC'};    %%% NEW

%% =========================================================
% LOOP OVER REGIONS (NEW)
%% =========================================================
for r = 1:numel(regions)

    region = regions{r};
    fprintf('\n==============================\n');
    fprintf('Running region: %s\n', region);
    fprintf('==============================\n');

    %% ===== LOAD DATA =====
    disp('Loading data...')

    tmp = load(fullfile(dataDir,'raw',['P_' region '.mat']));
    bhv  = tmp.bhv;
    psth = tmp.psth;

    load(fullfile(dataDir,'Trajectory','CoM_allDays_exceptDay1.mat'),'result')

    disp('Data loaded.')

    fprintf('bhv trials:  %d\n', numel(bhv))
    fprintf('psth trials: %d\n', numel(psth))
    fprintf('CoM trials:  %d\n', numel(result))

    %% ===== PARAMETERS =====
    dt_ms   = 20;          % <<< PSTH BIN SIZE
    win_ms  = 750;
    W       = round(win_ms / dt_ms);

    nShuffle = 1000;

    %% ===== STORAGE =====
    r_obs  = [];
    r_null = [];

    %% =========================================================
    % MAIN LOOP
    %% =========================================================
    for t = 1:numel(result)

        % skip non-CoM trials
        if result(t).total_CoM == 0
            continue
        end

        if t > numel(psth) || isempty(psth{t})
            continue
        end

        X = psth{t};   % [T x N]

        % ensure time x neurons
        if size(X,1) < size(X,2)
            X = X';
        end

        T = size(X,1);

        % loop through CoM events in this trial
        for k = 1:numel(result(t).CoM_revIdx)

            revIdx = result(t).CoM_revIdx(k);

            if isnan(revIdx)
                continue
            end

            % define PRE and POST windows
            pre_start  = revIdx - W;
            post_start = revIdx + 1;

            if pre_start < 1 || (post_start + W - 1) > T
                continue
            end

            % ===== BARCODE VECTORS =====
            v_pre  = mean(X(pre_start:pre_start+W-1,:), 1)';
            v_post = mean(X(post_start:post_start+W-1,:),1)';

            % observed correlation
            r_obs(end+1,1) = corr(v_pre, v_post, 'rows','complete');

            % ===== SHUFFLE NULL =====
            rS = nan(nShuffle,1);
            for s = 1:nShuffle
                v_post_s = v_post(randperm(numel(v_post)));
                rS(s) = corr(v_pre, v_post_s, 'rows','complete');
            end

            r_null(:,end+1) = rS;

        end
    end

    %% =========================================================
    % PAIRED OBSERVED vs SHUFFLED TEST (NONPARAMETRIC)
    %% =========================================================
    r_null_med = median(r_null, 1)';   % per-event null
    delta = r_obs - r_null_med;

    good = isfinite(delta);
    delta = delta(good);
    r_obs_g = r_obs(good);
    r_null_g = r_null_med(good);

    med_obs  = median(r_obs_g);
    med_null = median(r_null_g);
    med_diff = median(delta);

    [p_wil,~,~] = signrank(r_obs_g, r_null_g);
    [~,p_t] = ttest(r_obs_g, r_null_g);

    fprintf('\n===== %s RESULTS =====\n', region);
    fprintf('Median observed r  = %.3f\n', med_obs);
    fprintf('Median shuffled r  = %.3f\n', med_null);
    fprintf('Median difference  = %.3f\n', med_diff);
    fprintf('Wilcoxon p = %.3g\n', p_wil);
    fprintf('Paired t-test p (ref) = %.3g\n', p_t);

    %% =========================================================
    % PLOT (BIN SIZE INCREASED)
    %% =========================================================
    figure('Name',['Pre vs Post CoM - ' region]); hold on

    % ---- Shuffled histogram ----
    h_null = histogram(r_null(:), 20, ...   %%% BIN SIZE FIXED
        'Normalization','probability', ...
        'FaceColor',[0.75 0.75 0.75], ...
        'FaceAlpha',0.6, ...
        'EdgeColor','none');

    % ---- Observed histogram ----
    h_obs = histogram(r_obs, 20, ...        %%% BIN SIZE FIXED
        'Normalization','probability', ...
        'FaceColor',[0.85 0.2 0.2], ...
        'FaceAlpha',0.7, ...
        'EdgeColor','none');

    % ---- Median lines ----
    h_med_obs  = xline(med_obs,'r','LineWidth',3);
    h_med_null = xline(med_null,'k','LineWidth',3);

    uistack(h_med_obs,'top')
    uistack(h_med_null,'top')
    set(gca,'Layer','top')

    xlabel('Neural barcode correlation (r)')
    ylabel('Probability across CoM events')
    title(['Pre vs Post Change-of-Mind Neural Similarity (' region ')'])

    legend([h_null, h_obs, h_med_obs, h_med_null], ...
           {'Shuffled','Observed','Median observed','Median shuffled'}, ...
           'Location','northwest');

    set(gca,'FontSize',12)
    box off

end   %%% END REGION LOOP
