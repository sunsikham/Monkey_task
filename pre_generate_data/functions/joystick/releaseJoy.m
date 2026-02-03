function releaseJoy(opt)
% If joystick not released after reward, program cannot proceed
done = 0;
while done < 10
    [joy_vec, ~] = JoyMEX(0);
    if sum(abs(joy_vec(1:2))) < opt.minInput, done = done + 1; end
    if strcmp(opt.rewardAreaShape, 'rectangle')
        Screen('FillRect', opt.window, [255, 0, 0], opt.rewardArea);
        Screen('FillOval', opt.window, [255, 0, 0], opt.avatarArea);
        Screen('Flip', opt.window);
    elseif strcmp(opt.rewardAreaShape, 'two rectangle')
        Screen('FillRect', opt.window, [255, 0, 0], opt.rewardArea1);
        Screen('FillRect', opt.window, [255, 0, 0], opt.rewardArea2);
        Screen('FillOval', opt.window, [255, 0, 0], opt.avatarArea);
        Screen('Flip', opt.window);
    elseif strcmp(opt.rewardAreaShape, 'circle')
        Screen('FillRect', opt.window, [255, 0, 0]);
        Screen('FillOval', opt.window, [255, 255, 255], opt.rewardArea);
        Screen('FillOval', opt.window, [255, 0, 0], opt.avatarArea);
        Screen('Flip', opt.window);
    end
end
end

