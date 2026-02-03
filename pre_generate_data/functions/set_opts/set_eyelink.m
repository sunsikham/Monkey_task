function eye_opt = set_eyelink(visual_opt, monkey_config)
%% This function initializes Eyelink if it is connected, enabled in config, and the MEX file is valid.
% Input arguments:
% visual_opt: struct that contains visual information.
% monkey_config: struct containing monkey-specific configuration

eye_opt.eye_side = 1; % 1: left; 2: right.
eye_opt.eyelink_on = false; % Default to off

% Check if EyeLink is enabled in the configuration
if ~isfield(monkey_config, 'device') || ~isfield(monkey_config.device, 'EYELINK') || ~monkey_config.device.EYELINK
    disp('EyeLink is disabled in configuration. Skipping initialization.');
    return;
end

try
    % Try to call an EyeLink function to check if the MEX file is valid
    Eyelink('IsConnected');

    % If the function does not throw an error, the MEX file is valid
    eye_opt.eyelink_on = true; % If connected, set eyelink_on to true

    % Initialize the Eyelink system
    el = EyelinkInitDefaults(visual_opt.winPtr);
    EyelinkInit(0); % Zero indicates no specific initialization options (just defaults)

    % Add preamble text for the experiment file
    Eyelink('command', 'add_file_preamble_text ''Recorded by Eyelink Trial game experiment''');

    % Set the screen coordinates for the tracker
    Eyelink('command', 'screen_pixel_coords = %ld %ld %ld %ld', 0, 0, visual_opt.wWth-1, visual_opt.wHgt-1);

    % Send display coordinates message
    Eyelink('message', 'DISPLAY_COORDS %ld %ld %ld %ld', 0, 0, visual_opt.wWth-1, visual_opt.wHgt-1);

    % Set calibration type
    Eyelink('command', 'calibration_type = HV9');

    % Generate default targets for calibration
    Eyelink('command', 'generate_default_targets = YES');

    % Perform tracker setup and calibration
    EyelinkDoTrackerSetup(el);

    % Start the EyeLink recording
    Eyelink('StartRecording');
    disp('Eyelink is connected and turned on!');
catch ME
    % Catch errors related to the MEX file or EyeLink connection
    if contains(ME.message, 'Invalid MEX-file')
        disp('Error: Invalid or missing EyeLink MEX file. Skipping initialization.');
    else
        disp(['Unexpected error: ', ME.message]);
    end
end
end