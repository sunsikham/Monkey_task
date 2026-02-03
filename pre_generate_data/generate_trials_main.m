%% Main Script: Pre-Generate Trials with Eel Information and Plotting
clear; close all; clc;

%% 1) Setup Paths
currentFolder = fileparts(mfilename('fullpath'));
addpath(genpath(currentFolder));

save_directory = fullfile(currentFolder, 'data', 'premade_trials_new');
if ~exist(save_directory, 'dir')
    mkdir(save_directory);
end

%% 2) Define Game Options
game_opt = struct();

game_opt.competencies = [0.2, 0.8];

% Define the true identities by color:
game_opt.true_competency.blue   = game_opt.competencies(1);
game_opt.true_competency.purple = game_opt.competencies(2);
game_opt.true_reliability.blue   = 0.3;
game_opt.true_reliability.purple = 0.15;

game_opt.n_eels = 2;          % number of eels per trial
game_opt.n_fishes = 8;        % number of fish per trial
game_opt.electrical_field =200; % electrical field effect (example parameter)
game_opt.eel_sz = 30;         % eel size in pixels
game_opt.fish_init_min_r = game_opt.electrical_field - game_opt.eel_sz; % Minimum initialization distance (pixels)
game_opt.fish_init_max_r = game_opt.electrical_field + game_opt.eel_sz; % Maximum initialization distance (pixels)

% Noise level parameters for competency and reliability
game_opt.competency_noise_level = 0.02;
game_opt.reliability_noise_level = 0;


game_opt.n_big_noises = 1;          % Number of big noise samples to add per switch
game_opt.big_competency_bias = 0.2 ;  % Bias per noise sample (magnitude)
game_opt.big_competency_std = 0.09;   % Std deviation for each big noise sample

% old 17, 23
% old 8 11 
%% Switching Parameters
% Reliability switching parameters:
game_opt.reliability_offset = 2;   % starting offset (first 5 trials are swapped)
% Using uniform distribution between 18 to 23 for reliability switching
game_opt.min_rel_switch = 23;      % minimum switching interval
game_opt.max_rel_switch = 27;      % maximum switching interval

% Competency switching parameters:
game_opt.competency_switch_offset = 3;  % starting offset for competency switching
% Using uniform distribution between 7 to 10 for competency switching
game_opt.min_comp_switch = 15;      % minimum switching interval
game_opt.max_comp_switch = 20;     % maximum switching interval

N_trials = 350;         % total number of trials
game_opt.n_trials = N_trials;  % Add this line to define n_trials

%% 3) Define Visual Options
visual_opt = struct();
visual_opt.eel_colors = [0, 0, 255;      % Blue
    157, 0, 255];  % Purple
visual_opt.wHgt = 1080;         % window height (pixels)
visual_opt.wWth = 1920;         % window width (pixels)
visual_opt.eel_rnd_range = 50;  % range for randomizing eel positions
visual_opt.coordinate_window = 540; % vertical coordinate for avatar start (example)

%% 4) Generate Switching Schedules

% 4.1) Reliability Switching Schedule:
reliability_switch_trials = [];
current_trial = game_opt.reliability_offset;
while current_trial <= N_trials
    reliability_switch_trials(end+1) = round(current_trial);
    % Use uniform distribution for reliability switch interval
    interval = randi([game_opt.min_rel_switch, game_opt.max_rel_switch]);
    current_trial = current_trial + interval;
end
game_opt.reliability_switch_trials = reliability_switch_trials;

% 4.2) Competency Switching Schedule:
competency_switch_trials = [];
current_trial = game_opt.competency_switch_offset;
while current_trial <= N_trials
    competency_switch_trials(end+1) = round(current_trial);
    % Use uniform distribution for competency switch interval
    interval = randi([game_opt.min_comp_switch, game_opt.max_comp_switch]);
    current_trial = current_trial + interval;
end
game_opt.competency_switch_trials = competency_switch_trials;
% 4.3) Generate Random Big Noise Trials (separate for blue and purple eels)

% Initialize empty arrays for blue and purple eel big noise trials
game_opt.random_big_noise_trials_blue = [];
game_opt.random_big_noise_trials_purple = [];

for i = 1:length(game_opt.competency_switch_trials)
    if i < length(game_opt.competency_switch_trials)
        block_start = game_opt.competency_switch_trials(i);
        block_end = game_opt.competency_switch_trials(i+1) - 1;
    else
        block_start = game_opt.competency_switch_trials(i);
        block_end = game_opt.n_trials;
    end
    
    % Random big noise trials for blue eel
    blue_noise_trials = randi([block_start, block_end], [1, game_opt.n_big_noises]);
    game_opt.random_big_noise_trials_blue = [game_opt.random_big_noise_trials_blue, blue_noise_trials];
    
    % Random big noise trials for purple eel
    purple_noise_trials = randi([block_start, block_end], [1, game_opt.n_big_noises]);
    game_opt.random_big_noise_trials_purple = [game_opt.random_big_noise_trials_purple, purple_noise_trials];
end



%% 5) Generate and Save Trials and Record Data for Both Eels
reliability_purple = zeros(1, N_trials);
competency_purple  = zeros(1, N_trials);
reliability_blue   = zeros(1, N_trials);
competency_blue    = zeros(1, N_trials);

for trial_idx = 1:N_trials
    fprintf('Generating Trial %d/%d\n', trial_idx, N_trials);
    curr_trial_data = pre_generate_eels_info(visual_opt, game_opt, trial_idx);
    trial_filename = fullfile(save_directory, sprintf('trial_%03d.mat', trial_idx));
    save(trial_filename, 'curr_trial_data');

    purple_idx = find(arrayfun(@(e) isequal(e.eel_col, [157, 0, 255]), curr_trial_data.eels));
    if ~isempty(purple_idx)
        reliability_purple(trial_idx) = curr_trial_data.eels(purple_idx).reliability;
        competency_purple(trial_idx)  = curr_trial_data.eels(purple_idx).competency;
    end

    blue_idx = find(arrayfun(@(e) isequal(e.eel_col, [0, 0, 255]), curr_trial_data.eels));
    if ~isempty(blue_idx)
        reliability_blue(trial_idx) = curr_trial_data.eels(blue_idx).reliability;
        competency_blue(trial_idx)  = curr_trial_data.eels(blue_idx).competency;
    end
end
fprintf('Finished generating %d trials.\n', N_trials);
disp(save_directory);

%% 6) Plot the Eels' Reliability and Competency Across Trials
trials = 1:N_trials;
figure('Position', [100, 100, 1200, 800]);

% Create comparison arrays (purple vs blue)
purple_higher_comp = competency_purple > competency_blue;
purple_higher_rel = reliability_purple > reliability_blue;

% Plot Purple Eel (subplot 1)
subplot(4,1,1);
yyaxis left;
plot(trials, reliability_purple, 'b-', 'LineWidth', 2);
ylim([0 0.35]);
xlabel('Trial');
ylabel('Reliability');
yyaxis right;
plot(trials, competency_purple, 'r-', 'LineWidth', 2);
ylim([0 1]);
ylabel('Competency');
title('Purple Eel Reliability and Competency Across Trials');
grid on;

% Plot Blue Eel (subplot 2)
subplot(4,1,2);
yyaxis left;
plot(trials, reliability_blue, 'b-', 'LineWidth', 2);
ylim([0 0.35]);
xlabel('Trial');
ylabel('Reliability');
yyaxis right;
plot(trials, competency_blue, 'r-', 'LineWidth', 2);
ylim([0 1]);
ylabel('Competency');
title('Blue Eel Reliability and Competency Across Trials');
grid on;

% Add comparison subplot (new)
subplot(4,1,3);
hold on;

% Create shaded areas for different advantage combinations
advantage_categories = zeros(N_trials, 1);
for i = 1:N_trials
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

% Plot colored regions showing purple eel's advantage status
for i = 1:N_trials
    if advantage_categories(i) == 3
        color = [0.2 0.8 0.2]; % Green for double advantage
    elseif advantage_categories(i) == 2
        color = [0.8 0.6 0.0]; % Orange for comp advantage only
    elseif advantage_categories(i) == 1
        color = [0.0 0.6 0.8]; % Cyan for rel advantage only
    else
        color = [0.8 0.0 0.0]; % Red for no advantage
    end
    rectangle('Position', [i-0.5, 0, 1, 1], 'FaceColor', color, 'EdgeColor', 'none');
end

% Add legend patches
patch([0 0 0 0], [0 0 0 0], [0.2 0.8 0.2], 'EdgeColor', 'none', 'DisplayName', 'Purple: Higher Comp & Rel');
patch([0 0 0 0], [0 0 0 0], [0.8 0.6 0.0], 'EdgeColor', 'none', 'DisplayName', 'Purple: Higher Comp only');
patch([0 0 0 0], [0 0 0 0], [0.0 0.6 0.8], 'EdgeColor', 'none', 'DisplayName', 'Purple: Higher Rel only');
patch([0 0 0 0], [0 0 0 0], [0.8 0.0 0.0], 'EdgeColor', 'none', 'DisplayName', 'Purple: Lower Comp & Rel');

ylim([0 1]);
xlim([1 N_trials]);
set(gca, 'YTick', []);
legend('Location', 'eastoutside');
title('Purple Eel Advantage Regions (Compared to Blue)');
xlabel('Trial');

% Create numeric comparison plot
subplot(4,1,4);
hold on;

% Competency difference (purple - blue)
comp_diff = competency_purple - competency_blue;
% Reliability difference (purple - blue)
rel_diff = reliability_purple - reliability_blue;

% Plot the differences
plot(trials, comp_diff, 'r-', 'LineWidth', 2, 'DisplayName', 'Competency Diff (P-B)');
plot(trials, rel_diff, 'b-', 'LineWidth', 2, 'DisplayName', 'Reliability Diff (P-B)');

% Add a zero line
plot(trials, zeros(size(trials)), 'k--', 'DisplayName', 'No Difference');

xlabel('Trial');
ylabel('Difference (Purple - Blue)');
title('Difference in Competency and Reliability (Purple - Blue)');
legend('Location', 'eastoutside');
grid on;

%% 7) Plot the Distribution of Trials as a Heatmap (based on Purple Eel)
figure('Position', [100, 100, 800, 600]);

% Determine high/low thresholds dynamically using purple eel data
reliability_threshold = mean(reliability_purple);
competency_threshold = mean(competency_purple);

% Categorize trials (using purple eel values)
categories = zeros(N_trials, 1);
for i = 1:N_trials
    if reliability_purple(i) >= reliability_threshold && competency_purple(i) >= competency_threshold
        categories(i) = 1; % High Reliability, High Competency
    elseif reliability_purple(i) >= reliability_threshold && competency_purple(i) < competency_threshold
        categories(i) = 2; % High Reliability, Low Competency
    elseif reliability_purple(i) < reliability_threshold && competency_purple(i) < competency_threshold
        categories(i) = 3; % Low Reliability, Low Competency
    else
        categories(i) = 4; % Low Reliability, High Competency
    end
end

% Create a contingency table for the heatmap
heatmap_matrix = zeros(2, 2); % 2x2 matrix for high/low reliability vs. high/low competency
for i = 1:N_trials
    if reliability_purple(i) >= reliability_threshold
        reliability_index = 2; % High Reliability
    else
        reliability_index = 1; % Low Reliability
    end
    if competency_purple(i) >= competency_threshold
        competency_index = 2; % High Competency
    else
        competency_index = 1; % Low Competency
    end
    heatmap_matrix(reliability_index, competency_index) = heatmap_matrix(reliability_index, competency_index) + 1;
end

% Create the heatmap
heatmap({'Low', 'High'}, {'Low', 'High'}, heatmap_matrix');
xlabel('Competency');
ylabel('Reliability');
title('Distribution of Purple Eel Trial Categories (Reliability vs. Competency)');


function curr_trial_data = pre_generate_eels_info(visual_opt, game_opt, trial_idx)
    % Determine competency switching phases
    if trial_idx <= game_opt.competency_switch_offset
        comp_swapped = true;
    else
        comp_swapped = mod(sum(game_opt.competency_switch_trials <= trial_idx), 2) == 1;
    end

    % Determine reliability switching phases
    if trial_idx <= game_opt.reliability_offset
        rel_swapped = true;
    else
        rel_swapped = mod(sum(game_opt.reliability_switch_trials <= trial_idx), 2) == 1;
    end

    % Initialize eels
    eels(2) = struct();
    eel_colors = visual_opt.eel_colors(randperm(size(visual_opt.eel_colors, 1)), :);

    for iE = 1:2
        eels(iE).eel_col = eel_colors(iE, :);

        % Determine base competency
        if isequal(eels(iE).eel_col, [0, 0, 255])  % Blue eel
            if comp_swapped
                base_comp = game_opt.true_competency.purple;
            else
                base_comp = game_opt.true_competency.blue;
            end
        elseif isequal(eels(iE).eel_col, [157, 0, 255])  % Purple eel
            if comp_swapped
                base_comp = game_opt.true_competency.blue;
            else
                base_comp = game_opt.true_competency.purple;
            end
        end

        % Determine reliability
        if isequal(eels(iE).eel_col, [0, 0, 255])  % Blue eel
            if rel_swapped
                eels(iE).reliability = game_opt.true_reliability.purple;
            else
                eels(iE).reliability = game_opt.true_reliability.blue;
            end
        else  % Purple eel
            if rel_swapped
                eels(iE).reliability = game_opt.true_reliability.blue;
            else
                eels(iE).reliability = game_opt.true_reliability.purple;
            end
        end


        % Force small noise direction
        if base_comp == min(game_opt.competencies)
            small_noise = abs(game_opt.competency_noise_level * randn);
        else
            small_noise = -abs(game_opt.competency_noise_level * randn);
        end
        eels(iE).competency = base_comp + small_noise;

        % Check if trial_idx is the random big noise trial
        if isequal(eels(iE).eel_col, [0, 0, 255])  % Blue eel
            if ismember(trial_idx, game_opt.random_big_noise_trials_blue)  % Blue eel big noise trials
                if base_comp == max(game_opt.competencies)
                    big_noise_total = sum(-abs(game_opt.big_competency_bias + game_opt.big_competency_std * randn(game_opt.n_big_noises, 1)));
                else
                    big_noise_total = sum(abs(game_opt.big_competency_bias + game_opt.big_competency_std * randn(game_opt.n_big_noises, 1)));
                end
                eels(iE).competency = eels(iE).competency + big_noise_total;
            end
        elseif isequal(eels(iE).eel_col, [157, 0, 255])  % Purple eel
            if ismember(trial_idx, game_opt.random_big_noise_trials_purple)  % Purple eel big noise trials
                if base_comp == max(game_opt.competencies)
                    big_noise_total = sum(-abs(game_opt.big_competency_bias + game_opt.big_competency_std * randn(game_opt.n_big_noises, 1)));
                else
                    big_noise_total = sum(abs(game_opt.big_competency_bias + game_opt.big_competency_std * randn(game_opt.n_big_noises, 1)));
                end
                eels(iE).competency = eels(iE).competency + big_noise_total;
            end
        end

        % Clamp competency to [0,1]
        eels(iE).competency = min(max(eels(iE).competency, 0), 1);
    end

    % Assign sides and positions
    sides = randperm(2);
    for iE = 1:2
        eels(iE).initial_side = sides(iE);
        eels(iE).final_side = sides(iE);
        h_range = [floor(visual_opt.wHgt/2 - visual_opt.eel_rnd_range), ceil(visual_opt.wHgt/2 + visual_opt.eel_rnd_range)];
        w_range = [floor(visual_opt.wWth/4 - visual_opt.eel_rnd_range), ceil(visual_opt.wWth/4 + visual_opt.eel_rnd_range)];
        if eels(iE).final_side == 2
            w_range = [floor(visual_opt.wWth*(3/4) - visual_opt.eel_rnd_range), ceil(visual_opt.wWth*(3/4) + visual_opt.eel_rnd_range)];
        end
        eels(iE).eel_pos = [randi([w_range(1), w_range(2)]), randi([h_range(1), h_range(2)])];
        eels(iE).fish_pos = generate_fish_locs(eels(iE).eel_pos, game_opt);
    end

    % Avatar start position
    avtr_pos = [visual_opt.wWth/2, visual_opt.coordinate_window];

    % Package trial data
    curr_trial_data.eels = eels;
    curr_trial_data.avtr_start_pos = avtr_pos;
    curr_trial_data.trial_idx = trial_idx;
end

%% Function: generate_fish_locs
function fish_pos = generate_fish_locs(eel_pos, game_opt)
    % generate_fish_locs - Generates fish positions distributed across different distances and angles from the eel.
    %
    % Input arguments:
    %   eel_pos: (1x2 array) The [x, y] coordinates of the eel's position.
    %   game_opt: (struct) Structure containing game options.
    %
    % Output arguments:
    %   fish_pos: (Nx2 array) The [x, y] coordinates of generated fish positions.

    n_sectors = 6; % Number of angular sectors
    n_distance_bands = 3; % Number of distance bands
    sector_size = 2 * pi / n_sectors;

    min_r = game_opt.fish_init_min_r;
    max_r = game_opt.fish_init_max_r;
    band_size = (max_r - min_r) / n_distance_bands;

    fish_pos = zeros(game_opt.n_fishes, 2);

    fish_per_sector = ceil(game_opt.n_fishes / n_sectors);
    fish_count = 1;

    for sector = 1:n_sectors
        base_angle = (sector - 1) * sector_size;
        if fish_count > game_opt.n_fishes
            break;
        end

        n_fish_this_sector = min(fish_per_sector, game_opt.n_fishes - fish_count + 1);

        for f = 1:n_fish_this_sector
            distance_band = randi(n_distance_bands);
            min_dist = min_r + (distance_band - 1) * band_size;
            max_dist = min_r + distance_band * band_size;

            distance = min_dist + (max_dist - min_dist) * rand();
            angle = base_angle + (rand() * 0.8 + 0.1) * sector_size;

            fish_pos(fish_count, 1) = eel_pos(1) + distance * cos(angle);
            fish_pos(fish_count, 2) = eel_pos(2) + distance * sin(angle);

            fish_count = fish_count + 1;
        end
    end

    jitter_amount = min(band_size * 0.1, 10);
    fish_pos = fish_pos + (rand(size(fish_pos)) - 0.5) * jitter_amount;

    fish_pos = fish_pos(1:game_opt.n_fishes, :);
    end