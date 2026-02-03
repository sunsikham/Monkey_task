device_opt.dq = arduino('COM4', 'Uno');

% Configure digital pin for solenoid control
rewardPin = 'D2'; % Pin used for reward solenoid
configurePin(device_opt.dq, rewardPin, 'DigitalOutput');
device_opt.rewardPin = rewardPin;


disp('Testing reward solenoid...');
rewardDuration = 5; % 500ms for testing
writeDigitalPin(device_opt.dq, rewardPin, 1); % Deactivate solenoid

pause(rewardDuration);
writeDigitalPin(device_opt.dq, rewardPin, 0); % Deactivate solenoid
disp('Reward solenoid test complete.');