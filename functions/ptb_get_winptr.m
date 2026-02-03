function win = ptb_get_winptr(visual_opt, allow_reopen)
% ptb_get_winptr - Return a valid PTB window pointer, reopening if allowed.

if nargin < 2
    allow_reopen = true;
end

win = [];
wkind = 0;

% Prefer cached window if available.
if isappdata(0, 'PTB_WINPTR')
    cached = getappdata(0, 'PTB_WINPTR');
    try
        if Screen('WindowKind', cached) > 0
            win = cached;
            return;
        end
    catch
    end
end

% Try the window pointer in visual_opt.
if isfield(visual_opt, 'winPtr') && ~isempty(visual_opt.winPtr)
    try
        wkind = Screen('WindowKind', visual_opt.winPtr);
    catch
        wkind = 0;
    end
    if wkind > 0
        win = visual_opt.winPtr;
        setappdata(0, 'PTB_WINPTR', win);
        return;
    end
end

% Reopen the window if allowed.
if ~allow_reopen
    error('PTB window is invalid/closed. Refusing to reopen during task.');
end
[win, ~] = Screen('OpenWindow', visual_opt.screen_number, visual_opt.screen_color);
setappdata(0, 'PTB_WINPTR', win);
end
