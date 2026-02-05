function device_opt = configure_arduino(device_opt, monkey_config)
    % Configure Arduino for solenoid control using monkey_config
    
    % Get the COM port and Arduino activation flag from monkey_config
    if isfield(monkey_config, 'device') && isfield(monkey_config.device, 'arduino_port')
        comPort = monkey_config.device.arduino_port;
    else
        comPort = '';
    end
    if isfield(monkey_config, 'device_activate_arduino')
        device_opt.activate_arduino = monkey_config.device_activate_arduino;
    else
        device_opt.activate_arduino = 1;
    end
    portList = serialportlist("available");
    disp('Available serial ports:');
    disp(portList);

    % Clear existing Arduino object if it exists in device_opt
    if isfield(device_opt, 'arduino') && ~isempty(device_opt.arduino)
        disp('Removing existing Arduino object...');
        device_opt.arduino = []; % Clear the existing object reference
    end
    
    % Check if the COM port is available
    if isempty(comPort) || ~ismember(comPort, portList)
        if isempty(portList)
            error('No available serial ports found. Ensure the device is connected.');
        end
        fprintf('Configured COM port "%s" not available. Using "%s" instead.\n', comPort, portList(1));
        comPort = portList(1);
    end

    try
        device_opt.arduino = arduino(comPort, 'Uno');
        disp(['Arduino successfully connected on ', comPort]);

        % Configure digital pin for solenoid control
        rewardPin = 'D2'; % Pin used for reward solenoid
        configurePin(device_opt.arduino, rewardPin, 'DigitalOutput');
        device_opt.rewardPin = rewardPin;

        % Test solenoid signal
        disp('Testing reward solenoid...');
        rewardDuration = 0.5; % 500ms for testing
        writeDigitalPin(device_opt.arduino, rewardPin, device_opt.activate_arduino); % Activate solenoid
        pause(rewardDuration);
        writeDigitalPin(device_opt.arduino, rewardPin, ~device_opt.activate_arduino); % Deactivate solenoid
        disp('Reward solenoid test complete.');
    catch ME
        error('Failed to initialize Arduino connection on %s: %s', comPort, ME.message);
    end
end
