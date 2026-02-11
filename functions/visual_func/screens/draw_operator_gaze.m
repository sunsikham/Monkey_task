function draw_operator_gaze(visual_opt, eye_opt)
% draw_operator_gaze
% Draws live gaze cursor on operator window (non-blocking).

    if ~isfield(visual_opt, 'op_winPtr') || isempty(visual_opt.op_winPtr)
        return;
    end

    win = visual_opt.op_winPtr;
    if Screen('WindowKind', win) ~= 1
        return;
    end

    if ~isfield(visual_opt, 'subject_size')
        visual_opt.subject_size = [visual_opt.wWth, visual_opt.wHgt];
    end
    if ~isfield(visual_opt, 'op_size')
        rect = Screen('Rect', win);
        visual_opt.op_size = [rect(3) - rect(1), rect(4) - rect(2)];
    end

    if ~isfield(eye_opt, 'eyelink_on') || ~eye_opt.eyelink_on
        return;
    end
    if Eyelink('IsConnected') <= 0
        return;
    end

    persistent smoothXY lastXY mapParams mapFileMTime
    if isempty(smoothXY)
        smoothXY = [NaN NaN];
        lastXY = [NaN NaN];
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

    subjectW = visual_opt.subject_size(1);
    subjectH = visual_opt.subject_size(2);
    opW = visual_opt.op_size(1);
    opH = visual_opt.op_size(2);

    if Eyelink('NewFloatSampleAvailable') > 0
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
            % Apply optional gain/offset/flip from calibration file
            if isfield(mapParams, 'flipX') && mapParams.flipX
                gx = (subjectW - 1) - gx;
            end
            if isfield(mapParams, 'flipY') && mapParams.flipY
                gy = (subjectH - 1) - gy;
            end
            if isfield(mapParams, 'gx')
                gx = mapParams.gx * gx + mapParams.ox;
            end
            if isfield(mapParams, 'gy')
                gy = mapParams.gy * gy + mapParams.oy;
            end

            gx = min(max(gx, 0), subjectW-1);
            gy = min(max(gy, 0), subjectH-1);

            % Map to operator window coords
            gx = gx * (opW-1) / max(subjectW-1, 1);
            gy = gy * (opH-1) / max(subjectH-1, 1);

            lastXY = [gx gy];
            if any(isnan(smoothXY))
                smoothXY = lastXY;
            end
            alpha = 0.15;
            smoothXY = alpha * lastXY + (1 - alpha) * smoothXY;
        end
    end

    Screen('FillRect', win, [0 0 0]);

    % Crosshair
    cx = opW / 2;
    cy = opH / 2;
    Screen('DrawLine', win, [200 200 200], cx-20, cy, cx+20, cy, 2);
    Screen('DrawLine', win, [200 200 200], cx, cy-20, cx, cy+20, 2);

    if all(isfinite(smoothXY))
        dotR = 20;
        Screen('FillOval', win, [0 255 0], ...
            [smoothXY(1)-dotR, smoothXY(2)-dotR, smoothXY(1)+dotR, smoothXY(2)+dotR]);
    end

    Screen('Flip', win, 0, 1);
end

function paramFile = get_gain_offset_param_path()
    % Use a fixed path relative to the project root (where initalize.m lives).
    baseDir = fileparts(which('initalize'));
    if isempty(baseDir)
        baseDir = pwd;
    end
    paramFile = fullfile(baseDir, 'logs', 'calibration', 'gain_offset_params.mat');
end
