function curr_trial_data = phase_choice(curr_trial_data, visual_opt, game_opt, eye_opt, phase_str, device_opt)
    % PHASE_CHOICE - Handles the choice phase of the game/experiment.
    % After the avatar touches an eel:
    %  • both eels and the avatar turn green,
    %  • the screen freezes for 500 ms,
    % then the trial proceeds.

    if ~isfield(curr_trial_data, phase_str)
        curr_trial_data.(phase_str) = struct();
        curr_trial_data.(phase_str).choice = -1;
    end
    curr_trial_data.(phase_str).phase_start = GetSecs();

    % random pre‐movement delay
    delay_time = 0.5 + 0.25 * rand();
    curr_trial_data.(phase_str).initial_delay = delay_time;

    % initial avatar position
    avtr_pos = [visual_opt.wWth/2, visual_opt.coordinate_window];
    choice_onset = true;

    % preallocate storage
    num_steps = round(visual_opt.refresh_rate * game_opt.choice_time);
    all_avatar_pos = -1 * ones(num_steps, 2);
    all_eye_data(num_steps) = struct('eyeX', [], 'eyeY', [], 'pupSize', []);

    t_step = 1;
    start_time = GetSecs();
    movement_allowed = false;
    black_color = [0 0 0];
    keyState = false;

    % eel positions from generate_eels_dynamically
    eel1_pos = curr_trial_data.eels(1).eel_pos_choice;
    eel2_pos = curr_trial_data.eels(2).eel_pos_choice;

    green_color = [0 255 0];


    while choice_onset
        now = GetSecs();

        % enable movement after delay
        if ~movement_allowed && (now - start_time >= delay_time)
            movement_allowed = true;
        end

        % check reward key
        [keyState, curr_trial_data] = check_reward_key( ...
            keyState, curr_trial_data, phase_str, device_opt, game_opt);

        % choose avatar color for this frame
        if movement_allowed
            avatar_color = visual_opt.choice_color_avtr;
        else
            avatar_color = black_color;
        end

        % draw guide & avatar
        draw_monkey_choice_guide(visual_opt, game_opt, curr_trial_data);
        draw_avatar(avtr_pos, avatar_color, game_opt.avatar_sz, visual_opt.winPtr);
        Screen('Flip', visual_opt.winPtr);

        % sample eyes
        ed = sample_eyes(eye_opt);
        all_eye_data(t_step).eyeX    = ed.eyeX;
        all_eye_data(t_step).eyeY    = ed.eyeY;
        all_eye_data(t_step).pupSize = ed.eyePupSz;

        % update position if allowed
        if movement_allowed
            avtr_pos = update_pos_avatar(avtr_pos, device_opt, game_opt.avatar_speed, visual_opt, game_opt);
        end
        all_avatar_pos(t_step, :) = avtr_pos;

        %disp(['avtr_pos: ', mat2str(avtr_pos), ' | eel1_pos: ', mat2str(eel1_pos), ' | eel2_pos: ', mat2str(eel2_pos)])


        % collision detection
        thr = game_opt.avatar_sz + game_opt.eel_sz;
        if norm(avtr_pos - eel1_pos) < thr || norm(avtr_pos - eel2_pos) < thr
                % Check for choice based on position
            if avtr_pos(1) < visual_opt.corridor_coord(1, 1)
                % TODO: if labjack is on, send pulse (add it to all functs after
        
                curr_trial_data.(phase_str).choice_side = 'left';
                curr_trial_data.(phase_str).choice = 1;

                if curr_trial_data.eels(1).initial_side == 1
                    curr_trial_data.(phase_str).choice_color = curr_trial_data.eels(1).eel_col;
                else
                    curr_trial_data.(phase_str).choice_color = curr_trial_data.eels(2).eel_col;
                end 

            elseif avtr_pos(1) > visual_opt.corridor_coord(3, 1)
                % TODO: if labjack is on, send pulse (add it to all functs after
                % loop_start_t
                curr_trial_data.(phase_str).choice_side  = 'right';
                curr_trial_data.(phase_str).choice  = 2;
                
                if curr_trial_data.eels(1).initial_side == 2
                    curr_trial_data.(phase_str).choice_color = curr_trial_data.eels(1).eel_col;
                else
                    curr_trial_data.(phase_str).choice_color = curr_trial_data.eels(2).eel_col;
                end 
        
            end

            

            % highlight both eels and avatar in green
            old_colors = game_opt.eel_colors;
            game_opt.eel_colors = repmat(green_color, size(old_colors,1),1);

            draw_monkey_choice_guide(visual_opt, game_opt, curr_trial_data);
            draw_avatar(avtr_pos, green_color, game_opt.avatar_sz, visual_opt.winPtr);
            Screen('Flip', visual_opt.winPtr);

            % freeze for 500 ms
            WaitSecs(0.5);

            % restore eel colors
            game_opt.eel_colors = old_colors;

            choice_onset = false;
        end

        % frame timing
        check_duration(now, 1/visual_opt.refresh_rate, device_opt.min_t_scale);

        t_step = t_step + 1;
        if GetSecs() - curr_trial_data.(phase_str).phase_start > game_opt.choice_time
            choice_onset = false;
        end
    end



    % save data
    curr_trial_data = concatenate_pos_data( ...
        curr_trial_data, all_avatar_pos, -1, -1, all_eye_data, phase_str);
    curr_trial_data.(phase_str).phase_end      = GetSecs();
    curr_trial_data.(phase_str).phase_duration = ...
        curr_trial_data.(phase_str).phase_end - curr_trial_data.(phase_str).phase_start;
end
