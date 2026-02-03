
function device_opt = configure_joystick(device_opt, test)
    % Set up joystick
    try
        clear JOYMEX
        JoyMEX('init', 0);
        device_opt.joystick = true;
    catch joystickError
        if test
            warning(['JoyMEX not connected or initialization failed. ...' ...
                'Skipping joystick setup.']);
            device_opt.joystick = false;
        else
            error(['Fatal Error: JoyMEX not connected or initialization failed. ...' ...
                'Cannot proceed with experiment.']);
        end
    end
end
