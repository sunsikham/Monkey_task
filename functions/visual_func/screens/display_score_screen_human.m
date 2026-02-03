function [data, all_trials] = display_score(data, visual_opt, game_opt, device_opt, all_trials)
    phase_str = 'score';
    data.(phase_str).phase_start = GetSecs();

    % 남은 추격 시간(표시용)
    time = game_opt.pursuit_time - data.PURSUIT.phase_duration;
    fraction_remaining = time / game_opt.pursuit_time;

    % 총 잡은 물고기 수
    total_fish_caught = data.PURSUIT.caught_fish_count;

    % 화면 초기화 (회색 배경)
    SCREEN_COLOR = [128 128 128];
    Screen('FillRect', visual_opt.winPtr, SCREEN_COLOR);

    % 보상 정보 구조체
    data.reward_info = struct();
    data.reward_info.fish_caught = total_fish_caught;
    data.reward_info.time_remaining = time;
    data.reward_info.fraction_remaining = fraction_remaining;

    % 원 표시 설정
    numCircles        = 3;        % 최대 표시할 원 개수
    circleRadius      = 30;
    horizontalSpacing = 80;
    screenX = visual_opt.wWth / 2;
    screenY = visual_opt.wHgt / 2;

    % 색상 정의
    GREEN      = [0 255 0];
    RED        = [255 0 0];
    MUTE_GRAY  = [180 180 180];

    % 어떤 도형을 선택했는지에 따라 채울 색
    if data.CHOICE.choice == 1
        fillColor = GREEN;
    else
        fillColor = RED;
    end

    % 원 그리기: 잡은 수만큼 채우고 나머지는 회색
    n_fill = min(total_fish_caught, numCircles);
    for i = 1:numCircles
        % 중심 좌표 계산
        cx = screenX + (i - (numCircles+1)/2) * horizontalSpacing;
        cy = screenY;
        ovalRect = [cx - circleRadius, cy - circleRadius, cx + circleRadius, cy + circleRadius];

        if i <= n_fill
            Screen('FillOval', visual_opt.winPtr, fillColor, ovalRect);
        else
            Screen('FrameOval', visual_opt.winPtr, MUTE_GRAY, ovalRect, 3);
        end
    end

    % 화면 업데이트
    Screen('Flip', visual_opt.winPtr);

    % 보상 지급 (잡은 물고기 수에 비례)
    if total_fish_caught > 0
        if data.CHOICE.choice == 1
            give_reward(device_opt, 1 * total_fish_caught);
        else
            give_reward(device_opt, 0.1 * total_fish_caught);
        end
        data.reward_info.reward_given = true;
    else
        data.reward_info.reward_given = false;
    end

    % 스코어 화면 유지
    start_time = GetSecs();
    while (GetSecs() - start_time) < game_opt.score_time
        loop_start_t = GetSecs();
        check_duration(loop_start_t, 1 / visual_opt.refresh_rate, device_opt.min_t_scale);
    end

    % 종료 로그
    data.(phase_str).phase_end = GetSecs();
    data.(phase_str).phase_duration = data.(phase_str).phase_end - data.(phase_str).phase_start;
end
