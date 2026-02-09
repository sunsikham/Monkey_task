function visual_opt = initialize_ptb_windows(visual_opt)
% initialize_ptb_windows
% Opens the stimulus window once and computes geometry based on its size.

    Screen('Preference', 'SkipSyncTests', 1);

    if ~isfield(visual_opt, 'screen_number') || isempty(visual_opt.screen_number)
        screens = Screen('Screens');
        screens = screens(screens ~= 0);
        visual_opt.screen_number = max(screens);
    end

    [visual_opt.winPtr, ~] = Screen('OpenWindow', visual_opt.screen_number, visual_opt.screen_color);
    visual_opt.refresh_rate = Screen('NominalFrameRate', visual_opt.winPtr);
    fprintf('Monitor refresh rate: %.2f Hz\n', visual_opt.refresh_rate);

    rect = Screen('Rect', visual_opt.winPtr);
    visual_opt.subject_winRect = rect;
    [visual_opt.wWth, visual_opt.wHgt] = Screen('WindowSize', visual_opt.winPtr);
    visual_opt.screen_center = [visual_opt.wWth / 2, visual_opt.wHgt / 2];
    visual_opt.subject_size = [visual_opt.wWth, visual_opt.wHgt];

    % ---- Geometry (copied from set_visual_opt) ----
    safe_plase = 200;
    visual_opt.coordinate_window = visual_opt.wHgt / 2;

    visual_opt.corridor_coord = [
        visual_opt.wWth / 2 - visual_opt.corridor_thickness, ...
        visual_opt.coordinate_window - visual_opt.corridor_thickness;
        visual_opt.wWth / 2 - visual_opt.corridor_thickness, ...
        visual_opt.coordinate_window + visual_opt.corridor_thickness;
        visual_opt.wWth / 2 + visual_opt.corridor_thickness, 1;
        visual_opt.wWth / 2 + visual_opt.corridor_thickness, visual_opt.wHgt
    ];

    visual_opt.left_boundary = struct(...
        'left', 0, ...
        'right', visual_opt.wWth / 2 - visual_opt.corridor_thickness, ...
        'top', safe_plase, ...
        'bottom', visual_opt.wHgt - safe_plase, ...
        'window_top', visual_opt.coordinate_window - visual_opt.gap_size / 2, ...
        'window_bottom', visual_opt.coordinate_window + visual_opt.gap_size / 2 ...
    );

    visual_opt.right_boundary = struct(...
        'left', visual_opt.wWth / 2 + visual_opt.corridor_thickness, ...
        'right', visual_opt.wWth, ...
        'top', safe_plase, ...
        'bottom', visual_opt.wHgt - safe_plase ...
    );

    [visual_opt.left_center, visual_opt.right_center] = calculateCorridorCenters(...
        visual_opt.wWth, visual_opt.wHgt, visual_opt.corridor_thickness);
end

function [left_center, right_center] = calculateCorridorCenters(wWth, wHgt, corridor_thickness)
    left_x = (0 + (wWth / 2 - corridor_thickness)) / 2;
    right_x = ((wWth / 2 + corridor_thickness) + wWth) / 2;
    center_y = wHgt / 2;
    left_center = [left_x, center_y];
    right_center = [right_x, center_y];
end
