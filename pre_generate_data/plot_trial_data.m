%% Plot Trial Data: Visualize Eel Competencies and Reliabilities
clear; close all; clc;

%% User Settings
trial_start = 1;     % First trial to plot
trial_end = 330;     % Last trial to plot

%% Setup Paths
currentFolder = pwd;
data_directory = fullfile(currentFolder, 'pre_generate_data', 'data', 'Copy_of_premade_trials');

if ~exist(data_directory, 'dir')
    error('Trial data directory not found: %s', data_directory);
end

% Get list of all trial files
trial_files = dir(fullfile(data_directory, 'trial_*.mat'));
N_trials = length(trial_files);

if N_trials == 0
    error('No trial files found in directory: %s', data_directory);
end

% Validate and adjust trial range
trial_end = min(trial_end, N_trials);
trial_start = max(1, min(trial_start, trial_end));
plot_trials = trial_end - trial_start + 1;

fprintf('Loading trials %d to %d for plotting...\n', trial_start, trial_end);

%% Load and Process Trial Data
reliability_purple = zeros(1, plot_trials);
competency_purple  = zeros(1, plot_trials);
reliability_blue   = zeros(1, plot_trials);
competency_blue    = zeros(1, plot_trials);

for idx = 1:plot_trials
    trial_idx = idx + trial_start - 1;
    % Load trial data
    trial_path = fullfile(data_directory, trial_files(trial_idx).name);
    load(trial_path, 'curr_trial_data');
    
    % Extract purple eel data
    purple_idx = find(arrayfun(@(e) isequal(e.eel_col, [157, 0, 255]), curr_trial_data.eels));
    if ~isempty(purple_idx)
        reliability_purple(idx) = curr_trial_data.eels(purple_idx).reliability;
        competency_purple(idx)  = curr_trial_data.eels(purple_idx).competency;
    end

    % Extract blue eel data
    blue_idx = find(arrayfun(@(e) isequal(e.eel_col, [0, 0, 255]), curr_trial_data.eels));
    if ~isempty(blue_idx)
        reliability_blue(idx) = curr_trial_data.eels(blue_idx).reliability;
        competency_blue(idx)  = curr_trial_data.eels(blue_idx).competency;
    end
end

%% Create Plots
trials = trial_start:trial_end;

% Create comparison arrays (purple vs blue)
purple_higher_comp = competency_purple > competency_blue;
purple_higher_rel = reliability_purple > reliability_blue;

% Create single figure with subplots
figure('Position', [50, 50, 1500, 1200]);  % Made figure taller

% Plot Purple Eel (subplot 1)
subplot(4,2,1);  % Changed to 4x2 grid
yyaxis left;
plot(trials, reliability_purple, 'b-', 'LineWidth', 2);
ylim([0 0.45]);
xlabel('Trial');
ylabel('Reliability');
yyaxis right;
plot(trials, competency_purple, 'r-', 'LineWidth', 2);
ylim([0 1]);
ylabel('Competency');
title('Purple Eel Reliability and Competency');
grid on;

% Plot Blue Eel (subplot 2)
subplot(4,2,2);
yyaxis left;
plot(trials, reliability_blue, 'b-', 'LineWidth', 2);
ylim([0 0.45]);
xlabel('Trial');
ylabel('Reliability');
yyaxis right;
plot(trials, competency_blue, 'r-', 'LineWidth', 2);
ylim([0 1]);
ylabel('Competency');
title('Blue Eel Reliability and Competency');
grid on;

% Add comparison subplot (3)
subplot(4,2,3:4);
hold on;

% Create shaded areas for different advantage combinations
advantage_categories = zeros(plot_trials, 1);
for i = 1:plot_trials
    if purple_higher_comp(i) && purple_higher_rel(i)
        advantage_categories(i) = 3; % High comp, high rel
    elseif purple_higher_comp(i) && ~purple_higher_rel(i)
        advantage_categories(i) = 2; % High comp, low rel
    elseif ~purple_higher_comp(i) && purple_higher_rel(i)
        advantage_categories(i) = 1; % Low comp, high rel
    else
        advantage_categories(i) = 0; % Low comp, low rel
    end
end

% Plot colored regions
for i = 1:plot_trials
    trial_num = trials(i);
    if advantage_categories(i) == 3
        color = [0.2 0.8 0.2]; % Green for double advantage
    elseif advantage_categories(i) == 2
        color = [0.8 0.6 0.0]; % Orange for comp advantage only
    elseif advantage_categories(i) == 1
        color = [0.0 0.6 0.8]; % Cyan for rel advantage only
    else
        color = [0.8 0.0 0.0]; % Red for no advantage
    end
    rectangle('Position', [trial_num-0.5, 0, 1, 1], 'FaceColor', color, 'EdgeColor', 'none');
end

% Add legend patches
patch([0 0 0 0], [0 0 0 0], [0.2 0.8 0.2], 'EdgeColor', 'none', 'DisplayName', 'Purple: Higher Comp & Rel');
patch([0 0 0 0], [0 0 0 0], [0.8 0.6 0.0], 'EdgeColor', 'none', 'DisplayName', 'Purple: Higher Comp only');
patch([0 0 0 0], [0 0 0 0], [0.0 0.6 0.8], 'EdgeColor', 'none', 'DisplayName', 'Purple: Higher Rel only');
patch([0 0 0 0], [0 0 0 0], [0.8 0.0 0.0], 'EdgeColor', 'none', 'DisplayName', 'Purple: Lower Comp & Rel');

ylim([0 1]);
xlim([trial_start trial_end]);
set(gca, 'YTick', []);
legend('Location', 'eastoutside');
title('Purple Eel Advantage Regions (Compared to Blue)');
xlabel('Trial');

% Create numeric comparison plot (4)
subplot(4,2,5:6);
hold on;

% Competency difference (purple - blue)
comp_diff = competency_purple - competency_blue;
% Reliability difference (purple - blue)
rel_diff = reliability_purple - reliability_blue;

% Plot the differences
plot(trials, comp_diff, 'r-', 'LineWidth', 2, 'DisplayName', 'Competency Diff (P-B)');
plot(trials, rel_diff, 'b-', 'LineWidth', 2, 'DisplayName', 'Reliability Diff (P-B)');
plot(trials, zeros(size(trials)), 'k--', 'DisplayName', 'No Difference');

xlabel('Trial');
ylabel('Difference (Purple - Blue)');
title('Difference in Competency and Reliability (Purple - Blue)');
legend('Location', 'eastoutside');
grid on;
xlim([trial_start trial_end]);

% Add Heatmap (subplot 5)
subplot(4,2,7:8);

% Determine thresholds dynamically using purple eel data
reliability_threshold = mean(reliability_purple);
competency_threshold = mean(competency_purple);

% Create contingency table for heatmap
heatmap_matrix = zeros(2, 2);
for i = 1:plot_trials
    rel_idx = (reliability_purple(i) >= reliability_threshold) + 1;
    comp_idx = (competency_purple(i) >= competency_threshold) + 1;
    heatmap_matrix(rel_idx, comp_idx) = heatmap_matrix(rel_idx, comp_idx) + 1;
end

% Create heatmap
h = heatmap({'Low', 'High'}, {'Low', 'High'}, heatmap_matrix');
h.Title = 'Distribution of Purple Eel Trial Categories';
h.XLabel = 'Reliability';
h.YLabel = 'Competency';

% Print summary statistics for the selected range
fprintf('\nSummary Statistics (Trials %d-%d):\n', trial_start, trial_end);
fprintf('Purple Eel - Mean Competency: %.3f, Mean Reliability: %.3f\n', ...
    mean(competency_purple), mean(reliability_purple));
fprintf('Blue Eel - Mean Competency: %.3f, Mean Reliability: %.3f\n', ...
    mean(competency_blue), mean(reliability_blue));
fprintf('Competency Range - Purple: [%.3f, %.3f], Blue: [%.3f, %.3f]\n', ...
    min(competency_purple), max(competency_purple), ...
    min(competency_blue), max(competency_blue));
fprintf('Reliability Range - Purple: [%.3f, %.3f], Blue: [%.3f, %.3f]\n', ...
    min(reliability_purple), max(reliability_purple), ...
    min(reliability_blue), max(reliability_blue));