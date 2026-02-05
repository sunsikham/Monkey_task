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
    
    if ~isfield(game_opt, 'n_trials')
        game_opt.n_trials = 350;  % Default number of trials
    end
end

function game_opt = initialize_default_game_opt()
    % Initialize default game options
    
    %% Timing Parameters
    game_opt.ITI_time = 0.5;            % Inter-Trial Interval time (seconds)
    game_opt.PV_time = 6;               % Time for presenting the visual (seconds)
    game_opt.pursuit_time = 7;          % Duration of pursuit phase (seconds)
    game_opt.choice_time = 20;          % Time allowed for making a choice (seconds)
    game_opt.score_time = 1.5;          % Duration for displaying the score (seconds)
    
    % TIME TRACKING Buffer 
    game_opt.buffer_t = 1 / 500;        % Buffer time for frame drop (seconds)
    
    %% Reward Parameters
    game_opt.reward_duration = 5;       % Duration of reward (seconds)
    game_opt.short_reward_duration = 0.5; % Duration of short reward (seconds)
    game_opt.reward_value = 1;          % Reward value for humans
    
    %% Fish Configuration
    game_opt.n_fishes = 6;              % Total number of fish
    game_opt.n_fish_to_catch = 3;       % Maximum number of fish that can be caught
    game_opt.fish_sz = 25;              % Size of fish (pixels)
    game_opt.fish_init_min_r = game_opt.fish_sz * 2; % Min distance from spawn center
    game_opt.fish_init_max_r = game_opt.fish_sz * 8; % Max distance from spawn center
    game_opt.passive_view_radius = 200; % Radius where fish can move in PV
    game_opt.fast_spd = 9;             % Speed of fish when moving quickly
    
    % Avatar avoidance parameters
    game_opt.avatar_sigma = 30;         % Controls sharpness of exponential repulsion
    game_opt.avatar_repulsion_strength = 10; % Scaling factor for avatar repulsion
    
    % Weights for movement vectors
    game_opt.w_avatar = 0.5;            % Weight for avatar avoidance
    game_opt.w_momentum = 0.6;          % Weight for maintaining previous direction
    game_opt.w_avoidFish = 0.3;         % Weight for avoiding other fish
    game_opt.w_rand = 0.1;              % Weight for random wandering
    
    % Avatar Configuration
    game_opt.avatar_sz = 30;            % Avatar size (pixels)
    game_opt.avatar_offset = 100;       % Offset for avatar at pursuit phase
    game_opt.avatar_speed = 11;         % Avatar speed (pixels/second)
end
