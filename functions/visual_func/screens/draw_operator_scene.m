function draw_operator_scene(visual_opt, eye_opt, layout, mode, varargin)
% draw_operator_scene
% Renders a scaled version of the task background on the operator window and overlays gaze.
%
% mode:
%   'choice'  -> render_map_from_layout1(visual_opt_op, layout_op, tri_color)
%   'pursuit' -> draw_new_MAP_pursuit(visual_opt_op, game_opt, choice, data, layout_op)

    if ~isfield(visual_opt, 'op_winPtr') || isempty(visual_opt.op_winPtr)
        return;
    end
    win = visual_opt.op_winPtr;
    if Screen('WindowKind', win) ~= 1
        return;
    end

    % Subject/op rects and scale
    if isfield(visual_opt, 'subject_winRect') && ~isempty(visual_opt.subject_winRect)
        subjRect = visual_opt.subject_winRect;
    else
        subjRect = [0 0 visual_opt.wWth visual_opt.wHgt];
    end
    if isfield(visual_opt, 'op_winRect') && ~isempty(visual_opt.op_winRect)
        opRect = visual_opt.op_winRect;
    else
        opRect = Screen('Rect', win);
    end

    subjW = subjRect(3) - subjRect(1);
    subjH = subjRect(4) - subjRect(2);
    opW = opRect(3) - opRect(1);
    opH = opRect(4) - opRect(2);

    if subjW <= 0 || subjH <= 0 || opW <= 0 || opH <= 0
        return;
    end

    scale = [opW / subjW, opH / subjH];

    % Build scaled layout
    layout_op = scale_layout(layout, scale);

    % Temporary visual_opt for operator window
    visual_opt_op = visual_opt;
    visual_opt_op.winPtr = win;
    visual_opt_op.wWth = opW;
    visual_opt_op.wHgt = opH;
    visual_opt_op.screen_center = [opW/2, opH/2];

    % Render background
    switch lower(mode)
        case 'choice'
            tri_color = [0 0 255];
            if ~isempty(varargin)
                tri_color = varargin{1};
            end
            render_map_from_layout1(visual_opt_op, layout_op, tri_color);
        case 'pursuit'
            if numel(varargin) >= 2
                game_opt = varargin{1};
                data = varargin{2};
                draw_new_MAP_pursuit(visual_opt_op, game_opt, data.CHOICE.choice, data, layout_op);
            else
                Screen('FillRect', win, 0);
            end
        otherwise
            Screen('FillRect', win, 0);
    end

    % Draw gaze (scaled to operator)
    gaze_sub = get_mapped_gaze_subject(eye_opt, subjW, subjH);
    if all(isfinite(gaze_sub))
        gaze_op = [gaze_sub(1) * scale(1), gaze_sub(2) * scale(2)];
        dotR = 20;
        Screen('FillOval', win, [0 255 0], ...
            [gaze_op(1)-dotR, gaze_op(2)-dotR, gaze_op(1)+dotR, gaze_op(2)+dotR]);
    end

    Screen('Flip', win, 0, 1);
end

function layout_op = scale_layout(layout, scale)
% scale_layout
% Scales coordinate-like fields in a layout struct.

    layout_op = layout;
    if isempty(layout)
        return;
    end

    fields = fieldnames(layout);
    for i = 1:numel(fields)
        fname = fields{i};
        val = layout.(fname);
        if ~isnumeric(val)
            continue;
        end

        lname = lower(fname);
        is_coord_field = contains(lname, 'rect') || contains(lname, 'coord') || ...
                         contains(lname, 'corridor') || contains(lname, 'poly') || ...
                         contains(lname, 'tri');

        if ~is_coord_field
            continue;
        end

        layout_op.(fname) = scale_coords(val, scale);
    end
end

function out = scale_coords(val, scale)
    out = val;
    sx = scale(1); sy = scale(2);

    if isvector(val) && numel(val) == 4
        out = val;
        out([1 3]) = out([1 3]) * sx;
        out([2 4]) = out([2 4]) * sy;
        return;
    end

    if size(val,1) == 4
        out = val;
        out(1,:) = out(1,:) * sx;
        out(3,:) = out(3,:) * sx;
        out(2,:) = out(2,:) * sy;
        out(4,:) = out(4,:) * sy;
        return;
    end

    if size(val,1) == 2
        out = val;
        out(1,:) = out(1,:) * sx;
        out(2,:) = out(2,:) * sy;
        return;
    end

    if size(val,2) == 2
        out = val;
        out(:,1,:) = out(:,1,:) * sx;
        out(:,2,:) = out(:,2,:) * sy;
        return;
    end
end

function gaze_xy = get_mapped_gaze_subject(eye_opt, W, H)
% get_mapped_gaze_subject
% Returns smoothed gaze in subject coords with gain/offset/flip applied.

    gaze_xy = [NaN NaN];
    if ~isfield(eye_opt, 'eyelink_on') || ~eye_opt.eyelink_on
        return;
    end
    if Eyelink('IsConnected') <= 0
        return;
    end

    persistent smoothXY mapParams mapFileMTime
    if isempty(smoothXY)
        smoothXY = [NaN NaN];
    end
    if isempty(mapParams)
        mapParams = struct();
    end
    mapFile = get_gain_offset_param_path();
    if exist(mapFile, 'file')
        info = dir(mapFile);
        if isempty(mapFileMTime) || info.datenum ~= mapFileMTime
            try
                mapParams = load(mapFile);
            catch
                mapParams = struct();
            end
            mapFileMTime = info.datenum;
        end
    else
        mapParams = struct();
        mapFileMTime = [];
    end

    avail = Eyelink('NewFloatSampleAvailable');
    assignin('base', 'EL_NFSA', avail);
    if avail > 0
        s = Eyelink('NewestFloatSample');
        gxL = double(s.gx(1)); gyL = double(s.gy(1));
        gxR = double(s.gx(2)); gyR = double(s.gy(2));
        okL = isfinite(gxL) && isfinite(gyL) && gxL > -32000 && gyL > -32000;
        okR = isfinite(gxR) && isfinite(gyR) && gxR > -32000 && gyR > -32000;

        ix = 0;
        if isfield(eye_opt, 'eye_side') && eye_opt.eye_side == 2 && okR
            ix = 2;
        elseif isfield(eye_opt, 'eye_side') && eye_opt.eye_side == 1 && okL
            ix = 1;
        elseif okL
            ix = 1;
        elseif okR
            ix = 2;
        end

        if ix == 1
            gx = gxL; gy = gyL;
        elseif ix == 2
            gx = gxR; gy = gyR;
        else
            gx = NaN; gy = NaN;
        end

        if isfinite(gx) && isfinite(gy) && gx > -32000 && gy > -32000
            if isfield(mapParams, 'flipX') && mapParams.flipX
                gx = (W - 1) - gx;
            end
            if isfield(mapParams, 'flipY') && mapParams.flipY
                gy = (H - 1) - gy;
            end
            if isfield(mapParams, 'gx')
                gx = mapParams.gx * gx + mapParams.ox;
            end
            if isfield(mapParams, 'gy')
                gy = mapParams.gy * gy + mapParams.oy;
            end

            gx = min(max(gx, 0), W-1);
            gy = min(max(gy, 0), H-1);

            alpha = 0.15;
            if any(isnan(smoothXY))
                smoothXY = [gx gy];
            else
                smoothXY = alpha * [gx gy] + (1 - alpha) * smoothXY;
            end
        end
    end

    gaze_xy = smoothXY;
end

function paramFile = get_gain_offset_param_path()
    % Use a fixed path relative to the project root (where initalize.m lives).
    baseDir = fileparts(which('initalize'));
    if isempty(baseDir)
        baseDir = pwd;
    end
    paramFile = fullfile(baseDir, 'logs', 'calibration', 'gain_offset_params.mat');
end
