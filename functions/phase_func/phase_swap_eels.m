function curr_trial_data = phase_swap_eels(curr_trial_data)
% 이 함수는 choice 단계를 위해, 50% 확률로 eel의 위치 관련 정보를 교환합니다.
% eel의 정체성(순서, 속성)은 유지한 채, 위치 데이터만 바꿉니다.

    % 1. 먼저, choice 단계의 위치(final_side)를 초기 위치(initial_side)와 동일하게 설정합니다.
    
    
    curr_trial_data.eels(1).final_side = curr_trial_data.eels(1).initial_side;
    curr_trial_data.eels(2).final_side = curr_trial_data.eels(2).initial_side;
   
        curr_trial_data.eels(1).original_pos_choice= curr_trial_data.eels(1).eel_pos;
        curr_trial_data.eels(2).original_pos_choice=curr_trial_data.eels(2).eel_pos;
    
        
    
    % 2. 설정된 확률(현재 90%)에 따라 위치 관련 정보들을 교환합니다.
    if rand() < 0.01
        % 'choice' 단계의 eel 위치 (eel_pos_choice) 교환

        temp_eel_pos = curr_trial_data.eels(1).original_pos_choice;
        curr_trial_data.eels(1).eel_pos_choice = curr_trial_data.eels(2).original_pos_choice;
        curr_trial_data.eels(2).eel_pos_choice = temp_eel_pos;
        
        % 'final_side' 값 교환 (데이터 일관성 유지)
        temp_side = curr_trial_data.eels(1).final_side;
        curr_trial_data.eels(1).final_side = curr_trial_data.eels(2).final_side;
        curr_trial_data.eels(2).final_side = temp_side;
        
        % 연관된 물고기 위치(fish_pos)도 함께 교환
        temp_fish_pos = curr_trial_data.eels(1).fish_pos;
        curr_trial_data.eels(1).fish_pos = curr_trial_data.eels(2).fish_pos;
        curr_trial_data.eels(2).fish_pos = temp_fish_pos;
        
        % swap이 일어났음을 기록
        curr_trial_data.eel_swapped_in_choice = true;
    else
        % swap이 일어나지 않았음을 기록
        curr_trial_data.eel_swapped_in_choice = false;
        curr_trial_data.eels(1).eel_pos_choice=curr_trial_data.eels(1).original_pos_choice;
        curr_trial_data.eels(2).eel_pos_choice=curr_trial_data.eels(2).original_pos_choice;
    

    end
end