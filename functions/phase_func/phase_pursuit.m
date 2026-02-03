function curr_trial_data = phase_pursuit(curr_trial_data, visual_opt, ...
                                         device_opt, game_opt, eye_opt, ...
                                         phase_str, rKeyState,layout)

    visual_opt.winPtr = ptb_get_winptr(visual_opt, true);
    visual_opt.refresh_rate = Screen('NominalFrameRate', visual_opt.winPtr);
    [visual_opt.wWth, visual_opt.wHgt] = Screen('WindowSize', visual_opt.winPtr);
    visual_opt.screen_center = [visual_opt.wWth / 2, visual_opt.wHgt / 2];

    if ~isfield(curr_trial_data, phase_str)
        curr_trial_data.(phase_str) = struct();
    end
    curr_trial_data.(phase_str).phase_start = GetSecs();

    % 초기 
    fish_curr_pos = curr_trial_data.CHOICE.final_fish_pos;
    fish_prev_pos = fish_curr_pos;
    avtr_pos      =  [ (layout.Upper_Rect(1) + layout.Upper_Rect(3)) / 2, ...
             (layout.Upper_Rect(2) + layout.Upper_Rect(4)) / 2 ];


    avatar_speed = game_opt.avatar_speed;
    pursuit_time = game_opt.pursuit_time;   % 20 등
    n_fish       = size(fish_curr_pos,1);

    upper_rect= ...
        draw_new_MAP_pursuit(visual_opt, game_opt, curr_trial_data.CHOICE.choice,curr_trial_data,layout);
    avatar_r = game_opt.avatar_sz / 2;
    playArea = makePlayableAreaPoly_pursuit(upper_rect, avatar_r);

    num_steps      = round(visual_opt.refresh_rate * pursuit_time);
    all_fish_pos   = nan(num_steps, n_fish, 2);
    all_avatar_pos = nan(num_steps, 2);
    all_eye_data(num_steps) = struct('eyeX',[], 'eyeY',[], 'pupSize',[]);

    curr_trial_data.(phase_str).caught_fish_count = 0;
    caught_fish_data = struct('positions', [], 'frames_remaining', [], 'frame_caught', []);

    % Gaze monitor disabled for task stability.
   
    t_step     = 1;
    pursuit_on = true;
    inside_top = false; 
    while pursuit_on
        frame_start = GetSecs();

        % --- 입력/눈 ---
        [rKeyState, curr_trial_data] = check_reward_key( ...
            rKeyState, curr_trial_data, 'manual_check', device_opt, 0.5);
        ed = sample_eyes(eye_opt);
        all_eye_data(t_step).eyeX = ed.eyeX;
        all_eye_data(t_step).eyeY = ed.eyeY;
        all_eye_data(t_step).pupSize = ed.eyePupSz;

        % --- 아바타 이동 ---
        avtr_pos = update_pos_avatar_choice(avtr_pos, device_opt, ...
                                            avatar_speed, visual_opt, ...
                                            game_opt, playArea);
        if ~inside_top
            if avtr_pos(1) >= upper_rect(1)+avatar_r && ...
                avtr_pos(1) <= upper_rect(3)-avatar_r && ...
                avtr_pos(2) >= upper_rect(2)          && ...  % 위 rect은 위쪽 여유不要
                avtr_pos(2) <= upper_rect(4)-avatar_r
                playArea = makePlayableAreaPoly_upper(upper_rect, avatar_r);   % 이제부터는 위 사각형만
                inside_top    = true;          % 플래그 ON(다시 검사 안함)
            end
        end

        % --- 물고기 이동 ---
        fish_future_pos = move_fishes_no_eel( ...
            fish_curr_pos, fish_prev_pos, avtr_pos, game_opt, upper_rect);

        % --- 잡기 판정 ---
        [fish_future_pos, new_caught, caught_fish_data] = ...
            check_catch(fish_future_pos, avtr_pos, game_opt, ...
                        caught_fish_data, t_step, visual_opt);

       
           
        
        if new_caught > 0                      % ★ 0보다 클 때만
            curr_trial_data.(phase_str).caught_fish_count = ...
                curr_trial_data.(phase_str).caught_fish_count + new_caught;

            for i = 1:new_caught               % ★ 잡힌 마릿수만큼 보상
                %give_reward(device_opt, reward_per_fish);
                % WaitSecs(0.3);
            end
        end

        % --- 로그 저장 ---
        all_fish_pos(t_step,:,:) = fish_future_pos;
        all_avatar_pos(t_step,:) = avtr_pos;
        fish_prev_pos = fish_curr_pos;
        fish_curr_pos = fish_future_pos;

    
        draw_new_MAP_pursuit(visual_opt, game_opt, curr_trial_data.CHOICE.choice,curr_trial_data,layout);
        draw_fishes(fish_curr_pos, curr_trial_data.color, game_opt.fish_sz, visual_opt.winPtr);
        draw_avatar(avtr_pos, [255 255 0], game_opt.avatar_sz, visual_opt.winPtr);
        Screen('Flip', visual_opt.winPtr);


        % --- 종료 조건 ---
        elapsed_time = GetSecs() - curr_trial_data.(phase_str).phase_start;
        if elapsed_time >= pursuit_time || ...
           curr_trial_data.(phase_str).caught_fish_count >= n_fish
            pursuit_on = false;
        end

        t_step = t_step + 1;
        if t_step > num_steps
            pursuit_on = false;
        end

        % (선택) 프레임 속도 맞추기
        check_duration(frame_start, 1/visual_opt.refresh_rate, device_opt.min_t_scale);
    end

    % 저장
    valid_steps = min(t_step-1, num_steps);
    curr_trial_data.(phase_str).final_avatar_pos = avtr_pos;
    curr_trial_data.(phase_str).final_fish_pos   = fish_curr_pos;
    curr_trial_data.(phase_str).caught_fish_log  = caught_fish_data;

    curr_trial_data = concatenate_pos_data(curr_trial_data, ...
        all_avatar_pos(1:valid_steps,:), -1, ...
        all_fish_pos(1:valid_steps,:,:), all_eye_data(1:valid_steps), phase_str);

    curr_trial_data.(phase_str).phase_end = GetSecs();
    curr_trial_data.(phase_str).phase_duration = ...
        curr_trial_data.(phase_str).phase_end - curr_trial_data.(phase_str).phase_start;

  
 end
