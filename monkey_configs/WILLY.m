function config = WILLY()
    % Default configuration for monkeys
    % This file serves as a template for creating new monkey configurations

    % General settings
    config.test = false; % Set to true for testing mode
    
    %% DEVICE CONFIGS
    % Device settings
    config.device.KEYBOARD = true;
    config.device.JOYSTICK = true;
    config.device.EYELINK = true;
    config.device.ARDUINO = true; 

    config.device.arduino_port = 'COM8'; % Default Arduino port
    config.device.minInput = 0.15;  % joystick drift threshold
    config.device.min_t_scale = 1/1000; % 1ms scale
    config.device_activate_arduino = 1;
    
    %% VISUAL CONFIGS 
    % Visual settings
    config.visual.screen_number = 2; % Primary screen
    config.visual.screen_color = [232, 232, 232]; % Gray background
    config.visual.choice_color_avtr = [204, 153, 0]; % Avatar color during choice
    config.visual.pursuit_color_avtr = [239, 191, 4]; % Avatar color during pursuit
    config.visual.color_avtr_gray = [137, 137, 137]; % Gray for inactive avatar
    config.visual.color_fish = [255, 165, 0]; % Orange for fish
    config.visual.catch_animation_frames = 30; % Frames for caught fish animation
    config.visual.corridor_color = [0, 0, 0]; % Black corridor
    config.visual.corridor_thickness = 50; % Thickness of corridor walls
    config.visual.gap_size = 700; % Gap size in corridor

    % Fish counter 
    config.visual.SQUARE_SIZE = 40; % Size of each square in pixels
    config.visual.GAP = 4; % Gap between squares
    config.visual.MARGIN = 100; % Margin from edges

    % Time bar 
    config.visual.time_bar_height = 20; % Height of the timer bar
    config.visual.initial_time_color = [0, 255, 0]; % Green for initial time
    config.visual.bonus_time_color = [0, 191, 255]; % Blue for bonus time
    config.visual.time_background_color = [100, 100, 100]; % Gray for empty bar
    config.visual.show_timer_from_start = true; % Show timer from the start
    
    
    % Game settings
    %% GAME OPTS
    % Timing Parameters
    config.game.ITI_time = 0.5;            % Inter-Trial Interval time (seconds)
    config.game.PV_time = 6;               % Time for presenting the visual (seconds)
    config.game.pursuit_time = 15;          % Duration of pursuit phase (seconds)
    config.game.choice_time = 10;          % Time allowed for making a choice (seconds)
    config.game.score_time = 1.5;          % Duration for displaying the score (seconds)
    config.game.buffer_t = 1 / 500;        % Buffer time for frame drop (seconds)
    
    % Reward Parameters
    config.game.reward_duration = 1;       % Duration of reward (seconds)
    config.game.short_reward_duration = 0.5; % Duration of short reward (seconds)
    config.game.reward_value = 0.7; % For humans
    
    % Fish Configuration
    config.game.n_fishes = 6;              % Total number of fish
    config.game.n_fish_to_catch = 3;       % Maximum number of fish that can be caught
    config.game.fish_sz = 25;              % Size of fish (pixels)
    config.game.fish_init_min_r = config.game.fish_sz * 2; % Minimum initialization distance
    config.game.fish_init_max_r = config.game.fish_sz * 8; % Maximum initialization distance
    config.game.fast_spd = 30;             % Speed of the fish when moving quickly (pixels/second)
    
    % Avatar avoidance parameters
    config.game.avatar_sigma = 30;         % Controls the sharpness of exponential repulsion
    config.game.avatar_repulsion_strength = 10; % Scaling factor for avatar repulsion
    
    % Weights for movement vectors
    config.game.w_avatar = 0.5;            % Weight for avatar avoidance (exponential)
    config.game.w_momentum = 0.6;          % Weight for maintaining previous direction
    config.game.w_avoidFish = 0.3;         % Weight for avoiding other fish
    config.game.w_rand = 0.1;              % Weight for random wandering
    
    % Avatar Configuration
    config.game.avatar_sz = 25;            % Avatar size (pixels)
    config.game.avatar_offset = 100;       % Offset for avatar at the pursuit phase (pixels)
    config.game.avatar_speed = 10;         % Avatar speed (pixels/second)
    
    %% EUEYELINK 
    % EyeLink Configuration
    config.eye.useEL = true;               % Use EyeLink if available
    config.eye.calTargetSize = 30;         % Size of calibration targets
    config.eye.calTargetColor = [0, 0, 0]; % Black calibration targets
    config.eye.calibrationType = 'HV9';    % 9-point calibration
    config.eye.sampleRate = 1000;          % Sample rate in Hz
    config.eye.window_size = 200;          % Fixation window size in pixels
end
