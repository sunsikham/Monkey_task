function draw_scene_pursuit_both(visual_opt, game_opt, data, phase_str, loop_start_t, avtr_curr_pos, ...
                            chosen_eel_pos, chosen_fish_pos, chosen_eel_color, chosen_eel_shape, chosen_eel_pot, ...
                            unchosen_eel_pos, unchosen_fish_pos, unchosen_eel_color, unchosen_eel_shape, unchosen_eel_pot, ...
                            caught_fish_data, chosen_side)
% DRAW_SCENE_PURSUIT - 추격 단계의 모든 그래픽 요소를 한 번에 그립니다.
%
% 이 함수는 선택된 객체와 선택되지 않은 객체를 모두 받아 버퍼에 그린 후,
% 마지막에 단 한 번의 Screen('Flip')으로 화면을 갱신하여 깜빡임(flickering)을 방지합니다.

    phase_start_time = data.(phase_str).phase_start;
    
    % =================================================================
    % STEP 1: 모든 객체를 버퍼에 그리기 (화면 표시는 아직 안 함)
    % =================================================================
    
    % 복도 그리기
    draw_corridor_pursuit(visual_opt);
    
    % 물고기 배터리(점수판) 그리기
    draw_fish_battery(visual_opt, data.(phase_str).left_fish_caught, data.(phase_str).right_fish_caught, game_opt);
    
    % 선택된 장어(eel) 그리기
    if ~isempty(chosen_eel_pos)
        draw_eel(chosen_eel_pos, chosen_eel_color, 150, ...
                 visual_opt, chosen_eel_pot, game_opt, chosen_eel_shape);
    end
    
    % 선택되지 않은 장어(eel) 그리기
    if ~isempty(unchosen_eel_pos)
        draw_eel(unchosen_eel_pos, unchosen_eel_color, 150, ...
                 visual_opt, unchosen_eel_pot, game_opt, unchosen_eel_shape);
    end
    
    % 물고기 색상 계산 (시간에 따라 어두워짐)
    current_time = GetSecs();
    elapsed_time = current_time - phase_start_time;
    fish_darkening_factor = max(0, 1 - elapsed_time / game_opt.pursuit_time);
    darkened_fish_color = round(visual_opt.color_fish * fish_darkening_factor);
    
    % 선택된 물고기들 그리기
    if ~isempty(chosen_fish_pos)
        draw_fishes(chosen_fish_pos, darkened_fish_color, game_opt.fish_sz, visual_opt.winPtr);
    end
    
    % 선택되지 않은 물고기들 그리기
    if ~isempty(unchosen_fish_pos)
        draw_fishes(unchosen_fish_pos, darkened_fish_color, game_opt.fish_sz, visual_opt.winPtr);
    end
       
    % 잡힌 물고기 애니메이션 그리기
    if ~isempty(caught_fish_data) && ~isempty(caught_fish_data.positions)
        draw_caught_fish(caught_fish_data, game_opt, visual_opt);
    end
    
    % 아바타 그리기
    draw_avatar(avtr_curr_pos, visual_opt.pursuit_color_avtr, game_opt.avatar_sz, visual_opt.winPtr);
    
    % 타이머 그리기
    draw_timers(visual_opt, game_opt, phase_start_time, GetSecs(), chosen_side);
    
    % =================================================================
    % STEP 2: 버퍼에 그려진 모든 내용을 화면에 한 번에 표시
    % =================================================================
    timestamp = Screen('Flip', visual_opt.winPtr);
    
    % (Optional) 프레임 시간 계산 - 디버깅에 유용
    frame_time = timestamp - loop_start_t;
end
