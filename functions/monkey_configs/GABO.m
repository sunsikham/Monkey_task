function config = GABO()
    % Default configuration for monkeys
    % This file serves as a template for creating new monkey configurations

    % General settings
    config.test = false; % Set to true for testing mode

    % Device settings
    config.device.KEYBOARD = true;
    config.device.JOYSTICK = true;
    config.device.EYELINK = false;
    config.device.arduino_port = 'COM4'; % Default Arduino port
    config.device.minInput = 0.9;  % joystick drift threshold
    config.device.min_t_scale = 1/1000; % 1ms scale

    % Visual settings
    config.visual.screen_number = 2; % Primary screen
    config.visual.screen_color = [232, 232, 232]; % White background
    config.visual.choice_color_avtr = [204, 153, 0]; % Avatar color during choice
    config.visual.pursuit_color_avtr = [239, 191, 4]; % Avatar color during pursuit
    config.visual.color_avtr_gray = [137, 137, 137]; % Gray for inactive avatar
    config.visual.color_fish = [255, 165, 0]; % Orange for fish
    config.visual.catch_animation_frames = 30; % Frames for caught fish animation
    config.visual.corridor_color = [0, 0, 0]; % Black corridor
    config.visual.corridor_thickness = 50; % Thickness of corridor walls
    config.visual.gap_size = 500; % Gap size in corridor
    config.visual.eel_rnd_range = 50; % Maximum random movement for eels
    config.visual.SQUARE_SIZE = 40; % Size of each square in pixels
    config.visual.GAP = 4; % Gap between squares
    config.visual.MARGIN = 100; % Margin from edges
    config.visual.time_bar_height = 20; % Height of the timer bar
    config.visual.initial_time_color = [0, 255, 0]; % Green for initial time
    config.visual.bonus_time_color = [0, 191, 255]; % Blue for bonus time
    config.visual.time_background_color = [100, 100, 100]; % Gray for empty bar
    config.visual.show_timer_from_start = true; % Show timer from the start
    config.visual.visualize_pot = true; % Visualize eel potentials
    config.visual.alpha = 0.7; % Transparency (0 to 1)

    % Game settings
    config.game.premade_eels = false; % If true, load pre-made eels
    config.game.eels_src = './pre_generate_data/data/copy_of_premade_trials';
    config.game.reliability_interval = 0.15;
    
    % Timing Parameters
    config.game.ITI_time = 0.5;            % Inter-Trial Interval time (seconds)
    config.game.PV_time = 2;               % Time for presenting the visual (seconds)
    config.game.pursuit_time = 7;          % Duration of pursuit phase (seconds)
    config.game.choice_time = 10;          % Time allowed for making a choice (seconds)
    config.game.score_time = 1.5;          % Duration for displaying the score (seconds)
    config.game.buffer_t = 1 / 500;        % Buffer time for frame drop (seconds)
    
    % Reward Parameters
    config.game.reward_duration = 2;       % Duration of reward (seconds)
    config.game.short_reward_duration = 1; % Duration of short reward (seconds)
    config.game.reward_value = 1; % For humans
    
    % Eel Configuration
    config.game.use_only_initial_side = false; % If false, during choice and pursuit we use final (might be swapped)
    config.game.swap_eels_prob = 0.3;      % Probability of swapping eels side
    config.game.electrical_field = 250;    % Electrical field around the eel
    config.game.competencies = [0.4, 0.55, 0.7, 0.9]; % Competency values for eels
    
    config.game.n_eels = 2;                % Number of eels in the game
    config.game.eel_sz = 30;               % Size of eels (pixels)
    config.game.eel_spd = 1;               % Speed of the eel (pixels/second)
    config.game.eel_spd_passive_view = 1.2;
    
    config.game.eel_colors = [
        0, 0, 255;         % Blue
        157, 0, 255        % Purple
    ];
   
    
    % Define fixed change limits for change in eel competency
    config.game.min_increase = 0;          % The weaker eel can stay the same or increase
    config.game.max_increase = 0.2;        % Maximum possible increase for the weaker eel
    config.game.min_decrease = 0.2;        % Maximum possible decrease for the stronger eel
    config.game.max_decrease = 0;          % The stronger eel can stay the same or decrease
    
    % Passive View Eel Initialization Settings
    config.game.margin = 300;              % Offset from screen edges and corridor boundaries
    config.game.jistter_amount = 50;       % Maximum random jitter to avoid perfect alignment
    
    % Fish Configuration
    config.game.n_fishes = 6;              % Total number of fish
    config.game.n_fish_to_catch = 3;       % Maximum number of fish that can be caught
    config.game.fish_sz = 25;              % Size of fish (pixels)
    config.game.fish_init_min_r = min(config.game.electrical_field) - config.game.eel_sz; % Minimum initialization distance
    config.game.fish_init_max_r = max(config.game.electrical_field) + config.game.eel_sz; % Maximum initialization distance
    config.game.passive_view_radius = 200; % Radius where the fish can move in PV
    config.game.fast_spd = 11;             % Speed of the fish when moving quickly (pixels/second)
    config.game.R = 600;                   % Larger radius around eel (pixels) where fish can move in pursuit
    
    % Gravitational pull parameters
    config.game.R = max(config.game.electrical_field) + 50; % Larger radius around eel
    config.game.grav_strength = 0.2;       % Base strength for gravitational pull
    
    % Avatar avoidance parameters
    config.game.avatar_sigma = 30;         % Controls the sharpness of exponential repulsion
    config.game.avatar_repulsion_strength = 10; % Scaling factor for avatar repulsion
    
    % Weights for movement vectors
    config.game.w_grav = 0.3;              % Weight for gravitational pull towards R
    config.game.w_avatar = 0.5;            % Weight for avatar avoidance (exponential)
    config.game.w_momentum = 0.6;          % Weight for maintaining previous direction
    config.game.w_avoidFish = 0.3;         % Weight for avoiding other fish
    config.game.w_rand = 0.1;              % Weight for random wandering
    
    % Avatar Configuration
    config.game.avatar_sz = 30;            % Avatar size (pixels)
    config.game.avatar_offset = 100;       % Offset for avatar at the pursuit phase (pixels)
    config.game.avatar_speed = 11;         % Avatar speed (pixels/second)
    
    % EyeLink Configuration
    config.eye.useEL = false;               % Use EyeLink if available
    config.eye.calTargetSize = 30;         % Size of calibration targets
    config.eye.calTargetColor = [0, 0, 0]; % Black calibration targets
    config.eye.calibrationType = 'HV9';    % 9-point calibration
    config.eye.sampleRate = 1000;          % Sample rate in Hz
    config.eye.window_size = 200;          % Fixation window size in pixels
end