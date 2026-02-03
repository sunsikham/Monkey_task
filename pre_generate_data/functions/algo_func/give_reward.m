
function give_reward(device_opt, rewardDuration)
% sendRewardSignal - Activates a digital pin on Arduino for reward delivery.
%
% Syntax: sendRewardSignal(device_opt, rewardDuration)
%
% Inputs:
%    device_opt - Structure containing Arduino configuration (expects device_opt.ARDUINO and device_opt.arduino)
%    rewardDuration - Duration in seconds for how long the pin stays high
%
% Example:
%    sendRewardSignal(device_opt, 2); % Activates pin D2 for 2 seconds

    if device_opt.ARDUINO
        % Set digital pin D2 to HIGH
        writeDigitalPin(device_opt.arduino, 'D2', device_opt.activate_arduino);
        bgn = GetSecs;

        % Keep the pin HIGH for the reward duration
        while (GetSecs - bgn <= rewardDuration)
            % Busy wait
        end

        % Set digital pin D2 to LOW
        writeDigitalPin(device_opt.arduino, 'D2', ~device_opt.activate_arduino);
    else
        disp('ARDUINO NOT ACTIVE');
    end
end

