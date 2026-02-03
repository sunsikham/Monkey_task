function data = phase_new_passive_view(data, visual_opt, game_opt, ...
    eye_opt, phase_str, device_opt)
    %% Description:
    %   A “passive view” subphase that moves exactly one eel (left or right),
    %   chosen randomly on the first call, and flipped on the second call.
    disp('NEW passive view');
    
    % Record phase start time
    data.(phase_str).start_time = GetSecs();
    
    % Fixed calculations
    avtr_fixed_pos = [visual_opt.wWth / 2, visual_opt.coordinate_window];
    num_steps = round(visual_opt.refresh_rate * game_opt.PV_time) + randi([30, 60]);
    frame_duration = 1 / visual_opt.refresh_rate;
    frame_threshold = frame_duration - game_opt.buffer_t;
    
    % ──────────── Decide which eel to move ────────────
    % If this is the first time “NEW” appears, data.new_choice will not exist:
    if strcmp(phase_str, 'PV1')
        % first time with PV1 → pick randomly
        move_left_eel = rand() > 0.5;
        data.pv1_side_left = move_left_eel;

    elseif strcmp(phase_str, 'PV2')
        % second time with PV2 → invert what was stored
        move_left_eel = ~data.pv1_side_left;
    else
        error('Unexpected phase_str: %s', phase_str);
    end

    
    % Preallocate arrays
    all_avatar_pos = repmat(avtr_fixed_pos, [num_steps, 1]);
    all_eye_data(num_steps) = struct('eyeX', [], 'eyeY', [], 'eyePupSz', []);
    
    % Draw static corridor once
    draw_corridor(visual_opt);

    % Get the right and left eels info
    [left_eel_curr_pos, right_eel_curr_pos, ...
          left_eel_competency, right_eel_competency, ...
          left_eel_pot, right_eel_pot, ...
          left_eel_color, right_eel_color, ...
          ~, ~, ...
          ~,~, ...
          left_eel_shape, right_eel_shape] = ...
          check_eel_side_info(data, game_opt);
    
    % Generate initial positions for whichever eel is moving
    if move_left_eel
        left_fish_curr_pos  = generate_fish_locs_passive_view('left',  game_opt, visual_opt);
        left_eel_curr_pos   = generate_eel_loc_passive_view('left',  game_opt, visual_opt);
        left_fish_prev_pos  = left_fish_curr_pos;
        left_eel_prev_pos   = left_eel_curr_pos;
    else
        right_fish_curr_pos = generate_fish_locs_passive_view('right', game_opt, visual_opt);
        right_eel_curr_pos  = generate_eel_loc_passive_view('right', game_opt, visual_opt);
        right_fish_prev_pos = right_fish_curr_pos;
        right_eel_prev_pos  = right_eel_curr_pos;
    end
    
    % ──────────── Main loop ────────────
    for t_step = 1:num_steps
        loop_start_t = GetSecs();
        
        % 1) Sample eye data
        eye_data = sample_eyes(eye_opt);
        all_eye_data(t_step) = eye_data;
        
        % 2) Clear screen
        Screen('FillRect', visual_opt.winPtr, [255,255,255]);
        
        % 3) Update & draw eel + fish
        if move_left_eel
            left_eel_fut_pos = move_eel_passive_view(...
                left_eel_curr_pos, left_eel_prev_pos, left_fish_curr_pos, game_opt);
            draw_eel(left_eel_fut_pos, left_eel_color, game_opt.eel_sz, ...
                     visual_opt, left_eel_pot, game_opt,left_eel_shape);
            
            left_fish_fut_pos = move_fishes( ...
                left_fish_curr_pos, left_fish_prev_pos, left_eel_fut_pos, avtr_fixed_pos, ...
                visual_opt, left_eel_pot, game_opt, left_eel_competency);
            
            
            
            draw_fishes(left_fish_curr_pos, visual_opt.color_fish, ...
                      game_opt.fish_sz, visual_opt.winPtr);
            
            left_eel_prev_pos  = left_eel_curr_pos;
            left_eel_curr_pos  = left_eel_fut_pos;
            left_fish_prev_pos = left_fish_curr_pos;
            left_fish_curr_pos = left_fish_fut_pos;
        else
            right_eel_fut_pos = move_eel_passive_view(...
                right_eel_curr_pos, right_eel_prev_pos, right_fish_curr_pos, game_opt);
            draw_eel(right_eel_fut_pos, right_eel_color, game_opt.eel_sz, ...
                     visual_opt, right_eel_pot, game_opt,right_eel_shape );
            
            right_fish_fut_pos = move_fishes( ...
                right_fish_curr_pos, right_fish_prev_pos, right_eel_fut_pos, avtr_fixed_pos, ...
                visual_opt, right_eel_pot, game_opt, right_eel_competency);
            draw_fishes(right_fish_curr_pos, visual_opt.color_fish, ...
                      game_opt.fish_sz, visual_opt.winPtr);
            
            right_eel_prev_pos  = right_eel_curr_pos;
            right_eel_curr_pos  = right_eel_fut_pos;
            right_fish_prev_pos = right_fish_curr_pos;
            right_fish_curr_pos = right_fish_fut_pos;
        end
        
        % 4) Draw avatar & corridor
        draw_avatar(avtr_fixed_pos, visual_opt.color_avtr_gray, ...
                    game_opt.avatar_sz, visual_opt.winPtr);
        draw_corridor(visual_opt);
        
        % 5) Flip buffer
        Screen('Flip', visual_opt.winPtr);
        
        % 6) Enforce frame timing
        elapsed_time = GetSecs() - loop_start_t;
        if elapsed_time < frame_threshold
            check_duration(loop_start_t, frame_threshold, device_opt.min_t_scale);
        end
    end
    
    % Record end times
    end_time = GetSecs();
    data.(phase_str).end_time      = end_time;
    data.(phase_str).duration = end_time - data.(phase_str).start_time ;