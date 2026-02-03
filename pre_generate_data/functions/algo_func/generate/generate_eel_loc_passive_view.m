function eel_pos = generate_eel_loc_passive_view(side, game_opt, visual_opt)
% generate_eel_loc Generates the initial eel position for a given side.
%
%   eel_pos = generate_eel_loc(side, game_opt, visual_opt) returns a 1x2 vector 
%   representing the initial eel position. The eel is initialized near one of the
%   "corners" for the specified side ('left' or 'right') of the screen. The
%   corridor boundary (in the middle) is also considered as a candidate corner.
%
%   Inputs:
%       side      - A string: 'left' or 'right'.
%       game_opt  - A structure with game options (may include custom offsets).
%       visual_opt- A structure with visual options. Required fields:
%                     .wWth           : Screen width.
%                     .wHth           : Screen height.
%                     .corridor_coord : A matrix where:
%                                        row 1, col 1 is the left boundary of the corridor,
%                                        row 3, col 1 is the right boundary.
%
%   Output:
%       eel_pos   - A 1x2 vector [x, y] representing the eel's initial position.
%

    % Define a default margin (offset) from the screen edges and corridor boundaries.
    margin = game_opt.margin;           % Adjust this value as needed or get from game_opt.
    jitter_amount = game_opt.jistter_amount;    % Maximum random jitter to avoid perfect alignment.
    
    % Get screen dimensions.
    screen_width  = visual_opt.wWth;
    screen_height = visual_opt.wHgt;
    
    % Based on the side, define candidate positions.
    switch lower(side)
        case 'left'
            % For the left side, candidates include:
            %   - Top-left and bottom-left from the screen edge.
            %   - Positions near the left corridor boundary.
            candidate1 = [margin, margin];                      % Top left from screen edge.
            candidate2 = [margin, screen_height - margin];        % Bottom left from screen edge.
            candidate3 = [visual_opt.corridor_coord(1,1) - margin, margin];            % Top left near corridor.
            candidate4 = [visual_opt.corridor_coord(1,1) - margin, screen_height - margin]; % Bottom left near corridor.
            
            candidates = [candidate1; candidate2; candidate3; candidate4];
            
        case 'right'
            % For the right side, candidates include:
            %   - Top-right and bottom-right from the screen edge.
            %   - Positions near the right corridor boundary.
            candidate1 = [screen_width - margin, margin];                     % Top right from screen edge.
            candidate2 = [screen_width - margin, screen_height - margin];       % Bottom right from screen edge.
            candidate3 = [visual_opt.corridor_coord(3,1) + margin, margin];       % Top right near corridor.
            candidate4 = [visual_opt.corridor_coord(3,1) + margin, screen_height - margin]; % Bottom right near corridor.
            
            candidates = [candidate1; candidate2; candidate3; candidate4];
            
        otherwise
            error('Invalid side. Use "left" or "right".');
    end
    
    % Randomly select one candidate position.
    idx = randi(size(candidates, 1));
    eel_pos = candidates(idx, :);
    
    % Add a small random jitter to avoid perfect alignment.
    eel_pos = eel_pos + (rand(1,2) - 0.5) * jitter_amount;
end
