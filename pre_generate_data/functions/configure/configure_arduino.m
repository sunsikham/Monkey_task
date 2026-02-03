function device_opt = configure_arduino(device_opt, monkey_config)
    % Configure Arduino for solenoid control using monkey_config
    
    % Get the COM port and Arduino activation flag from monkey_config
    comPort = monkey_config.device.arduino_port;
    device_opt.activate_arduino = monkey_config.device_activate_arduino;
    
    portList = serialportlist("available");
    disp('Available serial ports:');
    disp(portList);

    % Clear existing Arduino object if it exists in device_opt
    if isfield(device_opt, 'arduino') && ~isempty(device_opt.arduino)
        disp('Removing existing Arduino object...');
        device_opt.arduino = []; % Clear the existing object reference
    end
    
    % Check if the COM port is available
    if ~ismember(comPort, portList)
        error('COM port %s is not available. Ensure the device is connected.', comPort);
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