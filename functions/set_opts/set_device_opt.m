function device_opt = set_device_opt(monkey, test_or_config, maybe_config)
    % SET_DEVICE_OPT - Configure device options based on monkey configuration
    %
    % Usage:
    %   device_opt = set_device_opt(monkey, monkey_config)
    %   device_opt = set_device_opt(monkey, test, monkey_config)
    %
    % If only two arguments are provided, the second is assumed to be
    % monkey_config and 'test' defaults to false. If three are provided,
    % the second is the test flag and the third is monkey_config.

    if nargin == 2
        monkey_config = test_or_config;
        test = false;
    elseif nargin == 3
        test = test_or_config;
        monkey_config = maybe_config;
    else
        error('set_device_opt requires either 2 or 3 inputs.');
    end

    % Initialize device options based on test mode and monkey_config
    device_opt = initialize_device_options(test, monkey_config);
    %device_opt.arduino_port = 'COM4';
    % Configure keyboard if enabled
    if isfield(device_opt, 'KEYBOARD') && device_opt.KEYBOARD
        device_opt = configure_keyboard(device_opt);
    end

    % Configure joystick if enabled
    if isfield(device_opt, 'JOYSTICK') && device_opt.JOYSTICK
        device_opt = configure_joystick(device_opt, test);
    end
    
    % Configure Arduino if enabled
    if isfield(device_opt, 'ARDUINO') && device_opt.ARDUINO
        device_opt = configure_arduino(device_opt, monkey_config);
    end

    % Set extra fields from monkey_config.device, if present
    if isfield(monkey_config, 'device')
        % minInput and min_t_scale are required fields
        if isfield(monkey_config.device, 'minInput')
            device_opt.minInput = monkey_config.device.minInput;
        end
        if isfield(monkey_config.device, 'min_t_scale')
            device_opt.min_t_scale = monkey_config.device.min_t_scale;
        end

        % Copy over any other device subfields
        fields = fieldnames(monkey_config.device);
        for i = 1:length(fields)
            fld = fields{i};
            if ~ismember(fld, {'KEYBOARD','JOYSTICK','EYELINK','ARDUINO','arduino_port','device_activate_arduino','minInput','min_t_scale'})
                device_opt.(fld) = monkey_config.device.(fld);
            end
        end
    end
end

% ──────────────────────────────────────────────────────────────────────────────
function device_opt = initialize_device_options(test, monkey_config)
    % Initialize default device options based on test mode and monkey_config

    if test
        device_opt.KEYBOARD = true;
        device_opt.JOYSTICK = false;
        device_opt.EYELINK  = false;
        device_opt.ARDUINO  = false;
    else
        device_opt.KEYBOARD = true;
        device_opt.JOYSTICK = true;
        device_opt.EYELINK  = true;
        device_opt.ARDUINO  = isfield(monkey_config, 'device') && isfield(monkey_config.device, 'ARDUINO') ...
                              && monkey_config.device.ARDUINO;
    end

    % Override defaults with monkey_config.device if provided
    if isfield(monkey_config, 'device')
        if isfield(monkey_config.device, 'KEYBOARD')
            device_opt.KEYBOARD = monkey_config.device.KEYBOARD;
        end
        if isfield(monkey_config.device, 'JOYSTICK')
            device_opt.JOYSTICK = monkey_config.device.JOYSTICK;
        end
        if isfield(monkey_config.device, 'EYELINK')
            device_opt.EYELINK = monkey_config.device.EYELINK;
        end
        if isfield(monkey_config.device, 'ARDUINO')
            device_opt.ARDUINO = monkey_config.device.ARDUINO;
        end
    end
end
