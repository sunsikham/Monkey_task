function visual_opt = open_operator_window(visual_opt)
% open_operator_window
% Opens a small operator window on a secondary monitor using global coords.

    if isfield(visual_opt, 'op_winPtr') && ~isempty(visual_opt.op_winPtr)
        try
            if Screen('WindowKind', visual_opt.op_winPtr) == 1
                return;
            end
        catch
        end
    end

    if ~isfield(visual_opt, 'operator_screen') || isempty(visual_opt.operator_screen)
        return;
    end

    if ~isfield(visual_opt, 'operator_rect_local') || isempty(visual_opt.operator_rect_local)
        visual_opt.operator_rect_local = [50 50 900 650];
    end

    try
        opRect = Screen('GlobalRect', visual_opt.operator_screen);
    catch
        opRect = Screen('Rect', visual_opt.operator_screen);
    end

    local = visual_opt.operator_rect_local;
    smallRect = local + [opRect(1) opRect(2) opRect(1) opRect(2)];

    try
        [winSmall, rectSmall] = Screen('OpenWindow', 0, [0 0 0], smallRect);
        Screen('BlendFunction', winSmall, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        visual_opt.op_winPtr = winSmall;
        visual_opt.op_rect = rectSmall;
        visual_opt.op_winRect = rectSmall;
        visual_opt.op_size = [rectSmall(3) - rectSmall(1), rectSmall(4) - rectSmall(2)];
    catch ME
        warning('Operator window open failed: %s', ME.message);
        visual_opt.op_winPtr = [];
    end
end
