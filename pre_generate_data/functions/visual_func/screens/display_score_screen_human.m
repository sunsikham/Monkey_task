function [data, all_trials] = display_score_screen_human(data, visual_opt, game_opt, device_opt, all_trials)
    % Start timing for the score phase
    phase_str = 'score';
    data.(phase_str).phase_start = GetSecs();

    % Calculate unused pursuit time
    time = game_opt.pursuit_time - data.PURSUIT.phase_duration;

    % Define screen color (grey background)
    SCREEN_COLOR = [255, 255, 255] / 2;

    % Clear the screen
    Screen('FillRect', visual_opt.winPtr, SCREEN_COLOR);

    % Calculate total fish caught
    left_fish_count = data.PURSUIT.left_fish_caught;
    right_fish_count = data.PURSUIT.right_fish_caught;
    total_fish_caught = left_fish_count + right_fish_count;  % Total fish caught by the player
    fraction_remaining = time / game_opt.pursuit_time;

    % Get eel info
    [~, ~, ~, ~, ~, ~, left_eel_color, right_eel_color, left_eel_rely, right_eel_rely] = ...
        check_eel_side_info(data, game_opt);
    
    rel_interval = game_opt.reliability_interval;
    
    % Compute reward probability correctly
    if left_fish_count > 0
        left_reward = left_eel_rely + (left_fish_count - 1) * rel_interval;
    else
        left_reward = 0;
    end

    if right_fish_count > 0
        right_reward = right_eel_rely + (right_fish_count - 1) * rel_interval;
    else
        right_reward = 0;
    end

    reward_probability = min(left_reward + right_reward, 1);
    
    % Store reward info in a structured format
    data.reward_info = struct();
    data.reward_info.left_reward_this_trial = left_reward;
    data.reward_info.right_reward_this_trial = right_reward;
    data.reward_info.probability_this_trial = reward_probability;
    data.rand_num_generated =  rand();
    disp(data.rand_num_generated);
    data.reward_info.reward_given = data.rand_num_generated < reward_probability;
    
    % Compute actual and expected rewards
    actual_reward = game_opt.reward_value * data.reward_info.reward_given;
    all_trials.total_actual_reward = all_trials.total_actual_reward + actual_reward;

    data.current_trial_reward = actual_reward;
    data.current_trial_expected_reward = game_opt.reward_value;
    data.cumulative_trial_reward = all_trials.total_actual_reward;
    
    % Define a gray color for muting
    MUTE_GRAY = [128, 128, 128];  
    mute_factor = 0.6;

    % Muted eel colors
    left_eel_color_muted = left_eel_color * mute_factor + MUTE_GRAY * (1 - mute_factor);
    right_eel_color_muted = right_eel_color * mute_factor + MUTE_GRAY * (1 - mute_factor);

    % Define the number of circles
    numCircles = 3;
    circleRadius = 30;
    horizontalSpacing = 80;

    % Positioning adjustments for centering vertically
    screenX = visual_opt.wWth / 2;
    screenY = visual_opt.wHgt / 2;

    % Now draw the circles
    for i = 1:numCircles
        if i <= left_fish_count
            circleColor = left_eel_color_muted;
        elseif i <= (left_fish_count + right_fish_count)
            circleColor = right_eel_color_muted;
        else
            circleColor = [169, 169, 169];  % Gray for no fish caught
        end

        % Calculate circle position
        circleX = screenX + (i - (numCircles + 1) / 2) * horizontalSpacing;

        % Draw the circle
        Screen('FillOval', visual_opt.winPtr, circleColor, ...
            [circleX - circleRadius, screenY - circleRadius, circleX + circleRadius, screenY + circleRadius]);
    end

    % Flip the screen
    Screen('Flip', visual_opt.winPtr);

    %% Give reward to the monkeys for each fish caught
    if total_fish_caught > 0
        % Trigger the solenoid for each fish caught

        give_reward(device_opt, game_opt.reward_duration *total_fish_caught);  % Call reward for each fish


        data.reward_info.reward_given =true;
    end

    %% Keep the score screen visible for the necessary duration
    start_time = GetSecs();
    while (GetSecs() - start_time) < game_opt.score_time
        loop_start_t = GetSecs();
        check_duration(loop_start_t, 1 / visual_opt.refresh_rate, device_opt.min_t_scale);
    end

    % Record phase end time and duration
    data.(phase_str).phase_end = GetSecs();
    data.(phase_str).phase_duration = data.(phase_str).phase_end - data.(phase_str).phase_start;
end
