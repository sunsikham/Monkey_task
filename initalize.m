function [visual_opt, device_opt, game_opt, eye_opt, save_directory] = initalize(varargin)

    %% 0) clear all;
    close all;
    clc;
    clearvars -except varargin;

    skip_eyelink_setup = false;
    if nargin >= 1
        skip_eyelink_setup = logical(varargin{1});
    end
        
    %% 1) Add all subdirectory;
    % Get the directory where this m-file is located
    currentFolder = fileparts(mfilename('fullpath'));
    
    % Add the current folder to the path
    addpath(currentFolder);
    
    % Recursively add all subdirectories
    %addpath(genpath(currentFolder));
    
    % Display a message confirming that the paths have been added
    disp(['Added ', currentFolder, ' and its subdirectories to the path.']);

    % Create monkey_configs directory if it doesn't exist
    configDir = fullfile(currentFolder, 'monkey_configs');
    if ~exist(configDir, 'dir')
        mkdir(configDir);
        disp(['Created monkey configuration directory: ', configDir]);
        % Create a default monkey config file to serve as a template
        createDefaultMonkeyConfig(configDir);
    end

    % Ensure the intended config directory has path precedence
    addpath(configDir, '-begin');
    % Remove any shadowing monkey_configs or pre_generate_data paths (case/sep agnostic)
    pathParts = strsplit(path, pathsep);
    altSuffix = lower(fullfile('functions', 'monkey_configs'));
    preSuffix = lower('pre_generate_data');
    for i = 1:numel(pathParts)
        p = pathParts{i};
        lp = lower(p);
        if contains(lp, altSuffix) || contains(lp, preSuffix)
            rmpath(p);
        end
    end
    
    
    if ismac
        disp('Running on macOS');
        username = getenv('USER');  % Works on macOS and Linux
        
        % Get list of available monkey configurations
        monkeyConfigs = dir(fullfile(configDir, '*.m'));
        monkeyNames = cellfun(@(x) x(1:end-2), {monkeyConfigs.name}, 'UniformOutput', false);
        
        if isempty(monkeyNames)
            disp('No monkey configurations found. Creating default config.');
            createDefaultMonkeyConfig(configDir);
            monkeyConfigs = dir(fullfile(configDir, '*.m'));
            monkeyNames = cellfun(@(x) x(1:end-2), {monkeyConfigs.name}, 'UniformOutput', false);
        end
        
        % If only one monkey config exists, use it automatically
        if length(monkeyNames) == 1
            monkey = monkeyNames{1};
        else
            % List available monkeys and let user choose
            disp('Available monkey configurations:');
            for i = 1:length(monkeyNames)
                disp([num2str(i), '. ', monkeyNames{i}]);
            end
            
            choice = input('Select a monkey configuration (number) or enter a new name: ');
            if isnumeric(choice) && choice <= length(monkeyNames)
                monkey = monkeyNames{choice};
            else
                monkey = input('Enter new monkey name: ', 's');
                % Create a new config file based on default
                createMonkeyConfig(configDir, monkey);
            end
        end
        
    elseif ispc
        disp('Running on Windows');
        username = getenv('USERNAME');
        
        % Get list of available monkey configurations
        monkeyConfigs = dir(fullfile(configDir, '*.m'));
        monkeyNames = cellfun(@(x) x(1:end-2), {monkeyConfigs.name}, 'UniformOutput', false);
        
        if isempty(monkeyNames)
            disp('No monkey configurations found. Creating default config.');
            createDefaultMonkeyConfig(configDir);
            monkeyConfigs = dir(fullfile(configDir, '*.m'));
            monkeyNames = cellfun(@(x) x(1:end-2), {monkeyConfigs.name}, 'UniformOutput', false);
        end
        
        % Display available monkeys
        disp('Available monkey configurations:');
        for i = 1:length(monkeyNames)
            disp([num2str(i), '. ', monkeyNames{i}]);
        end
        
        choice = input('Select a monkey configuration (number) or enter a new name: ');
        if isnumeric(choice) && choice <= length(monkeyNames)
            monkey = monkeyNames{choice};
        else
            monkey = input('Enter new monkey name: ', 's');
            % Create a new config file based on default
            createMonkeyConfig(configDir, monkey);
        end
    else
        disp('Running on another OS');
        username = "OTHER";
        monkey = input('Enter monkey name: ', 's');
    end

    % Load monkey-specific configuration
    configFile = fullfile(configDir, [monkey, '.m']);
    if exist(configFile, 'file')
        disp(['Loading configuration for monkey: ', monkey]);
        % Use run to execute the config file and get the output
        config_func = str2func(monkey);
        monkey_config = config_func();
        test = monkey_config.test; % Override test mode based on monkey config
    else
        disp(['No configuration found for monkey: ', monkey, '. Creating default.']);
        createMonkeyConfig(configDir, monkey);
        config_func = str2func(monkey);
        monkey_config = config_func();
    end

    % Define the save path and filenames
    save_directory = define_save(currentFolder, monkey);
    
    %% 2) Set visual_opt, game_opt, device_opt
    device_opt = set_device_opt(monkey, monkey_config.test, monkey_config);
    visual_opt = set_visual_opt(monkey, monkey_config);
    game_opt = set_game_opt(monkey_config);

    %% 3) Eyelink related.
    
    eye_opt = set_eyelink(visual_opt, monkey_config, device_opt, skip_eyelink_setup);

    %temporary
    if eye_opt.eyelink_on
        try
            if Eyelink('IsConnected') > 0
                disp('Testing gaze samples for 2 seconds...');
                t0 = GetSecs;
                while GetSecs - t0 < 2
                    if Eyelink('NewFloatSampleAvailable') > 0
                        s = Eyelink('NewestFloatSample');
                        fprintf('GX=%.1f  GY=%.1f\n', s.gx(eye_opt.eye_side), s.gy(eye_opt.eye_side));
                    end
                end
            else
                disp('Eyelink is OFF (not connected).');
            end
        catch ME
            disp(['Eyelink sample test skipped: ', ME.message]);
        end
    else
        disp('Eyelink is OFF (config or connection).');
    end

    
    metadata = struct();
    metadata.game_opt = game_opt;
    metadata.device_opt = device_opt;
    metadata.visual_opt = visual_opt; 
    metadata.monkey_config = monkey_config;
    
    % Save the metadata 
    full_file_path = fullfile(save_directory, ['metadata', '.mat']);
    save(full_file_path, 'metadata');
end


function createMonkeyConfig(configDir, monkey)
    % Create a new monkey configuration file based on the default
    newConfig = [
        'function config = ' upper(monkey) '()\n', ...
        '    % Configuration for monkey: ' upper(monkey) '\n', ...
        '    % This file was automatically generated\n\n', ...
        '    % Load the default configuration\n', ...
        '    defaultConfig = DEFAULT();\n', ...
        '    config = defaultConfig;\n\n', ...
        '    % Override specific settings for this monkey\n', ...
        '    % Examples:\n', ...
        '    % config.test = true;\n', ...
        '    % config.device.arduino_port = ''COM4'';\n', ...
        '    % config.visual.screen_number = 1;\n', ...
        'end\n'
    ];
    
    % Create the monkey-specific config file
    fid = fopen(fullfile(configDir, [upper(monkey), '.m']), 'w');
    fprintf(fid, newConfig);
    fclose(fid);
end
