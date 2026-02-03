function test_switching_logic(game_opt)
% TEST_SWITCHING_LOGIC - Tests the eel switching logic for correctness with visualization
% using the actual task functions
%
% Syntax:
%   test_switching_logic(game_opt)
%
% Input:
%   game_opt - Game options structure with switching parameters
%
% This function simulates trials and plots reliability/competency for blue and purple eels
    sca;
    % Define trial range
    num_trials = 100;
    trials = 1:num_trials;
    
    % Make sure initial values are defined
    if ~isfield(game_opt, 'initial_rel_swapped')
        game_opt.initial_rel_swapped = 0;
        fprintf('Created initial_rel_swapped = %d\n', game_opt.initial_rel_swapped);
    end
    
    if ~isfield(game_opt, 'initial_comp_swapped')
        game_opt.initial_comp_swapped = 0;
        fprintf('Created initial_comp_swapped = %d\n', game_opt.initial_comp_swapped);
    end
   
    % Create dummy visual_opt structure with required fields
    visual_opt = struct();
    visual_opt.wWth = 1000;  % Screen width
    visual_opt.wHgt = 800;   % Screen height
    visual_opt.eel_rnd_range = 50;  % Range for random eel positions
    visual_opt.coordinate_window = 400;  % For avatar start position
    
    % Force dynamic trial generation
    game_opt.premade_eels = false;
    
    % Create arrays to store the values for each trial
    blue_rel = zeros(1, num_trials);
    purple_rel = zeros(1, num_trials);
    blue_comp = zeros(1, num_trials);
    purple_comp = zeros(1, num_trials);
    
    % Generate the data for all trials using actual task functions
    test_game_opt = game_opt;
    
    game_opt.competency_noise_level =0;
    
    fprintf('\n==== Testing Eel Switching Logic with Task Functions ====\n');
    
    for trial = 1:num_trials
        % Create trial data structure as it would be in the task
        curr_trial_data = struct();
        curr_trial_data.trial_idx = trial;
        
        % Call the actual function used in the task
        [curr_trial_data, test_game_opt] = generate_eels_info(curr_trial_data, visual_opt, test_game_opt);
        
        % Extract eel data
        eels = curr_trial_data.eels;
        
        % Find blue and purple eels
        blue_eel_idx = find(cellfun(@(x) isequal(x, [0, 0, 255]), {eels.eel_col}));
        purple_eel_idx = find(cellfun(@(x) isequal(x, [157, 0, 255]), {eels.eel_col}));
        
        % Store values
        blue_rel(trial) = eels(blue_eel_idx).reliability;
        purple_rel(trial) = eels(purple_eel_idx).reliability;
        blue_comp(trial) = eels(blue_eel_idx).competency;
        purple_comp(trial) = eels(purple_eel_idx).competency;
        
        if trial <= 5
            fprintf('Trial %d: Blue eel reliability=%.3f, competency=%.3f\n', ...
                    trial, blue_rel(trial), blue_comp(trial));
            fprintf('Trial %d: Purple eel reliability=%.3f, competency=%.3f\n', ...
                    trial, purple_rel(trial), purple_comp(trial));
        end
    end
    
    % Create the figure
    figure('Position', [100, 100, 1000, 600]);
    
    % Plot reliability
    subplot(2, 1, 1);
    plot(trials, blue_rel, 'b-', 'LineWidth', 2);
    hold on;
    plot(trials, purple_rel, 'm-', 'LineWidth', 2);
    ylabel('Reliability Value');
    title('Reliability Over Trials');
    legend('Blue Eel', 'Purple Eel', 'Location', 'Best');
    grid on;
    
    % Plot competency
    subplot(2, 1, 2);
    plot(trials, blue_comp, 'b-', 'LineWidth', 2);
    hold on;
    plot(trials, purple_comp, 'm-', 'LineWidth', 2);
    xlabel('Trial Number');
    ylabel('Competency Value');
    title('Competency Over Trials');
    legend('Blue Eel', 'Purple Eel', 'Location', 'Best');
    grid on;
    
    % Add overall title
    sgtitle('Eel Characteristics Across Trials (Using Task Functions)', 'FontSize', 14);
    
    % Extract and display switch points
    if isfield(test_game_opt, 'reliability_switch_trials')
        rel_switches = test_game_opt.reliability_switch_trials;
        rel_switches = rel_switches(rel_switches <= num_trials);
        
        % Mark reliability switch points
        subplot(2, 1, 1);
        for sw = rel_switches
            line([sw, sw], ylim, 'Color', 'r', 'LineStyle', '--', 'LineWidth', 1);
        end
    end
    
    if isfield(test_game_opt, 'competency_switch_trials')
        comp_switches = test_game_opt.competency_switch_trials;
        comp_switches = comp_switches(comp_switches <= num_trials);
        
        % Mark competency switch points
        subplot(2, 1, 2);
        for sw = comp_switches
            line([sw, sw], ylim, 'Color', 'r', 'LineStyle', '--', 'LineWidth', 1);
        end
    end
    
    % Create an advantage plot
    figure('Position', [100, 700, 1000, 300]);
    
    % Calculate advantage
    rel_advantage = purple_rel > blue_rel;
    comp_advantage = purple_comp > blue_comp;
    
    % Create numerical advantage measure (-1 = blue advantage, 1 = purple advantage)
    combined_advantage = zeros(1, num_trials);
    for i = 1:num_trials
        if rel_advantage(i) && comp_advantage(i)
            combined_advantage(i) = 2;  % Purple has both advantages
        elseif rel_advantage(i)
            combined_advantage(i) = 1;  % Purple has reliability advantage
        elseif comp_advantage(i)
            combined_advantage(i) = -1; % Purple has competency advantage
        else
            combined_advantage(i) = -2; % Blue has both advantages
        end
    end
    
    % Plot advantage state
    h = bar(trials, combined_advantage);
    ylim([-2.5, 2.5]);
    title('Eel Advantage by Trial');
    xlabel('Trial Number');
    ylabel('Advantage State');
    
    % Create custom y-tick labels
    set(gca, 'YTick', [-2, -1, 0, 1, 2]);
    set(gca, 'YTickLabel', {'Blue Both', 'Blue Rel', 'Equal', 'Purple Rel', 'Purple Both'});
    grid on;
    
    % Color code the bars
    cdata = zeros(length(trials), 3);
    for i = 1:length(trials)
        if combined_advantage(i) == 2
            cdata(i,:) = [0.8, 0, 0.8]; % Purple (both advantages)
        elseif combined_advantage(i) == 1
            cdata(i,:) = [1, 0.5, 1];   % Light purple (reliability advantage)
        elseif combined_advantage(i) == -1
            cdata(i,:) = [0.5, 0.5, 1]; % Light blue (competency advantage)
        else
            cdata(i,:) = [0, 0, 0.8];   % Blue (both advantages)
        end
    end
    h.FaceColor = 'flat';
    h.CData = cdata;
    
    fprintf('\n==== Test Complete ====\n');
end