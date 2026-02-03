function fish_pos = generate_fish_locs_passive_view(side, game_opt, visual_opt)
% generate_fish_locs Generates fish positions around the center of a given side.
%
%   fish_pos = generate_fish_locs(side, game_opt, visual_opt) generates an
%   (n_fishes x 2) array of fish positions for the specified side ('left' or 'right')
%   of the screen. The fish are distributed randomly around the center of that side,
%   within a radial distance defined by game_opt.fish_init_min_r and 
%   game_opt.fish_init_max_r. Additionally, positions that would place a fish in 
%   the middle corridor are adjusted using a buffer zone.
%
%   Inputs:
%       side      - A string: 'left' or 'right' (determines which side's center is used)
%       game_opt  - A structure with game options. Required fields:
%                     .n_fishes           : Number of fish to generate for that side
%                     .fish_init_min_r    : Minimum distance from the center of the side
%                     .fish_init_max_r    : Maximum distance from the center of the side
%       visual_opt- A structure with visual options. Required fields:
%                     .wWth               : Screen width
%                     .wHth               : Screen height
%                     .corridor_coord     : A matrix (at least 3 rows) where:
%                                             row 1, col 1 is the left boundary of the corridor,
%                                             row 3, col 1 is the right boundary.
%                     .corridor_thickness : Buffer in pixels to avoid near the corridor
%
%   Output:
%       fish_pos  - An (n_fishes x 2) array of fish [x, y] positions.
%

    % Define screen dimensions.
    screen_width  = visual_opt.wWth;
    screen_height = visual_opt.wHgt;
    
    % Extract middle corridor boundaries and define a buffer zone.
    middle_left  = visual_opt.corridor_coord(1, 1);  % Left boundary of corridor.
    middle_right = visual_opt.corridor_coord(3, 1);  % Right boundary of corridor.
    buffer_zone  = visual_opt.corridor_thickness;      % Buffer to avoid the corridor.
    
    % Determine the center of fish generation based on the specified side.
    switch lower(side)
        case 'left'
            center_pos = [screen_width * 0.25, screen_height / 2];
        case 'right'
            center_pos = [screen_width * 0.75, screen_height / 2];
        otherwise
            error('Invalid side. Use "left" or "right".');
    end

    % Number of fish to generate for this side.
    n_fishes = game_opt.n_fishes;
    fish_pos = zeros(n_fishes, 2);

    % Radial limits for fish placement.
    min_r = game_opt.fish_init_min_r;
    max_r = game_opt.fish_init_max_r;

    for i = 1:n_fishes
        % Generate a random radial distance between min_r and max_r.
        r = min_r + (max_r - min_r) * rand();
        
        % Generate an angle that biases fish to remain on the same side.
        % For left side: restrict angle to [pi/2, 3pi/2] (left half of the circle).
        % For right side: restrict angle to [-pi/2, pi/2] (right half of the circle).
        switch lower(side)
            case 'left'
                theta = pi/2 + pi * rand();   % Angle from 90° to 270°.
            case 'right'
                theta = -pi/2 + pi * rand();   % Angle from -90° to 90°.
        end
        
        % Convert polar coordinates to Cartesian coordinates relative to center.
        x = center_pos(1) + r * cos(theta);
        y = center_pos(2) + r * sin(theta);
        
        % Ensure fish do not fall into the middle corridor.
        switch lower(side)
            case 'left'
                if x > (middle_left - buffer_zone)
                    x = middle_left - buffer_zone;
                end
            case 'right'
                if x < (middle_right + buffer_zone)
                    x = middle_right + buffer_zone;
                end
        end
        
        % Optionally, add a small random jitter to avoid perfect alignment.
        jitter = 5; % Adjust this value as needed.
        x = x + (rand() - 0.5) * jitter;
        y = y + (rand() - 0.5) * jitter;
        
        fish_pos(i, :) = [x, y];
    end
end
