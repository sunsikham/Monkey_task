function [curr_trial_data, game_opt] = generate_eels_dynamically(curr_trial_data, visual_opt, game_opt)
    % GENERATE_EELS_DYNAMICALLY - Generates eel information on-the-fly
    %
    % This function creates eel data for the current trial using the same
    % switching logic as in the premade trials.
    
    % Ensure we have total trials defined
    if ~isfield(game_opt, 'n_trials')
        game_opt.n_trials = 350; % Default if not specified
    end

    % If not provided, define a default wall of size 100x100 pixels.
    if ~isfield(visual_opt, 'wall_rect')
        wall_width = 50; 
        wall_height = 100;
        visual_opt.wall_rect = [visual_opt.wWth/2 - wall_width/2, ...
                                visual_opt.wHgt/2 - wall_height/2, ...
                                wall_width, wall_height];
    end

    % Handle eel shapes
    if curr_trial_data.trial_idx == 1
        % First trial - initialize shapes
        if game_opt.n_eels == 2
            % Fixed shapes for 2 eels
            game_opt.eel_shapes = cell(1, 2);
            game_opt.eel_shapes{1} = 'triangle';
            game_opt.eel_shapes{2} = 'hexagon';
        else
            % Random shapes for more eels
            shapes = {'triangle', 'hexagon', 'star', 'diamond', 'pentagon'};
            indices = randperm(length(shapes), game_opt.n_eels);
            
            game_opt.eel_shapes = cell(1, game_opt.n_eels);
            for i = 1:game_opt.n_eels
                game_opt.eel_shapes{i} = shapes{indices(i)};
            end
        end
        
        % Debug output
        disp('Assigned eel shapes:');
        for i = 1:game_opt.n_eels
            fprintf('Eel %d: %s\n', i, game_opt.eel_shapes{i});
        end
    end
    
    % Ensure shapes exist for all trials
    if ~isfield(game_opt, 'eel_shapes')
        % Fallback if trial didn't start at 1
        game_opt.eel_shapes = cell(1, game_opt.n_eels);
        game_opt.eel_shapes{1} = 'triangle';
        if game_opt.n_eels >= 2
            game_opt.eel_shapes{2} = 'hexagon';
        end
        
        % Fill any additional eels with other shapes
        shapes = {'star', 'diamond', 'pentagon'};
        for i = 3:game_opt.n_eels
            idx = mod(i-3, length(shapes)) + 1;
            game_opt.eel_shapes{i} = shapes{idx};
        end
        
        disp('Warning: Created default shapes since trial did not start from 1');
    end
    
    % Get wall center and circle radius
    wall_center = [visual_opt.wall_rect(1) + visual_opt.wall_rect(3)/2, ...
                   visual_opt.wall_rect(2) + visual_opt.wall_rect(4)/2];
    circle_radius = game_opt.circle_radius;  % in pixels
    
    % Create RGB string keys for the colors we'll be using
    eel_color_keys = cell(1, game_opt.n_eels);
    for i = 1:game_opt.n_eels
        eel_color_keys{i} = sprintf('%d,%d,%d', game_opt.eel_colors(i,1), game_opt.eel_colors(i,2), game_opt.eel_colors(i,3));
    end
    
    % Create a reliability map if it doesn't exist or ensure it has proper keys
    if ~isfield(game_opt, 'reliability_map') || ~isa(game_opt.reliability_map, 'containers.Map') || isempty(game_opt.reliability_map.keys)
        % Initialize reliability values
        reliability_values = zeros(1, game_opt.n_eels);
        
        % Check different sources for reliability values
        if isfield(game_opt, 'start_reliability') && isa(game_opt.start_reliability, 'containers.Map')
            % Convert old style to new style if needed
            if game_opt.start_reliability.isKey('blue') && game_opt.start_reliability.isKey('purple')
                reliability_values(1) = game_opt.start_reliability('blue');
                reliability_values(2) = game_opt.start_reliability('purple');
            elseif game_opt.start_reliability.isKey('color1') && game_opt.start_reliability.isKey('color2')
                reliability_values(1) = game_opt.start_reliability('color1');
                reliability_values(2) = game_opt.start_reliability('color2');
            else
                % Try to get values from keys as they are
                keys = game_opt.start_reliability.keys;
                for i = 1:min(game_opt.n_eels, length(keys))
                    reliability_values(i) = game_opt.start_reliability(keys{i});
                end
            end
        elseif isfield(game_opt, 'true_reliability') 
            % Handle true_reliability struct if it exists
            field_names = fieldnames(game_opt.true_reliability);
            for i = 1:min(game_opt.n_eels, length(field_names))
                reliability_values(i) = game_opt.true_reliability.(field_names{i});
            end
        else
            % Default values as fallback
            default_reliabilities = [0.30, 0.15];
            for i = 1:game_opt.n_eels
                if i <= length(default_reliabilities)
                    reliability_values(i) = default_reliabilities(i);
                else
                    reliability_values(i) = default_reliabilities(1);
                end
            end
            fprintf('Using default reliability values: %s\n', mat2str(reliability_values));
        end
        
        % Create a new reliability map using our RGB color keys
        game_opt.reliability_map = containers.Map(eel_color_keys, reliability_values);
    else
        % Ensure all necessary keys exist in the reliability map
        % If not, add them with default values
        for i = 1:game_opt.n_eels
            if ~game_opt.reliability_map.isKey(eel_color_keys{i})
                if i == 1
                    default_value = 0.30;  % Default for first color
                else
                    default_value = 0.15;  % Default for second color
                end
                fprintf('Adding missing color key %s with default reliability %.2f\n', eel_color_keys{i}, default_value);
                game_opt.reliability_map(eel_color_keys{i}) = default_value;
            end
        end
    end
    
    % Debug output for first few trials
    if curr_trial_data.trial_idx <= 5
        fprintf('Color keys in reliability map: ');
        disp(game_opt.reliability_map.keys);
    end
    
    % Ensure competency parameters are properly defined
    if ~isfield(game_opt, 'competencies') || length(game_opt.competencies) < 2
        error('Need at least two competency values in game_opt.competencies.');
    end
    
    % Determine if reliability and competency are swapped for this trial
    [rel_swapped, comp_swapped, ~, game_opt] = get_eel_switch_state(curr_trial_data.trial_idx, game_opt);
    
    % Print debug info for first few trials
    if curr_trial_data.trial_idx <= 10
        fprintf('Trial %d: Reliability swapped = %d, Competency swapped = %d\n', ...
                curr_trial_data.trial_idx, rel_swapped, comp_swapped);
    end
    
    % Use consistent competency values instead of randomizing them each trial
    high_comp = game_opt.competencies(2); % typically 0.9
    low_comp = game_opt.competencies(1);  % typically 0.4
    
    % Generate competency changes (for pursuit phase)
    [comp_changes, dist_info] = generate_competency_changes([low_comp, high_comp], game_opt, curr_trial_data);

    
    % Randomly assign initial sides (1 = Left, 2 = Right)
    %sides = randperm(2);



    pattern = [1 1 2 2];                                 % eel1용 패턴
    side1   = pattern( mod(curr_trial_data.trial_idx-1, numel(pattern) ) + 1 );
    side2   = 3 - side1;                                 % 1 ↔ 2 반전

% 두 마리일 때는 간단히
    sides = [side1 side2];
    % Use fixed colors for eels from game_opt.eel_colors
    eel_colors = game_opt.eel_colors;
    
    % Define vertical position range
    h_range = [floor(visual_opt.wHgt/2 - visual_opt.eel_rnd_range), ...
               ceil(visual_opt.wHgt/2 + visual_opt.eel_rnd_range)];
    
    % Preallocate eel structure array
    eels(game_opt.n_eels) = struct();
    
    % Process each eel
    for iE = 1:game_opt.n_eels
        % Assign sides (initial and potentially swapped final)
        eels(iE).initial_side = sides(iE);
        
        
        % Assign color (uses index iE to match with eel_colors)
        eels(iE).eel_col = eel_colors(iE, :);
        
        % Assign shape from the stored shapes in game_opt
        eels(iE).shape = game_opt.eel_shapes{iE};
        
        % Determine horizontal position range based on final side
        w_quarter = visual_opt.wWth / 4;
        w_range = [floor(w_quarter - visual_opt.eel_rnd_range), ...
                   ceil(w_quarter + visual_opt.eel_rnd_range)];
        if eels(iE).initial_side == 2
            w_range = w_range + visual_opt.wWth / 2;
        end
        
        % Assign position and generate fish locations
        eels(iE).eel_pos = [randi(w_range), randi(h_range)];
        eels(iE).eel_pos_choice = [1000, 324];
        eels(iE).fish_pos = generate_fish_locs(eels(iE).eel_pos, game_opt, visual_opt);
        
        % Assign basic eel attributes
        eels(iE).potent = game_opt.electrical_field;
        idx = (sides(iE) == 2) + 1;
        eels(iE).comp_change = comp_changes(idx);
        eels(iE).dist_params = dist_info(idx);
        
        % Get the first and second color keys
        color1_key = eel_color_keys{1};
        color2_key = eel_color_keys{2};
        
        % Debug output for the first few trials to help diagnose issues
        if curr_trial_data.trial_idx <= 5 && iE == 1
            fprintf('Trial %d - Using color keys: %s and %s\n', curr_trial_data.trial_idx, color1_key, color2_key);
            fprintf('Keys in reliability map: ');
            disp(game_opt.reliability_map.keys);
            % Also debug the shape assignments
            fprintf('Shapes assigned: %s for eel %d with color %s\n', eels(iE).shape, iE, color1_key);
        end
        
        % Determine competency based on eel index and switch state
        % First color (index 1) typically gets high competency, second color gets low
        if iE == 1
            % First color (e.g. blue)
            if comp_swapped
                eels(iE).competency = low_comp;  % Swapped: first color gets low competency
            else
                eels(iE).competency = high_comp; % Original: first color gets high competency
            end
        else
            % Second color (e.g. purple)
            if comp_swapped
                eels(iE).competency = high_comp; % Swapped: second color gets high competency
            else
                eels(iE).competency = low_comp;  % Original: second color gets low competency
            end
        end
        
        % Apply noise to competency if specified
        if game_opt.competency_noise_level > 0
            noise = randn() * game_opt.competency_noise_level;
            eels(iE).competency = eels(iE).competency + noise;
            % Clamp to valid range [0,1]
            eels(iE).competency = min(max(eels(iE).competency, 0), 1);
        end
        
        % Determine reliability based on eel index and switch state
        % Use a safer approach with try/catch to prevent key access errors
        try
            if iE == 1
                % First color (e.g. blue)
                if rel_swapped
                    eels(iE).reliability = game_opt.reliability_map(color2_key);  % Swapped
                else
                    eels(iE).reliability = game_opt.reliability_map(color1_key);  % Original
                end
            else
                % Second color (e.g. purple)
                if rel_swapped
                    eels(iE).reliability = game_opt.reliability_map(color1_key);  % Swapped
                else
                    eels(iE).reliability = game_opt.reliability_map(color2_key);  % Original
                end
            end
        catch e
            % If we can't find the key, use default fallback values
            fprintf('Warning: Reliability key not found. Using fallback value.\n');
            fprintf('Error was: %s\n', e.message);
            if iE == 1
                eels(iE).reliability = 0.30;  % Default for first eel
            else
                eels(iE).reliability = 0.15;  % Default for second eel
            end
        end
        
        % Calculate final competency for pursuit phase
        eels(iE).final_competency = eels(iE).competency + eels(iE).comp_change;
        
        % Ensure competency stays within valid range [0, 1]
        eels(iE).final_competency = min(max(eels(iE).final_competency, 0), 1);

        % === Generate eel choice position using the circular system ===
        % For the right eel (final_side == 2): select an angle between -pi/6 and pi/6,
        % For the left eel (final_side == 1): select an angle between 5pi/6 and 7pi/6.
        % These angular ranges ensure that the eels appear only in the middle
        % (i.e., they do not appear in the upper or lower extremes of the circle).
        valid_candidate = false;
        while ~valid_candidate
            if eels(iE).initial_side == 1
                angle = (5*pi/6) + rand() * (pi/6);
            else % initial_side == 2
                angle = rand() * (pi/6);
            end
            
            candidate = wall_center + circle_radius * [cos(angle), sin(angle)];
            candidate = round(candidate);
            
            % Check candidate is within screen boundaries.
            if candidate(1) < 1 || candidate(1) > visual_opt.wWth || ...
               candidate(2) < 1 || candidate(2) > visual_opt.wHgt
                continue;
            end
            
            valid_candidate = true;
        end
        eels(iE).eel_pos_choice = candidate;

    end
    
    % Store results in trial data
    curr_trial_data.eels = eels;
    curr_trial_data.avtr_start_pos = [visual_opt.wWth/2, visual_opt.coordinate_window];
    
    % Validation check
    if isempty(eels)
        error('Eel initialization failed: No eels were assigned.');
    end
end