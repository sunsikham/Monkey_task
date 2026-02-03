function eel_fut_pos = move_eel_passive_view(eel_curr_pos, eel_prev_pos, fish_curr_pos, game_opt)
% move_eel_passive_view Moves the eel toward the average fish position while maintaining smooth momentum.
%
%   eel_fut_pos = move_eel_passive_view(eel_curr_pos, eel_prev_pos, fish_curr_pos, game_opt, visual_opt)
%   computes the centroid of all fish positions and moves the eel smoothly toward that centroid.
%   The step length is determined by game_opt.eel_spd, and momentum is preserved to prevent jitter.
%
%   Inputs:
%       eel_curr_pos  - [x, y] current position of the eel.
%       eel_prev_pos  - [x, y] previous position of the eel (to track momentum).
%       fish_curr_pos - (n x 2) matrix of fish positions.
%       game_opt      - Struct with game options; must include field eel_spd.
%       visual_opt    - Struct with visual options (not used in computation here,
%                       but included for consistency).
%
%   Output:
%       eel_fut_pos   - [x, y] future position of the eel.

    % If no fish exist, do not move the eel.
    if isempty(fish_curr_pos)
        eel_fut_pos = eel_curr_pos;
        return;
    end

    % Compute the centroid of all fish positions.
    target_pos = mean(fish_curr_pos, 1);
    
    % Compute the vector from the eel to the centroid.
    diff_vec = target_pos - eel_curr_pos;
    
    if norm(diff_vec) == 0
        % If the eel is exactly at the centroid, maintain movement in the last direction.
        diff_vec = eel_curr_pos - eel_prev_pos;  
    end
    
    % Normalize the direction vector.
    direction = diff_vec / norm(diff_vec);
    
    % Blend direction with previous movement direction for momentum effect.
    momentum_weight = 0.85;  % Higher value = stronger momentum (less sudden direction changes)
    prev_direction = eel_curr_pos - eel_prev_pos;
    
    if norm(prev_direction) > 0
        prev_direction = prev_direction / norm(prev_direction);  % Normalize
        direction = momentum_weight * prev_direction + (1 - momentum_weight) * direction;
        direction = direction / norm(direction);  % Re-normalize after blending
    end

    % Compute displacement based on the eel speed.
    displacement = game_opt.eel_spd_passive_view * direction;
    
    % Update the eel's future position.
    eel_fut_pos = eel_curr_pos + displacement;
end