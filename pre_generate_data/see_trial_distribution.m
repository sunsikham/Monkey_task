%% Combined Plot Script: Eel Competency & Reliability Analysis and Count Heatmap
clear; close all; clc;

%% 1) Setup Paths and Load Files
currentFolder = fileparts(mfilename('fullpath'));
data_directory = fullfile(currentFolder, 'data', 'premade_trials');

% Get list of generated trial files (assumed to be named trial_*.mat)
files = dir(fullfile(data_directory, 'trial_*.mat'));
N_trials = length(files);

%% 2) Preallocate Arrays for Subplot Analysis
comp_change_stronger = zeros(1, N_trials);
comp_change_weaker  = zeros(1, N_trials);
reliability_stronger = zeros(1, N_trials);
reliability_weaker  = zeros(1, N_trials);
reliability_blue    = zeros(1, N_trials);
reliability_purple  = zeros(1, N_trials);
competency_blue     = zeros(1, N_trials);
competency_purple   = zeros(1, N_trials);
initial_comp_diff = zeros(1, N_trials);
final_comp_diff = zeros(1, N_trials);

%% Loop 1: Load Each Trial and Extract Data for Subplots
for k = 1:N_trials
    trial_file = fullfile(data_directory, files(k).name);
    data = load(trial_file);
    curr_trial_data = data.curr_trial_data;
    eels = curr_trial_data.eels;
    
    % Extract competencies for blue and purple eels
    for i = 1:2
        if isequal(eels(i).eel_col, [0, 0, 255])  % Blue eel
            competency_blue(k) = eels(i).competency;
            reliability_blue(k) = eels(i).reliability;
        elseif isequal(eels(i).eel_col, [157, 0, 255])  % Purple eel
            competency_purple(k) = eels(i).competency;
            reliability_purple(k) = eels(i).reliability;
        end
    end

    % Determine stronger and weaker eels based on competency
    [~, idx_strong] = max([eels.competency]);
    [~, idx_weak] = min([eels.competency]);

    % Handle the case where competencies are equal
    if eels(1).competency == eels(2).competency
        % Arbitrarily assign if equal
        idx_strong = 1;
        idx_weak = 2;
    end

    % Since comp_changes doesn't exist in the new structure, we'll calculate it
    % based on the difference from the expected base competencies
    % We'll use the first trial's competencies as reference
    if k == 1
        base_comp_strong = eels(idx_strong).competency;
        base_comp_weak = eels(idx_weak).competency;
    end

    comp_change_stronger(k) = eels(idx_strong).competency - base_comp_strong;
    comp_change_weaker(k) = eels(idx_weak).competency - base_comp_weak;
    reliability_stronger(k) = eels(idx_strong).reliability;
    reliability_weaker(k) = eels(idx_weak).reliability;

    % Calculate initial and final competency differences
    % Since we don't have initial_competencies anymore, we'll use the current competencies
    initial_comp_diff(k) = eels(idx_strong).competency - eels(idx_weak).competency;
    final_comp_diff(k) = initial_comp_diff(k); // Same as initial since we don't have separate final values
end

% Calculate average competency differences
avg_initial_diff = mean(initial_comp_diff);
avg_final_diff = mean(final_comp_diff);
avg_abs_initial_diff = mean(abs(initial_comp_diff));
avg_abs_final_diff = mean(abs(final_comp_diff));

% Display average differences in command window
fprintf('Average Competency Difference: %.4f\n', avg_initial_diff);
fprintf('Average Absolute Competency Difference: %.4f\n', avg_abs_initial_diff);

%% Loop 2: Build Count Matrix for Competency Heatmap
% The heatmap bins are defined by comparing the left eel (final_side == 1)
% to the right eel (final_side == 2), using competency and reliability.
bin_counts = zeros(3,3); % Rows: reliability (1: lower, 2: equal, 3: higher)
                         % Columns: competency (1: lower, 2: equal, 3: higher)
for k = 1:N_trials
    trial_file = fullfile(data_directory, files(k).name);
    data = load(trial_file);
    curr_trial_data = data.curr_trial_data;
    eels = curr_trial_data.eels;

    % Identify left and right eels based on final_side.
    left_idx = find([eels.final_side] == 1);
    right_idx = find([eels.final_side] == 2);
    if isempty(left_idx) || isempty(right_idx)
        continue;
    end

    left_comp = eels(left_idx).competency;
    right_comp = eels(right_idx).competency;
    left_rel = eels(left_idx).reliability;
    right_rel = eels(right_idx).reliability;

    % Determine competency bin for left eel relative to right eel
    if left_comp < right_comp
        comp_bin = 1;
    elseif left_comp == right_comp
        comp_bin = 2;
    else
        comp_bin = 3;
    end
    
    % Determine reliability bin for left eel relative to right eel
    if left_rel < right_rel
        rel_bin = 1;
    elseif left_rel == right_rel
        rel_bin = 2;
    else
        rel_bin = 3;
    end

    bin_counts(rel_bin, comp_bin) = bin_counts(rel_bin, comp_bin) + 1;
end
total_trials = sum(bin_counts, 'all');

%% 3) Plot Combined Figure with Subplots - BEAUTIFIED
figure('Color','w','Position',[100, 100, 1200, 900]); % Increased height to accommodate new row

% Set common properties for better aesthetics
fontName = 'Arial';
titleFontSize = 13;
labelFontSize = 12;
mainTitleFontSize = 16;
lineWidth = 2;
markerSize = 3;

% Color scheme
strongColor = [0.2, 0.6, 0.2]; % Green for stronger eel
weakColor = [0.8, 0.4, 0]; % Orange for weaker eel
blueEelColor = [0, 0.4, 0.9]; % Refined blue
purpleEelColor = [0.65, 0.1, 0.8]; % Refined purple
initialDiffColor = [0.4, 0.4, 0.6]; % Muted blue-gray

% Larger eel plots (stronger eel)
subplot(6,2,1);
plot(1:N_trials, comp_change_stronger, '-o', 'LineWidth', lineWidth, 'MarkerSize', markerSize, 'Color', strongColor);
xlabel('Trial Number', 'FontSize', labelFontSize, 'FontWeight', 'bold', 'FontName', fontName);
ylabel('Comp Change', 'FontSize', labelFontSize, 'FontWeight', 'bold', 'FontName', fontName);
title('Stronger Eel: Competency Change', 'FontSize', titleFontSize, 'FontName', fontName);
grid on;
set(gca, 'LineWidth', 1.5, 'GridLineStyle', ':');
ylim([min(comp_change_stronger)-0.5, max(comp_change_stronger)+0.5]);

subplot(6,2,3);
plot(1:N_trials, reliability_stronger, '-s', 'LineWidth', lineWidth, 'MarkerSize', markerSize, 'Color', strongColor);
xlabel('Trial Number', 'FontSize', labelFontSize, 'FontWeight', 'bold', 'FontName', fontName);
ylabel('Reliability', 'FontSize', labelFontSize, 'FontWeight', 'bold', 'FontName', fontName);
title('Stronger Eel: Reliability', 'FontSize', titleFontSize, 'FontName', fontName);
grid on;
set(gca, 'LineWidth', 1.5, 'GridLineStyle', ':');
ylim([min(reliability_stronger)-0.05, max(reliability_stronger)+0.05]);

% Smaller eel plots (weaker eel)
subplot(6,2,2);
plot(1:N_trials, comp_change_weaker, '-o', 'LineWidth', lineWidth, 'MarkerSize', markerSize, 'Color', weakColor);
xlabel('Trial Number', 'FontSize', labelFontSize, 'FontWeight', 'bold', 'FontName', fontName);
ylabel('Comp Change', 'FontSize', labelFontSize, 'FontWeight', 'bold', 'FontName', fontName);
title('Weaker Eel: Competency Change', 'FontSize', titleFontSize, 'FontName', fontName);
grid on;
set(gca, 'LineWidth', 1.5, 'GridLineStyle', ':');
ylim([min(comp_change_weaker)-0.5, max(comp_change_weaker)+0.5]);

subplot(6,2,4);
plot(1:N_trials, reliability_weaker, '-s', 'LineWidth', lineWidth, 'MarkerSize', markerSize, 'Color', weakColor);
xlabel('Trial Number', 'FontSize', labelFontSize, 'FontWeight', 'bold', 'FontName', fontName);
ylabel('Reliability', 'FontSize', labelFontSize, 'FontWeight', 'bold', 'FontName', fontName);
title('Weaker Eel: Reliability', 'FontSize', titleFontSize, 'FontName', fontName);
grid on;
set(gca, 'LineWidth', 1.5, 'GridLineStyle', ':');
ylim([min(reliability_weaker)-0.05, max(reliability_weaker)+0.05]);

% Additional Plots: Reliability of Blue and Purple Eels
subplot(6,2,5);
plot(1:N_trials, reliability_blue, '-o', 'LineWidth', lineWidth, 'MarkerSize', markerSize, 'Color', blueEelColor);
xlabel('Trial Number', 'FontSize', labelFontSize, 'FontWeight', 'bold', 'FontName', fontName);
ylabel('Reliability', 'FontSize', labelFontSize, 'FontWeight', 'bold', 'FontName', fontName);
title('Blue Eel Reliability Through Trials', 'FontSize', titleFontSize, 'FontName', fontName);
grid on;
set(gca, 'LineWidth', 1.5, 'GridLineStyle', ':');
ylim([min(reliability_blue)-0.05, max(reliability_blue)+0.05]);

subplot(6,2,6);
plot(1:N_trials, reliability_purple, '-o', 'LineWidth', lineWidth, 'MarkerSize', markerSize, 'Color', purpleEelColor);
xlabel('Trial Number', 'FontSize', labelFontSize, 'FontWeight', 'bold', 'FontName', fontName);
ylabel('Reliability', 'FontSize', labelFontSize, 'FontWeight', 'bold', 'FontName', fontName);
title('Purple Eel Reliability Through Trials', 'FontSize', titleFontSize, 'FontName', fontName);
grid on;
set(gca, 'LineWidth', 1.5, 'GridLineStyle', ':');
ylim([min(reliability_purple)-0.05, max(reliability_purple)+0.05]);

% New row: Competency of Blue and Purple Eels
subplot(6,2,7);
plot(1:N_trials, competency_blue, '-o', 'LineWidth', lineWidth, 'MarkerSize', markerSize, 'Color', blueEelColor);
xlabel('Trial Number', 'FontSize', labelFontSize, 'FontWeight', 'bold', 'FontName', fontName);
ylabel('Competency', 'FontSize', labelFontSize, 'FontWeight', 'bold', 'FontName', fontName);
title('Blue Eel Competency Through Trials', 'FontSize', titleFontSize, 'FontName', fontName);
grid on;
set(gca, 'LineWidth', 1.5, 'GridLineStyle', ':');
ylim([min(competency_blue)-0.05, max(competency_blue)+0.05]);

subplot(6,2,8);
plot(1:N_trials, competency_purple, '-o', 'LineWidth', lineWidth, 'MarkerSize', markerSize, 'Color', purpleEelColor);
xlabel('Trial Number', 'FontSize', labelFontSize, 'FontWeight', 'bold', 'FontName', fontName);
ylabel('Competency', 'FontSize', labelFontSize, 'FontWeight', 'bold', 'FontName', fontName);
title('Purple Eel Competency Through Trials', 'FontSize', titleFontSize, 'FontName', fontName);
grid on;
set(gca, 'LineWidth', 1.5, 'GridLineStyle', ':');
ylim([min(competency_purple)-0.05, max(competency_purple)+0.05]);

% Combined plot (Blue eel competency & reliability)
subplot(6,2,[9,10]);
hold on;
yyaxis left
p1 = plot(1:N_trials, competency_blue, '-o', 'LineWidth', lineWidth, 'MarkerSize', markerSize, 'Color', blueEelColor);
ylabel('Competency', 'FontSize', labelFontSize, 'FontWeight', 'bold', 'FontName', fontName);
ylim([min(competency_blue)-0.05, max(competency_blue)+0.05]);

yyaxis right
p2 = plot(1:N_trials, reliability_blue, '-s', 'LineWidth', lineWidth, 'MarkerSize', markerSize, 'Color', strongColor);
ylabel('Reliability', 'FontSize', labelFontSize, 'FontWeight', 'bold', 'FontName', fontName);
ylim([min(reliability_blue)-0.05, max(reliability_blue)+0.05]);
hold off;

xlabel('Trial Number', 'FontSize', labelFontSize, 'FontWeight', 'bold', 'FontName', fontName);
title('Blue Eel Competency & Reliability', 'FontSize', titleFontSize, 'FontName', fontName);
legend({'Competency', 'Reliability'}, 'FontSize', 11, 'Location', 'best', 'Box', 'off');
grid on;
set(gca, 'LineWidth', 1.5, 'GridLineStyle', ':');

% Combined plot (Purple eel competency & reliability)
subplot(6,2,[11,12]);
hold on;
yyaxis left
p1 = plot(1:N_trials, competency_purple, '-o', 'LineWidth', lineWidth, 'MarkerSize', markerSize, 'Color', purpleEelColor);
ylabel('Competency', 'FontSize', labelFontSize, 'FontWeight', 'bold', 'FontName', fontName);
ylim([min(competency_purple)-0.05, max(competency_purple)+0.05]);

yyaxis right
p2 = plot(1:N_trials, reliability_purple, '-s', 'LineWidth', lineWidth, 'MarkerSize', markerSize, 'Color', strongColor);
ylabel('Reliability', 'FontSize', labelFontSize, 'FontWeight', 'bold', 'FontName', fontName);
ylim([min(reliability_purple)-0.05, max(reliability_purple)+0.05]);
hold off;

xlabel('Trial Number', 'FontSize', labelFontSize, 'FontWeight', 'bold', 'FontName', fontName);
title('Purple Eel Competency & Reliability', 'FontSize', titleFontSize, 'FontName', fontName);
legend({'Competency', 'Reliability'}, 'FontSize', 11, 'Location', 'best', 'Box', 'off');
grid on;
set(gca, 'LineWidth', 1.5, 'GridLineStyle', ':');

sgtitle('Eel Competency and Reliability Analysis', 'FontSize', mainTitleFontSize, 'FontWeight', 'bold', 'FontName', fontName);

%% 4) Plot Count Heatmap for Competency Left vs. Right Eel Comparisons - BEAUTIFIED
figure('Color','w', 'Position', [100, 100, 800, 600]);

% Create custom colormap with more appealing gradient
cmap = [
    0.95, 0.95, 1.0;  % Very light blue
    0.8, 0.85, 1.0;   % Light blue
    0.6, 0.75, 1.0;   % Medium blue
    0.4, 0.6, 0.95;   % Medium-dark blue
    0.2, 0.4, 0.9;    % Dark blue
    0.0, 0.2, 0.8     % Very dark blue
];
colormap(cmap);

% Competency Heatmap
h1 = imagesc(bin_counts);
c1 = colorbar;
c1.Label.String = 'Count';
c1.Label.FontSize = 12;
c1.Label.FontWeight = 'bold';
c1.Label.FontName = fontName;

% Improve axis labels and title
xlabel('Competency of Left Eel', 'FontSize', labelFontSize+1, 'FontWeight', 'bold', 'FontName', fontName);
ylabel('Reliability of Left Eel', 'FontSize', labelFontSize+1, 'FontWeight', 'bold', 'FontName', fontName);
title('Count Heatmap: Left vs. Right Eel', 'FontSize', titleFontSize+1, 'FontWeight', 'bold', 'FontName', fontName);

% Improve tick labels
set(gca, 'XTick', 1:3, 'XTickLabel', {'Lower', 'Equal', 'Higher'}, 'FontSize', 11, 'FontWeight', 'bold', 'FontName', fontName);
set(gca, 'YTick', 1:3, 'YTickLabel', {'Lower', 'Equal', 'Higher'}, 'FontSize', 11, 'FontWeight', 'bold', 'FontName', fontName);
set(gca, 'LineWidth', 1.5);

% Add a border around the heatmap cells
for i = 0.5:1:3.5
    line([i, i], [0.5, 3.5], 'Color', [0.3, 0.3, 0.3], 'LineWidth', 1.5);
    line([0.5, 3.5], [i, i], 'Color', [0.3, 0.3, 0.3], 'LineWidth', 1.5);
end

% Annotate heatmap with counts and percentages
textColors = zeros(3,3,3);  % Initialize text color matrix (RGB)
for row = 1:3
    for col = 1:3
        count = bin_counts(row, col);
        percentage = (count / total_trials) * 100;

        % Determine text color based on background darkness
        if count > max(bin_counts(:))/2
            textColor = [1, 1, 1];  % White text on dark backgrounds
        else
            textColor = [0, 0, 0];  % Black text on light backgrounds
        end

        % Store text color for use in the text function
        textColors(row, col, :) = textColor;

        text(col, row, sprintf('%d\n(%.1f%%)', count, percentage), ...
            'HorizontalAlignment', 'center', 'Color', textColor, 'FontSize', 12, ...
            'FontWeight', 'bold', 'FontName', fontName);
    end
end

% Add a subtitle with methodology explanation
annotation('textbox', [0.1, 0.01, 0.8, 0.05], 'String', ...
    'Comparison of left eel (x-axis) to right eel (reference) for Competency', ...
    'HorizontalAlignment', 'center', 'FontSize', 11, 'FontName', fontName, 'LineStyle', 'none');

% Display count summaries in command window
disp('Bin counts (Rows: Reliability, Columns: Competency):');
disp(bin_counts);
disp('Total trials:');
disp(total_trials);