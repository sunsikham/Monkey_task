function new_pos = update_pos_avatar_pursuit(current_pos, device_opt, movement_speed, visual_opt, game_opt)
    % 이 함수는 'pursuit' 단계 전용으로, 통짜 벽과의 충돌만 계산합니다.
    
    new_pos = current_pos;
    avatar_radius = game_opt.avatar_sz / 2;
    
    % 화면 경계 설정
    screen_left = avatar_radius;
    screen_right = visual_opt.wWth - avatar_radius;
    screen_top = avatar_radius;
    screen_bottom = visual_opt.wHgt - avatar_radius;
    
    joy_vec = [0, 0]; % Initialize joy_vec
    
    % ======================= [수정된 부분 시작] =======================
    % choice 단계에서 정상 작동하던 키보드/조이스틱 입력 로직을 그대로 가져옵니다.
    
    % Get movement input (Keyboard)
    if device_opt.KEYBOARD
        [keyIsDown, ~, keyCode] = KbCheck;
        if keyIsDown
            if keyCode(KbName('LeftArrow'))
                joy_vec(1) = joy_vec(1) - 1;
            elseif keyCode(KbName('RightArrow'))
                joy_vec(1) = joy_vec(1) + 1;
            end
            if keyCode(KbName('UpArrow'))
                joy_vec(2) = joy_vec(2) - 1;
            elseif keyCode(KbName('DownArrow'))
                joy_vec(2) = joy_vec(2) + 1;
            end
        end
    end
    
    % Get movement input (Joystick)
    if device_opt.JOYSTICK
        [joy_temp, ~] = JoyMEX(0);
        joy_temp = joy_temp(1:2);
        if norm(joy_temp) >= device_opt.minInput
            joy_vec = joy_vec + joy_temp;
        end
    end
    
    % Apply dead zone and normalization
    if norm(joy_vec) < device_opt.minInput % deadzone
        joy_vec = [0, 0];
        isJoyMoved = false;
    else
        % norm_joy 함수 로직 통합
        magnitude = norm(joy_vec);
        if magnitude > 0
            joy_vec = joy_vec / magnitude;
        end
        isJoyMoved = true;
    end
    
    % ======================== [수정된 부분 끝] ========================
    
    if isJoyMoved
        % Compute new potential position
        movement = joy_vec * movement_speed;
        potential_pos_x = current_pos(1) + movement(1);
        potential_pos_y = current_pos(2) + movement(2);
        
        % Pursuit 단계 전용: 통짜 벽(solid_wall_rect)과의 충돌만 검사합니다.
        if isfield(visual_opt, 'solid_wall_rect')
            if check_wall_collision([potential_pos_x, potential_pos_y], avatar_radius, visual_opt.solid_wall_rect)
                % 충돌 시 위치 업데이트 안함
                potential_pos_x = current_pos(1);
                potential_pos_y = current_pos(2);
            end
        end
        
        % 화면 경계 적용 및 최종 위치 반환
        potential_pos_x = max(screen_left, min(screen_right, potential_pos_x));
        potential_pos_y = max(screen_top, min(screen_bottom, potential_pos_y));
        new_pos = [potential_pos_x, potential_pos_y];
    end
end