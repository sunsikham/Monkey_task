function run_session()
% run_session
% Master session runner: select monkey -> calibrate -> run task without closing PTB.

    cleanupObj = onCleanup(@()cleanup_ptb()); %#ok<NASGU>

    try
        % Load config only (no PTB windows, no eyelink init)
        [visual_opt, device_opt, game_opt, eye_opt, save_directory] = initalize(false, 'config_only');
        if isempty(visual_opt)
            return;
        end

        % Open PTB windows once
        visual_opt = initialize_ptb_windows(visual_opt);
        visual_opt = open_operator_window(visual_opt);

        % Run calibration using existing windows
        if eye_opt.eyelink_on
            Eyelink_BigOnScreen1_SmallOnScreen2_GainOffset_WASD_LOG_FlipXY(visual_opt, eye_opt, device_opt);
        else
            disp('Eyelink disabled in config. Skipping calibration.');
        end

        % Run main task using existing windows
        New_task(visual_opt, device_opt, game_opt, eye_opt, save_directory);

    catch ME
        fprintf('ERROR in session: %s\n', ME.message);
        rethrow(ME);
    end
end

function cleanup_ptb()
    try Screen('CloseAll'); catch, end
    try Priority(0); catch, end
    try ShowCursor; catch, end
end
