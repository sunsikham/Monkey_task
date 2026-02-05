% Function to display break screen
function display_break_screen(visual_opt, device_opt, current_session, total_sessions)
    % Create the break screen
    Screen('FillRect', visual_opt.winPtr, [255, 255, 255] / 2);
    
    % Display break text
    completed = current_session;
    remaining = total_sessions - current_session;
    
    breakText = sprintf('You have completed %d out of %d sessions.\n\nPlease take a short break.\n\nPress any key when you are ready to continue.', ...
        completed, total_sessions);
    
    DrawFormattedText(visual_opt.winPtr, breakText, 'center', 'center', [255, 255, 255]);
    Screen('Flip', visual_opt.winPtr);
    
    % Wait for keypress to continue
    KbStrokeWait;
    
    % Eye tracker recalibration after break is disabled.

    
    % Display the start screen for the next session
    display_start_screen(visual_opt, device_opt);
end
