function avtr_curr_pos = generate_rand_avatar_start_pos(data, visual_opt, game_opt)
    % Function to generate a random valid avatar starting position or use a default position.
    % Ensures the avatar does not initialize outside screen boundaries, considering its size.
    %
    % Inputs:
    % - data: Struct containing eel positions and potentials, and default start position.
    % - visual_opt: Struct containing visual boundaries and corridor settings.
    % - game_opt: Struct containing game settings, including random start toggle and avatar size.
    %
    % Outputs:
    % - avtr_curr_pos: Calculated or default avatar position [x, y].

    if game_opt.avatar_rand_start
        % Define screen boundaries adjusted for avatar size
        screen_left = game_opt.avatar_sz;
        screen_right = visual_opt.wWth - game_opt.avatar_sz;
        screen_top = game_opt.avatar_sz;
        screen_bottom = visual_opt.wHgt - game_opt.avatar_sz;

        % Define corridor boundaries
        corridor_center = visual_opt.wWth / 2;
        corridor_left = corridor_center - visual_opt.corridor_thickness;
        corridor_right = corridor_center + visual_opt.corridor_thickness;

        % Initialize a flag for valid position
        valid_position = false;

        while ~valid_position
            % Generate random position
            random_x = randi([screen_left, screen_right]);
            random_y = randi([screen_top, screen_bottom]);

            % Check if the random position is outside the corridor
            outside_corridor = random_x < corridor_left || random_x > corridor_right;

            % Initialize no_overlap as true
            no_overlap = true;

            % Check overlap with eel positions and potentials
            if isfield(data, 'left_eel_pos') && ~isempty(data.left_eel_pos) && ...
                    pdist2([random_x, random_y], data.left_eel_pos) < (data.left_eel_pot_final + game_opt.avatar_sz)
                no_overlap = false;
            end
            if isfield(data, 'right_eel_pos') && ~isempty(data.right_eel_pos) && ...
                    pdist2([random_x, random_y], data.right_eel_pos) < (data.right_eel_pot_final + game_opt.avatar_sz)
                no_overlap = false;
            end

            % Mark position as valid if all conditions are met
            valid_position = outside_corridor && no_overlap;
        end

        % Assign random position to avatar
        avtr_curr_pos = [random_x, random_y];
    else
        % Default starting position
        avtr_curr_pos = [data.avtr_start_pos(1), data.avtr_start_pos(2)];
    end
end