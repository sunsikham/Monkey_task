function fish_fut_pos = move_fishes(...
    fish_curr_pos, fish_prev_pos, eel_fut_pos, avtr_fut_pos, ...
    visual_opt, eel_potential, game_opt, eel_strength)
    
    %% Tunable Parameters
 
    
    % Gravitational pull parameters
    R              = game_opt.R;
    
    % Collision avoidance parameters
    fish_size       = game_opt.fish_sz;
    eel_size        = game_opt.eel_sz;
    fish_radius     = fish_size / 2;
    min_separation  = (eel_size + fish_size) * 0.75;
    min_fish_separation = fish_size * 1.2;
    
    % ======================= [수정 1: 화면 경계 정의] =======================
    % 물고기가 화면 밖으로 나가지 않도록, 화면의 상하좌우 경계를 정의합니다.
    screen_left = fish_radius;
    screen_right = visual_opt.wWth - fish_radius;
    screen_top = fish_radius;
    screen_bottom = visual_opt.wHgt - fish_radius;
    % =====================================================================
    
    %% Basic Parameters
    n_fishes     = size(fish_curr_pos, 1);
    fish_fut_pos = zeros(size(fish_curr_pos));
    
    %% Helper Functions
    
    % (Helper Functions 코드는 기존과 동일하므로 생략)
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
    function pos_out = repel_eel(pos_in)
        to_eel = pos_in - eel_fut_pos;
        d_eel = norm(to_eel);
        if d_eel < min_separation && d_eel > 0
            push = (to_eel / d_eel) * min_separation;
            pos_out = eel_fut_pos + push;
        else
            pos_out = pos_in;
        end
    end
    
    %% Nested Helper Functions
    
    function side = determineEelSide(eel_pos, visual_opt)
        corridor_center = visual_opt.wWth / 2;
        corridor_thickness = visual_opt.corridor_thickness;
        corridor_boundary_left = corridor_center - corridor_thickness;
        corridor_boundary_right = corridor_center + corridor_thickness;
        if eel_pos(1) < corridor_boundary_left, side = 'left';
        elseif eel_pos(1) > corridor_boundary_right, side = 'right';
        else, side = 'left'; end
    end
    
    function new_pos = handle_boundary_bounce(start_pos, proposed_pos, movement_vector, visual_opt, side, game_opt)
        corridor_thickness = visual_opt.corridor_thickness;
        corridor_center    = visual_opt.wWth / 2;
        if strcmp(side, 'left')
            corridor_boundary_left = corridor_center - corridor_thickness;
            if proposed_pos(1) > corridor_boundary_left - game_opt.fish_sz * 1.5
                new_pos = start_pos;
                new_pos(1) = corridor_boundary_left - game_opt.fish_sz * 1.5;
                return;
            end
        else % right side
            corridor_boundary_right = corridor_center + corridor_thickness;
            if proposed_pos(1) < corridor_boundary_right + game_opt.fish_sz * 1.5
                new_pos = start_pos;
                new_pos(1) = corridor_boundary_right + game_opt.fish_sz * 1.5;
                return;
            end
        end
        new_pos = proposed_pos;
    end
    
    %% Main Loop: Update Each Fish
    for i = 1:n_fishes
        if fish_curr_pos(i,1) < 0, fish_fut_pos(i,:) = [-1, -1]; continue; end
        
        f_pos = fish_curr_pos(i, :);
        f_prev = fish_prev_pos(i, :);
        
        % 1. ~ 8. : (기존의 움직임 계산 로직은 동일)
        dir_prev = get_prev_direction(f_pos, f_prev);
        d_eel = norm(f_pos - eel_fut_pos);
        d_avatar = norm(f_pos - avtr_fut_pos);
        if d_eel <= eel_potential, speed = game_opt.fast_spd * (1 - eel_strength);
        else, speed = game_opt.fast_spd; end
        if d_eel > R
            pull_vec = eel_fut_pos - f_pos; mag_pull = norm(pull_vec);
            if mag_pull > 1e-6, v_grav = (pull_vec / mag_pull) * game_opt.grav_strength * (mag_pull - R);
            else, v_grav = [0, 0]; end
        else, v_grav = [0, 0]; end
        if d_avatar > 1e-6
            repulsion_strength = game_opt.avatar_repulsion_strength * exp(- (d_avatar / game_opt.avatar_sigma));
            v_avatar = ((f_pos - avtr_fut_pos) / d_avatar) * repulsion_strength;
        else, v_avatar = [0, 0]; end
        v_momentum = dir_prev;
        v_fishavoid = avoid_fish(i, f_pos);
        v_rand = random_unit_vector();
        v_total = game_opt.w_grav*v_grav + game_opt.w_avatar*v_avatar + game_opt.w_momentum*v_momentum + game_opt.w_avoidFish*v_fishavoid + game_opt.w_rand*v_rand;
        if norm(v_total) > 1e-6, v_total = clamp_vec(v_total, 1); else, v_total = [0, 0]; end
        movement_vec = v_total * speed;
        new_pos = f_pos + movement_vec;
        new_pos = repel_eel(new_pos);
        
        % 9. Handle Inner Corridor Boundary
        side = determineEelSide(eel_fut_pos, visual_opt);
        new_pos = handle_boundary_bounce(f_pos, new_pos, movement_vec, visual_opt, side, game_opt);
        
        % ================== [수정 2: 화면 경계 충돌 처리 추가] ==================
        % 10. Handle Outer Screen Boundaries
        % 계산된 최종 위치가 화면 밖으로 나가지 않도록 x, y 좌표를 각각 보정합니다.
        new_pos(1) = max(screen_left, min(screen_right, new_pos(1)));
        new_pos(2) = max(screen_top, min(screen_bottom, new_pos(2)));
        % ======================================================================
        
        % 11. Assign New Position
        fish_fut_pos(i, :) = new_pos;
    end
end 