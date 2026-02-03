function draw_eel(eel_pos, eel_color, obj_size, visual_opt, eel_pot, game_opt, eel_shape)
    %% Function to draw the eel and optionally display its potential radius,
    %  now with a black border around the filled shape.
    %
    % Inputs:
    %   eel_pos    - [x, y] position of the eel
    %   eel_color  - RGB color (1×3 vector, values 0–255) for the eel fill
    %   obj_size   - Scalar size (radius/half‐width) for the shape
    %   visual_opt - Struct with fields:
    %                  · winPtr            : Psychtoolbox window pointer
    %                  · visualize_pot     : boolean, draw potential circle if true
    %                  · alpha             : blending factor [0–1] for potential circle
    %                  · visualize_radius  : boolean, draw larger radius R if true
    %   eel_pot    - Scalar radius of the eel’s small potential field
    %   game_opt   - Struct with fields:
    %                  · R                 : larger radius for frame circle (optional)
    %   eel_shape  - (Optional) string indicating shape: 
    %                  'triangle', 'hexagon', 'star', 'diamond', 'pentagon'
    %
    % Behavior:
    % 1) Draw the eel’s potential circle (semi‐transparent).
    % 2) Compute vertices for the specified shape, fill with eel_color.
    % 3) Draw a 1–2px thick black border (FramePoly) around that polygon.
    % 4) Optionally draw a larger semi‐transparent radius R around the eel.

    % 1) Draw potential field (semi‐transparent circle) if requested
    if isfield(visual_opt, 'visualize_pot') && visual_opt.visualize_pot && eel_pot > 0
        % Clamp alpha between 0 (opaque) and 1 (fully transparent)
        alpha = min(max(visual_opt.alpha, 0), 1);
        % Blend eel_color toward white by alpha
        final_color = round((1 - alpha) * eel_color + alpha * [255, 255, 255]);
        destRect = [eel_pos(1) - eel_pot, eel_pos(2) - eel_pot, ...
                    eel_pos(1) + eel_pot, eel_pos(2) + eel_pot];
        Screen('FillOval', visual_opt.winPtr, final_color, destRect);
    end

    % 2) Determine shape vertices (default = triangle)
    if nargin < 7 || isempty(eel_shape)
        eel_shape = 'triangle';
    end
    eel_shape = lower(eel_shape);

    switch eel_shape
        case 'triangle'
            % Equilateral triangle pointing upward
            angles = [pi/2, -pi/6, -5*pi/6];
            vertices = zeros(3, 2);
            for i = 1:3
                vertices(i, :) = [ ...
                    eel_pos(1) + obj_size * cos(angles(i)), ...
                    eel_pos(2) - obj_size * sin(angles(i)) ...
                ];
            end

        case 'hexagon'
            % Regular hexagon
            vertices = zeros(6, 2);
            for i = 1:6
                angle = (i - 1) * (2 * pi / 6);
                vertices(i, :) = [ ...
                    eel_pos(1) + obj_size * cos(angle), ...
                    eel_pos(2) + obj_size * sin(angle) ...
                ];
            end

        case 'star'
            % 5‐pointed star: 10 vertices alternating outer/inner
            vertices = zeros(10, 2);
            outer_radius = obj_size;
            inner_radius = obj_size * 0.4;
            for i = 1:5
                angle_outer = (i - 1) * (2*pi/5) - pi/2;
                vertices(2*i - 1, :) = [ ...
                    eel_pos(1) + outer_radius * cos(angle_outer), ...
                    eel_pos(2) + outer_radius * sin(angle_outer) ...
                ];
                angle_inner = angle_outer + pi/5;
                vertices(2*i, :) = [ ...
                    eel_pos(1) + inner_radius * cos(angle_inner), ...
                    eel_pos(2) + inner_radius * sin(angle_inner) ...
                ];
            end

        case 'diamond'
            % Diamond (rotated square)
            vertices = [ ...
                eel_pos(1),           eel_pos(2) - obj_size;  % Top
                eel_pos(1) + obj_size, eel_pos(2);            % Right
                eel_pos(1),           eel_pos(2) + obj_size;  % Bottom
                eel_pos(1) - obj_size, eel_pos(2)             % Left
            ];

        case 'pentagon'
            % Regular pentagon
            vertices = zeros(5, 2);
            for i = 1:5
                angle = (i - 1) * (2*pi/5) - pi/2;
                vertices(i, :) = [ ...
                    eel_pos(1) + obj_size * cos(angle), ...
                    eel_pos(2) + obj_size * sin(angle) ...
                ];
            end

        otherwise
            % Fallback to triangle
            warning('Unrecognized eel_shape "%s"; defaulting to triangle.', eel_shape);
            angles = [pi/2, -pi/6, -5*pi/6];
            vertices = zeros(3, 2);
            for i = 1:3
                vertices(i, :) = [ ...
                    eel_pos(1) + obj_size * cos(angles(i)), ...
                    eel_pos(2) - obj_size * sin(angles(i)) ...
                ];
            end
    end

    % 3) Draw the filled polygon
    Screen('FillPoly', visual_opt.winPtr, eel_color, vertices);

    % 4) Draw a thin black frame around that polygon
    %    Using FramePoly with penWidth = 2 pixels
    border_color = [0, 0, 0];  % pure black
    penWidth = 2;
    Screen('FramePoly', visual_opt.winPtr, border_color, vertices, penWidth);

    % 5) Optionally draw the larger radius R (semi‐transparent outline)
    if isfield(game_opt, 'R') && game_opt.R > 0 ...
       && isfield(visual_opt, 'visualize_radius') && visual_opt.visualize_radius
        outline_color = [0, 100, 255, 128];  % semi-transparent blue (RGBA)
        radiusRect   = [eel_pos(1) - game_opt.R, eel_pos(2) - game_opt.R, ...
                        eel_pos(1) + game_opt.R, eel_pos(2) + game_opt.R];
        Screen('FrameOval', visual_opt.winPtr, outline_color, radiusRect, 3);
    end
end
