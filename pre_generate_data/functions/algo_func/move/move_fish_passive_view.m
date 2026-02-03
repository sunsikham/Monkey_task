function fish_fut_pos = move_fish_passive_view(...
    fish_curr_pos, fish_prev_pos, eel_fut_pos, ...
    visual_opt, eel_potential, game_opt, eel_strength, side)
    
    %% Parameters
    fish_size = game_opt.fish_sz;
    min_fish_separation = fish_size * 1.5;
    
    screen_width  = visual_opt.wWth;
    screen_height = visual_opt.wHgt;
    corridor_center = screen_width / 2;
    
    % Determine the center of the allowed region based on the side of the screen
    if strcmp(side, 'left')
        region_center = [corridor_center/2, screen_height/2];
    elseif strcmp(side, 'right')
        region_center = [corridor_center + (screen_width - corridor_center)/2, screen_height/2];
    else
        % Default to left if side is not recognized
        region_center = [corridor_center/2, screen_height/2];
    end
    
    % The allowed movement radius (R) is now centered on the side region
    region_radius = game_opt.passive_view_radius;
    
    %% Basic Parameters
    n_fishes = size(fish_curr_pos, 1);
    fish_fut_pos = zeros(size(fish_curr_pos));
    
    %% Helper Functions
    
    % Clamp a vector to a maximum length
    function v_out = clamp_vec(v_in, max_len)
        mag = norm(v_in);
        if mag > max_len
            v_out = (v_in / mag) * max_len;
        else
            v_out = v_in;
        end
    end

    % Generate a random unit vector
    function v_rand = random_unit_vector()
        theta = 2 * pi * rand;
        v_rand = [cos(theta), sin(theta)];
    end

    % Compute the previous movement direction (for momentum)
    function dir_out = get_prev_direction(curr_pos, prev_pos)
        dir_out = [0, 0];
        if all(prev_pos > 0)
            delta = curr_pos - prev_pos;
            d = norm(delta);
            if d > 1e-6
                dir_out = delta / d;
            end
        end
    end

    % Avoid collisions with other fish
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

    % Handle boundaries to keep fish within the allowed region and on-screen
    function new_pos = handle_region_boundary(start_pos, proposed_pos, region_center, region_radius, fish_size, screen_width, screen_height)
        % First, ensure the fish remains within the circular region
        vec = proposed_pos - region_center;
        dist = norm(vec);
        if dist > region_radius
            % Clamp the position to the edge of the allowed region
            proposed_pos = region_center + (vec / dist) * region_radius;
        end
        
        % Then, ensure the fish stays entirely within the screen boundaries
        if proposed_pos(1) < fish_size
            proposed_pos(1) = fish_size;
        elseif proposed_pos(1) > (screen_width - fish_size)
            proposed_pos(1) = screen_width - fish_size;
        end
        
        if proposed_pos(2) < fish_size
            proposed_pos(2) = fish_size;
        elseif proposed_pos(2) > (screen_height - fish_size)
            proposed_pos(2) = screen_height - fish_size;
        end
        
        new_pos = proposed_pos;
    end

    % Determine the speed based on proximity to the eel
    function spd = determine_speed(f_pos, eel_pos, eel_potential, fast_spd, slow_spd)
        d_eel = norm(f_pos - eel_pos);
        if d_eel <= eel_potential
            spd = slow_spd;  % Slow down within the danger zone
        else
            spd = fast_spd;
        end
    end

    %% Main Loop: Update Each Fish
    for i = 1:n_fishes
        % Skip inactive fish
        if fish_curr_pos(i,1) < 0 && fish_curr_pos(i,2) < 0
            fish_fut_pos(i,:) = [-1, -1];
            continue;
        end
        
        % Current and previous positions
        f_pos = fish_curr_pos(i, :);
        f_prev = fish_prev_pos(i, :);
        
        % 1. Momentum from previous movement
        v_momentum = get_prev_direction(f_pos, f_prev);
        
        % 2. Determine speed based on eel proximity
        speed = determine_speed(f_pos, eel_fut_pos, eel_potential, game_opt.fast_spd, eel_strength);
        
        % 3. Random wandering component
        v_rand = random_unit_vector();
        
        % 4. Collision avoidance between fish
        v_fishavoid = avoid_fish(i, f_pos);
        
        % 5. Combine movement vectors with respective weights
        v_total = game_opt.w_momentum * v_momentum + ...
                  game_opt.w_rand * v_rand + ...
                  game_opt.w_avoidFish * v_fishavoid;
              
        % Normalize the vector if nonzero to prevent jitter
        if norm(v_total) > 1e-6
            v_total = clamp_vec(v_total, 1);
        else
            v_total = [0, 0];
        end
        
        movement_vec = v_total * speed;
        
        % 6. Compute tentative new position
        new_pos = f_pos + movement_vec;
        
        % 7. Keep the fish within the allowed circular region and on-screen
        new_pos = handle_region_boundary(f_pos, new_pos, region_center, region_radius, fish_size, screen_width, screen_height);
        
        % 8. Assign the new position
        fish_fut_pos(i, :) = new_pos;
    end
end
