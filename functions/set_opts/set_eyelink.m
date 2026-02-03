function eye_opt = set_eyelink(visual_opt, monkey_config, device_opt, skip_tracker_setup)
%% This function initializes Eyelink if it is connected, enabled in config, and the MEX file is valid.
% Input arguments:
% visual_opt: struct that contains visual information.
% monkey_config: struct containing monkey-specific configuration

eye_opt.eye_side = 1; % 1: left; 2: right.
eye_opt.eyelink_on = false; % Default to off

if nargin < 3
    device_opt = struct();
end
if nargin < 4
    skip_tracker_setup = false;
end

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
    Eyelink('command', 'calibration_type = HV5');

    % Generate default targets for calibration
    Eyelink('command', 'generate_default_targets = YES');

    Eyelink('command', 'calibration_target_size = 1.2');   % ≈ 4 %
    Eyelink('command', 'calibration_target_width = 0.6');

    % Set background and calibration dot color
    el.backgroundcolour = [255 255 255];        % grey background
    el.calibrationtargetcolour = [255 0 0];     % red dot
    el.calibrationtargetsize = 12;             % outer dot size (pixels or %)
    el.calibrationtargetwidth = 0;             % inner dot size (pixels)

    % Apply changes to EyeLink defaults
    EyelinkUpdateDefaults(el);

    % Set EyeLink calibration type and other parameters
    Eyelink('command', 'calibration_type = HV5');
    Eyelink('command', 'generate_default_targets = YES');
    Eyelink('command', 'calibration_target_size = 12');  % outer
    Eyelink('command', 'calibration_target_width = 1');  % inner



    % Perform tracker setup and calibration unless manual calibration was already done
    if skip_tracker_setup
        disp('Skipping EyeLink tracker setup (manual calibration already done).');
    else
        EyelinkDoTrackerSetup(el);
    end


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