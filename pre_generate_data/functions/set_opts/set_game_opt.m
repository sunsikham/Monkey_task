function game_opt = set_game_opt(monkey_config)
    % SET_GAME_OPT - Configures game options for the experiment.
    %
    % Input:
    %   monkey_config - Struct containing monkey-specific configurations
    %
    % Output:
    %   game_opt - Struct containing all game configuration parameters.
    
    % Initialize default game options
    game_opt = initialize_default_game_opt();
    
    % Override with monkey-specific game options if provided
    if isfield(monkey_config, 'game')
        fields = fieldnames(monkey_config.game);
        for i = 1:length(fields)
            field = fields{i};
            game_opt.(field) = monkey_config.game.(field);
        end
    end
    
    % Ensure switching parameters are defined
    % This is essential for dynamic trial generation to match premade trials
    if ~isfield(game_opt, 'n_trials')
        game_opt.n_trials = 350;  % Default number of trials
    end
    
    % In the function that sets up game_opt:
    game_opt.initial_rel_swapped = (rand() > 0.5);  % Randomly choose initial reliability state
    game_opt.initial_comp_swapped = (rand() > 0.5); % Randomly choose initial competency state

    % Set offsets to start from first trial
    game_opt.reliability_offset = 1;
    game_opt.competency_switch_offset = 1;
end

function game_opt = initialize_default_game_opt()
    % Initialize default game options
    
    game_opt.premade_eels = true;      % If true, load the eels and use those 
    game_opt.eels_src = './pre_generate_data/data/copy_of_premade_trials';
    game_opt.reliability_interval = 0.15;
   
    %% Timing Parameters
    game_opt.ITI_time = 0.5;            % Inter-Trial Interval time (seconds)
    game_opt.PV_time = 2;               % Time for presenting the visual (seconds)
    game_opt.pursuit_time = 7;          % Duration of pursuit phase (seconds)
    game_opt.choice_time = 10;          % Time allowed for making a choice (seconds)
    game_opt.score_time = 1.5;          % Duration for displaying the score (seconds)
    
    % TIME TRACKING Buffer 
    game_opt.buffer_t = 1 / 500;        % Buffer time for frame drop (seconds)
    
    %% Reward Parameters
    game_opt.reward_duration = 2;       % Duration of reward (seconds)
    game_opt.short_reward_duration = 1; % Duration of short reward (seconds)
    game_opt.reward_value = 1;          % Reward value for humans
    
    %% Eel Configuration

    % Electrical Field Parameters
    game_opt.use_only_initial_side = false; % If false, use potentially swapped final side
    game_opt.swap_eels_prob = 0.3;      % Probability of swapping eels' sides during trial 
    game_opt.electrical_field = 250;    % Electrical field radius around the eel
    
    % Competency values affect how much the eel slows down the fish
    % Higher competency (0.9) = fish moves faster near eel (less slowing)
    % Lower competency (0.4) = fish moves slower near eel (more slowing)
    game_opt.competencies = [0.4, 0.9]; 
    
    game_opt.n_eels = 2;                % Number of eels in the game
    game_opt.eel_sz = 30;               % Size of eels (pixels)
    game_opt.eel_spd = 1;               % Speed of the eel (pixels/second)
    game_opt.eel_spd_passive_view = 1.2;
      
    % Default eel colors - can be changed but should always have n_eels rows
    game_opt.eel_colors = [
            0, 0, 255;         % Color 1 (Default: Blue)
            157, 0, 255        % Color 2 (Default: Purple)
        ];
    
    % Base reliability values for each eel color by index
    % Lower reliability = more variability in effect on fish speed
    % Store using color indices instead of color names
    color_keys = cell(1, game_opt.n_eels);
    reliability_values = zeros(1, game_opt.n_eels);
    
    % Default reliability values
    default_reliabilities = [0.30, 0.15];  % Default values for first two colors
    
    % Create keys for each color from RGB values
    for i = 1:game_opt.n_eels
        color_keys{i} = sprintf('%d,%d,%d', game_opt.eel_colors(i,1), game_opt.eel_colors(i,2), game_opt.eel_colors(i,3));
        
        % Use default values if available, otherwise use first value
        if i <= length(default_reliabilities)
            reliability_values(i) = default_reliabilities(i);
        else
            reliability_values(i) = default_reliabilities(1);
        end
    end
    
    % Create reliability map using RGB values as keys
    game_opt.reliability_map = containers.Map(color_keys, reliability_values);
    
    % For backward compatibility (can be removed in future versions)
    game_opt.start_reliability = containers.Map({'color1', 'color2'}, [0.30, 0.15]);
    
    %% Switching Parameters
    % These control when reliability and competency switch between eels
    game_opt.n_trials = 350;            % Total number of trials
    
    game_opt.min_rel_switch = 23;       % Minimum trials between reliability switches
    game_opt.max_rel_switch = 27;       % Maximum trials between reliability switches
    
    game_opt.min_comp_switch = 15;      % Minimum trials between competency switches
    game_opt.max_comp_switch = 20;      % Maximum trials between competency switches
    
    game_opt.circle_radius = 570 ; % radius where the eels will appear during choice 
    
    game_opt.competency_noise_level = 0.0;
    %% Passive View Parameters
    game_opt.margin = 300;              % Offset from screen edges and boundaries
    game_opt.jistter_amount = 50;       % Random jitter to avoid perfect alignment
    game_opt.passive_view_electrical_field = 250;
    
    %% Fish Configuration
    game_opt.n_fishes = 6;              % Total number of fish
    game_opt.n_fish_to_catch = 3;       % Maximum number of fish that can be caught
    game_opt.fish_sz = 25;              % Size of fish (pixels)
    game_opt.fish_init_min_r = game_opt.electrical_field - game_opt.eel_sz; % Min distance
    game_opt.fish_init_max_r = game_opt.electrical_field + game_opt.eel_sz; % Max distance
    game_opt.passive_view_radius = 200; % Radius where fish can move in PV
    game_opt.fast_spd = 11;             % Speed of fish when moving quickly
    game_opt.R = 600;                   % Radius around eel where fish can move
    
    % Fish movement parameters
    game_opt.R = max(game_opt.electrical_field) + 50; % Larger radius around eel
    game_opt.grav_strength = 0.2;       % Base strength for gravitational pull
    
    % Avatar avoidance parameters
    game_opt.avatar_sigma = 30;         % Controls sharpness of exponential repulsion
    game_opt.avatar_repulsion_strength = 10; % Scaling factor for avatar repulsion
    
    % Weights for movement vectors
    game_opt.w_grav = 0.3;              % Weight for gravitational pull towards R
    game_opt.w_avatar = 0.5;            % Weight for avatar avoidance
    game_opt.w_momentum = 0.6;          % Weight for maintaining previous direction
    game_opt.w_avoidFish = 0.3;         % Weight for avoiding other fish
    game_opt.w_rand = 0.1;              % Weight for random wandering
    
    % Avatar Configuration
    game_opt.avatar_sz = 30;            % Avatar size (pixels)
    game_opt.avatar_offset = 100;       % Offset for avatar at pursuit phase
    game_opt.avatar_speed = 11;         % Avatar speed (pixels/second)
end