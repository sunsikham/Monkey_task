function [data, all_trials] = display_score(data, visual_opt, game_opt, device_opt, all_trials,max_fish,max_time)
    
    phase_str = 'SCORE';

    % SCORE phase struct 초기화
    if ~isfield(data, phase_str)
        data.(phase_str) = struct();
    end
    data.(phase_str).phase_start = GetSecs();

    % 남은 추격 시간(표시용)
    time = game_opt.pursuit_time - data.PURSUIT.phase_duration;
    fraction_remaining = time / game_opt.pursuit_time;

    % 총 잡은 물고기 수
    total_fish_caught = data.PURSUIT.caught_fish_count;

    SCREEN_COLOR = [0 0 0];
    Screen('FillRect', visual_opt.winPtr, SCREEN_COLOR);

    % 보상 정보 구조체
    data.reward_info = struct();
    data.reward_info.fish_caught = total_fish_caught;
    data.reward_info.time_remaining = time;
    data.reward_info.fraction_remaining = fraction_remaining;
    
    % 원 표시 설정

    fish_curr_pos = data.CHOICE.final_fish_pos;
    numCircles        = size(fish_curr_pos,1);        % 최대 표시할 원 개수
    circleRadius      = 30;
    horizontalSpacing = 80;
    screenX = visual_opt.wWth / 2;
    screenY = visual_opt.wHgt / 2;

    % 색상 정의
    GREEN      = [0 255 0];
    RED        = [255 0 0];
    BLUE       = [0 0 255];
    MUTE_GRAY  = [255 255 255,100];
    GRAY= [128 128 128];

    % 어떤 도형을 선택했는지에 따라 채울 색
    if isequal(data.color, [0 255 0])
        fillColor = GREEN;
    elseif isequal(data.color,[255 0 0] )
        fillColor = RED;
    elseif isequal(data.color,[0 0 255] )
        fillColor=BLUE;
    else
        fillColor=  GRAY;
    end

    % 원/배경 그리기 함수 (보상 대기 중에도 유지)
    function draw_score_frame()
        Screen('FillRect', visual_opt.winPtr, SCREEN_COLOR);
        n_fill = min(total_fish_caught, numCircles);
        for i = 1:numCircles
            cx = screenX + (i - (numCircles+1)/2) * horizontalSpacing;
            cy = screenY;
            ovalRect = [cx - circleRadius, cy - circleRadius, cx + circleRadius, cy + circleRadius];
            if i <= n_fill
                Screen('FillOval', visual_opt.winPtr, fillColor, ovalRect);
            else
                Screen('FillOval', visual_opt.winPtr, MUTE_GRAY, ovalRect);
            end
        end
    end

    draw_score_frame();
    Screen('Flip', visual_opt.winPtr);


    
   %% 삼각형 회색 (GRAY TRIANGLE YOU ADUJUST THIS NUMBER)
    reward_duration = 0;
    if isequal(data.color, [128 128 128])
     
            switch total_fish_caught
                case 1
                      reward_duration = 0;
                     
                case 2
                     reward_duration = 0;
                case 3
                    reward_duration = 0.0;
                case 4
                    reward_duration = 1.6;
                case 5
                    reward_duration = 1.6;
                case 6
                    reward_duration = 2.6;
                case 7
                    reward_duration = 6;
                case 8
                    reward_duration = 6.5;
                otherwise
                    % 3~7마리가 아닌 경우 (예: 2마리 이하)
                    % 보상을 0 또는 다른 값으로 설정할 수 있습니다.
                    reward_duration = 0;
            end
     
    end


    
    disp('reward duration is:')
    disp(reward_duration)
    disp('----------------------')
    % 시간으로 패널티 주는 로직
    % ── 1) 보상 시간 계산 ---------------------------------------------------
   
    max_reward_duration = 1.5;               % 5마리 기준 최대

    % ── 2) 보상 재생 (렌더 루프 유지) -------------------------------------
    reward_on = false;
    if total_fish_caught > 0 && reward_duration > 0
        data.reward_info.reward_given = true;
        if device_opt.ARDUINO
            writeDigitalPin(device_opt.arduino, 'D2', device_opt.activate_arduino);
            reward_on = true;
        end
    else
        data.reward_info.reward_given = false;
    end

    % ── 3) 보상 시간 동안 화면 업데이트 유지 -------------------------------
    total_hold = max(max_reward_duration, reward_duration);
    t0 = GetSecs;
    while (GetSecs - t0) < total_hold
        if reward_on && (GetSecs - t0) >= reward_duration
            writeDigitalPin(device_opt.arduino, 'D2', ~device_opt.activate_arduino);
            reward_on = false;
        end
        draw_score_frame();
        Screen('Flip', visual_opt.winPtr);
        WaitSecs('YieldSecs', 0.005);
    end
    if reward_on
        writeDigitalPin(device_opt.arduino, 'D2', ~device_opt.activate_arduino);
    end
    %---- 물고기 못 잡은 만큼 패널티 
  

   

    

    % 종료 로그
    data.(phase_str).phase_end = GetSecs();
    data.(phase_str).phase_duration = data.(phase_str).phase_end - data.(phase_str).phase_start;

end
