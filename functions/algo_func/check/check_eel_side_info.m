function [left_eel_curr_pos, right_eel_curr_pos, ...
          left_eel_original_competency, right_eel_original_competency, ...
          left_eel_original_potent, right_eel_original_potent, ...
          left_eel_color, right_eel_color, ...
          left_eel_rely, right_eel_rely, ...
          left_eel_choice_pos, right_eel_choice_pos, ...
          left_eel_shape, right_eel_shape] = ...
          check_eel_side_info(curr_trial_data, game_opt)

    % [최종 수정] 이 함수는 오직 'initial_side'만을 기준으로 왼쪽/오른쪽을 구분합니다.
    % passive view 단계에서는 이 함수가 사용되므로, final_side를 참조해서는 안 됩니다.

    % 먼저, 어느 인덱스(1 또는 2)가 왼쪽(side 1)에 해당하는지 찾습니다.
    if curr_trial_data.eels(1).initial_side == 1
        left_idx = 1;
        right_idx = 2;
    else % eels(2).initial_side가 1일 경우
        left_idx = 2;
        right_idx = 1;
    end
    
    % 이제 찾아낸 인덱스를 사용하여 모든 변수에 값을 정확하게 할당합니다.
    left_eel_curr_pos = curr_trial_data.eels(left_idx).eel_pos;
    right_eel_curr_pos = curr_trial_data.eels(right_idx).eel_pos;

    left_eel_original_competency = curr_trial_data.eels(left_idx).competency;
    right_eel_original_competency = curr_trial_data.eels(right_idx).competency;

    left_eel_original_potent = game_opt.electrical_field;
    right_eel_original_potent = game_opt.electrical_field;

    left_eel_color = curr_trial_data.eels(left_idx).eel_col;
    right_eel_color = curr_trial_data.eels(right_idx).eel_col;

    left_eel_rely = curr_trial_data.eels(left_idx).reliability;
    right_eel_rely = curr_trial_data.eels(right_idx).reliability;

    left_eel_choice_pos = curr_trial_data.eels(left_idx).eel_pos_choice;   
    right_eel_choice_pos = curr_trial_data.eels(right_idx).eel_pos_choice;   

    left_eel_shape = curr_trial_data.eels(left_idx).shape; 
    right_eel_shape = curr_trial_data.eels(right_idx).shape;
end