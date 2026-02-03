function fish_fut_pos = move_fishes_no_eel(fish_curr_pos, fish_prev_pos, avtr_fut_pos, game_opt,upper_rect)
    % move_fishes_no_eel - 장어의 영향 없이 물고기의 움직임을 계산합니다.

    %% Tunable Parameters
    fish_size       = game_opt.fish_sz;
    fish_radius     = fish_size / 2;
    min_fish_separation = fish_size * 1.2;
    
    % 화면 경계 정의
    screen_left   = upper_rect(1) + fish_radius;
    screen_right  = upper_rect(3) - fish_radius;
    screen_top    = upper_rect(2) + fish_radius;
    screen_bottom = upper_rect(4) - fish_radius;
    
    %% Basic Parameters
    n_fishes     = size(fish_curr_pos, 1);
    fish_fut_pos = zeros(size(fish_curr_pos));
    
    %% Helper Functions (필요한 함수만 남김)
    function v_out = clamp_vec(v_in, max_len)
        mag = norm(v_in);
        if mag > max_len, v_out = (v_in / mag) * max_len; else, v_out = v_in; end
    end
    function v_rand = random_unit_vector()
        theta = 2 * pi * rand;
        v_rand = [cos(theta), sin(theta)];
    end
    function dir_out = get_prev_direction(curr_pos, prev_pos)
        dir_out = [0, 0];
        if all(prev_pos > 0)
            delta = curr_pos - prev_pos;
            d = norm(delta);
            if d > 1e-6, dir_out = delta / d; end
        end
    end
    function v_avoid = avoid_fish(f_idx, curr_pos)
        v_avoid = [0, 0];
        for j = 1:n_fishes
            if j == f_idx, continue; end
            other_pos = fish_curr_pos(j, :);
            if any(other_pos < 0), continue; end
            dist_f = norm(curr_pos - other_pos);
            if dist_f < min_fish_separation && dist_f > 0
                repulsion_dir = (curr_pos - other_pos) / dist_f;
                overlap = (min_fish_separation - dist_f) / min_fish_separation;
                v_avoid = v_avoid + (repulsion_dir * overlap);
            end
        end
    end
    
    %% Main Loop: Update Each Fish
    for i = 1:n_fishes
        if fish_curr_pos(i,1) < 0, fish_fut_pos(i,:) = [-1, -1]; continue; end
        
        f_pos = fish_curr_pos(i, :);
        f_prev = fish_prev_pos(i, :);
        
        % --- 장어 관련 기능 삭제 ---
        % 1. 아바타와의 거리 및 척력 계산
        d_avatar = norm(f_pos - avtr_fut_pos);
        if d_avatar > 1e-6
            repulsion_strength = game_opt.avatar_repulsion_strength * exp(- (d_avatar / game_opt.avatar_sigma));
            v_avatar = ((f_pos - avtr_fut_pos) / d_avatar) * repulsion_strength;
        else
            v_avatar = [0, 0];
        end

        % 2. 나머지 힘 계산 (관성, 물고기 회피, 무작위)
        v_momentum = get_prev_direction(f_pos, f_prev);
        v_fishavoid = avoid_fish(i, f_pos);
        v_rand = random_unit_vector();
        
        % 3. 모든 힘을 합산
        % --- 장어 인력(w_grav) 부분 삭제 ---
        v_total = game_opt.w_avatar*v_avatar + game_opt.w_momentum*v_momentum + game_opt.w_avoidFish*v_fishavoid + game_opt.w_rand*v_rand;
        if norm(v_total) > 1e-6
            v_total = clamp_vec(v_total, 1); 
        else
            v_total = [0, 0]; % 움직일 힘이 없으면 멈춤
        end

        % 4. 최종 움직임 계산
        speed = game_opt.fast_spd; % --- 속도를 상수로 고정 ---
        movement_vec = v_total * speed;
        new_pos = f_pos + movement_vec;
        
        % --- 장어 충돌 및 중앙 경계 로직 삭제 ---
        
        % 5. 화면 경계 처리
        new_pos(1) = max(screen_left, min(screen_right, new_pos(1)));
        new_pos(2) = max(screen_top, min(screen_bottom, new_pos(2)));
        
        % 6. 새로운 위치 할당
        fish_fut_pos(i, :) = new_pos;
    end
end