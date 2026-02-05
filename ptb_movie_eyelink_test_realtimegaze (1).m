function ptb_movie_eyelink_test_realtimegaze(movieFiles, thumbFiles, useDummyMode, stimScreen, mainScreen)
% Plays main video on STIM screen, gaze dot window on MAIN screen.
% After main ends: show 3 thumbnails on STIM, select by dwell, then play chosen next movie.
%
% movieFiles = {main, vid2, vid3, vid4, ...}
% thumbFiles = {thumb2, thumb3, thumb4}  (corresponding to movieFiles{2:4})

if nargin < 3 || isempty(useDummyMode), useDummyMode = 0; end
if ischar(movieFiles) || isstring(movieFiles), movieFiles = {char(movieFiles)}; end
if nargin < 2 || isempty(thumbFiles), thumbFiles = {}; end
if ischar(thumbFiles) || isstring(thumbFiles), thumbFiles = {char(thumbFiles)}; end

try
    AssertOpenGL;
    KbName('UnifyKeyNames');
    escKey = KbName('ESCAPE');

    Screen('Preference','SkipSyncTests', 1); % debugging; set 0 later
    PsychDefaultSetup(2);

    screens = Screen('Screens');
    screensNo0 = screens(screens ~= 0);

    if nargin < 4 || isempty(stimScreen) || nargin < 5 || isempty(mainScreen)
        if numel(screensNo0) < 2
            warning('Only one non-zero PTB screen found. Both windows will be on the same monitor.');
            stimScreen = screensNo0(1);
            mainScreen = screensNo0(1);
        else
            mainScreen = min(screensNo0);
            stimScreen = max(screensNo0);
        end
    end

    fprintf('Using mainScreen=%d stimScreen=%d\n', mainScreen, stimScreen);

    % =========================================================
    % Open windows
    % =========================================================
    [winStim, stimRect] = PsychImaging('OpenWindow', stimScreen, 0);
    Priority(MaxPriority(winStim));
    HideCursor(winStim);
    stimW = RectWidth(stimRect);
    stimH = RectHeight(stimRect);

    gazeWinLocalRect = [100 120 820 620];
    [winGaze, gazeRect] = PsychImaging('OpenWindow', mainScreen, 0, gazeWinLocalRect);
    gazeRectIn = InsetRect(gazeRect, 15, 15);

    % Quick debug labels
    Screen('FillRect', winStim, 0);  DrawFormattedText(winStim, 'STIM WINDOW', 'center','center',[255 255 255]); Screen('Flip', winStim);
    Screen('FillRect', winGaze, 50); DrawFormattedText(winGaze, 'GAZE WINDOW', 'center','center',[255 255 255]); Screen('Flip', winGaze);
    WaitSecs(0.6);

    % =========================================================
    % EyeLink init (bind defaults to STIM)
    % =========================================================
    el = EyelinkInitDefaults(winStim);
    el.backgroundcolour = 0;
    el.foregroundcolour = 255;
    el.msgfontcolour    = 255;
    el.imgtitlecolour   = 255;
    EyelinkUpdateDefaults(el);

    if ~EyelinkInit(useDummyMode)
        error('EyelinkInit failed. Is the tracker connected?');
    end

    edfFile = 'MOVTEST.edf';
    if Eyelink('Openfile', edfFile) ~= 0
        error('Cannot create EDF file on Host PC.');
    end

    Eyelink('Command', 'file_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON');
    Eyelink('Command', 'file_sample_data  = LEFT,RIGHT,GAZE,AREA,GAZERES,STATUS,HTARGET');
    Eyelink('Command', 'link_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,BUTTON');
    Eyelink('Command', 'link_sample_data  = LEFT,RIGHT,GAZE,AREA,GAZERES,STATUS,HTARGET');

    Eyelink('Message', 'START_MOVIE_TASK');

    EyelinkDoTrackerSetup(el);

    Eyelink('StartRecording');
    WaitSecs(0.05);
    Eyelink('Message','RECORDING_START');

    % =========================================================
    % Preload thumbnails on STIM
    % =========================================================
    thumbTex = [];
    if ~isempty(thumbFiles)
        thumbTex = zeros(1, numel(thumbFiles));
        for i = 1:numel(thumbFiles)
            img = imread(thumbFiles{i});
            thumbTex(i) = Screen('MakeTexture', winStim, img);
        end
    end

    % =========================================================
    % Logs (for main movie)
    % =========================================================
    gazeLog = nan(250000,5); % [tFlipStim, eyeTime, gx, gy, pa]
    n = 0;
    tStart = GetSecs;

    lastValid = false; lastX = NaN; lastY = NaN;
    rDot = 8;

    % =========================================================
    % --------- PLAY MOVIE #1 (MAIN) ----------
    % =========================================================
    if isempty(movieFiles), error('movieFiles is empty'); end
    movieFile = movieFiles{1};

    [moviePtr, duration, fps, mw, mh] = Screen('OpenMovie', winStim, movieFile, 0, 1, 2);
    Screen('PlayMovie', moviePtr, 1, 0, 1.0);

    scale = min(stimW/mw, stimH/mh);
    dstStim = CenterRectOnPoint(ScaleRect([0 0 mw mh], scale, scale), stimW/2, stimH/2);

    Eyelink('Message','MOVIE_START_MAIN');

    while true
        tex = Screen('GetMovieImage', winStim, moviePtr, 1);
        if tex <= 0, break; end

        % Read gaze once/frame
        haveSample = false; gx = NaN; gy = NaN; pa = NaN; eyeTime = NaN;
        if Eyelink('NewFloatSampleAvailable') > 0
            fs = Eyelink('NewestFloatSample');
            gx = fs.gx(1); gy = fs.gy(1); pa = fs.pa(1);
            if gx == el.MISSING_DATA || gy == el.MISSING_DATA
                gx = fs.gx(2); gy = fs.gy(2); pa = fs.pa(2);
            end
            eyeTime = fs.time;
            haveSample = isfinite(gx) && isfinite(gy) && gx~=el.MISSING_DATA && gy~=el.MISSING_DATA;
        end

        % Draw movie
        Screen('FillRect', winStim, 0);
        Screen('DrawTexture', winStim, tex, [], dstStim);
        Screen('Close', tex);
        tFlipStim = Screen('Flip', winStim);

        % Draw gaze dot window
        Screen('FillRect', winGaze, [20 20 20]);
        Screen('FrameRect', winGaze, [200 200 200], gazeRect, 2);
        DrawFormattedText(winGaze, 'Realtime gaze (STIM coords)', gazeRectIn(1), gazeRectIn(2)-25, [200 200 200]);

        if haveSample
            gxC = min(max(gx,0), stimW-1);
            gyC = min(max(gy,0), stimH-1);
            nx = gxC / stimW; ny = gyC / stimH;
            xDot = gazeRectIn(1) + nx * RectWidth(gazeRectIn);
            yDot = gazeRectIn(2) + ny * RectHeight(gazeRectIn);
            lastX = xDot; lastY = yDot; lastValid = true;
            Screen('FillOval', winGaze, [0 255 0], [xDot-rDot yDot-rDot xDot+rDot yDot+rDot]);
        else
            if lastValid
                Screen('FillOval', winGaze, [255 255 0], [lastX-rDot lastY-rDot lastX+rDot lastY+rDot]);
            else
                [cx,cy] = RectCenter(gazeRectIn);
                Screen('FillOval', winGaze, [255 0 0], [cx-rDot cy-rDot cx+rDot cy+rDot]);
            end
        end
        Screen('Flip', winGaze);

        % Log
        if ~isnan(eyeTime)
            n = n + 1;
            if n > size(gazeLog,1), gazeLog(end+100000,:) = nan; end %#ok<AGROW>
            if haveSample
                gxStore = min(max(gx,0), stimW-1);
                gyStore = min(max(gy,0), stimH-1);
            else
                gxStore = gx; gyStore = gy;
            end
            gazeLog(n,:) = [tFlipStim, eyeTime, gxStore, gyStore, pa];
        end

        % ESC abort
        [down,~,keyCode] = KbCheck;
        if down && keyCode(escKey)
            Eyelink('Message','ABORT_BY_ESC');
            break;
        end
    end

    Screen('PlayMovie', moviePtr, 0);
    Screen('CloseMovie', moviePtr);
    Eyelink('Message','MOVIE_END_MAIN');

    % =========================================================
    % --------- END SCREEN: THUMB SELECTION ----------
    % =========================================================
    chosenVideoIdx = [];
    if ~isempty(thumbTex) && numel(thumbTex) >= 3 && numel(movieFiles) >= 4

        candMovieIdx = [2 3 4]; % candidates

        margin = round(0.10 * stimW);
        gap    = round(0.05 * stimW);
        thumbW = floor((stimW - 2*margin - 2*gap) / 3);
        thumbH = floor(thumbW * 9/16);
        y1 = round(stimH * 0.35);
        y2 = y1 + thumbH;

        thumbRect = zeros(3,4);
        for k = 1:3
            x1 = margin + (k-1)*(thumbW + gap);
            x2 = x1 + thumbW;
            thumbRect(k,:) = [x1 y1 x2 y2];
        end

        dwell = zeros(1,3);
        dwellThresh = 0.80;
        timeoutSec  = 10.0;

        selectedK = 0;
        tPrev = GetSecs;
        tStartChoose = tPrev;

        Eyelink('Message','ENDSCREEN_START');

        while selectedK == 0
            tNow = GetSecs;
            dt = tNow - tPrev;
            tPrev = tNow;

            [down,~,keyCode] = KbCheck;
            if down && keyCode(escKey)
                Eyelink('Message','ENDSCREEN_ABORT_ESC');
                selectedK = 1;
                break;
            end

            haveGaze = false; gxS = NaN; gyS = NaN;
            if Eyelink('NewFloatSampleAvailable') > 0
                fs = Eyelink('NewestFloatSample');
                gxS = fs.gx(1); gyS = fs.gy(1);
                if gxS == el.MISSING_DATA || gyS == el.MISSING_DATA
                    gxS = fs.gx(2); gyS = fs.gy(2);
                end
                haveGaze = isfinite(gxS) && isfinite(gyS) && gxS~=el.MISSING_DATA && gyS~=el.MISSING_DATA;
            end

            lookedK = 0;
            if haveGaze
                gxS = min(max(gxS,0), stimW-1);
                gyS = min(max(gyS,0), stimH-1);
                for k = 1:3
                    if IsInRect(gxS, gyS, thumbRect(k,:))
                        lookedK = k;
                        dwell(k) = dwell(k) + dt;
                        break;
                    end
                end
            end

            Screen('FillRect', winStim, 0);
            DrawFormattedText(winStim, 'Look at a thumbnail to select next video', 'center', round(stimH*0.20), [255 255 255]);

            for k = 1:3
                Screen('DrawTexture', winStim, thumbTex(k), [], thumbRect(k,:));
                if k == lookedK
                    Screen('FrameRect', winStim, [255 0 0], thumbRect(k,:), 8);
                else
                    Screen('FrameRect', winStim, [200 200 200], thumbRect(k,:), 2);
                end

                bar = thumbRect(k,:);
                bar(2) = bar(4) + 12;
                bar(4) = bar(2) + 12;
                frac = min(dwell(k)/dwellThresh, 1);
                barFill = bar;
                barFill(3) = barFill(1) + round(frac * RectWidth(bar));
                Screen('FrameRect', winStim, [200 200 200], bar, 1);
                Screen('FillRect',  winStim, [200 200 200], barFill);
            end

            Screen('Flip', winStim);

            [mx, kbest] = max(dwell);
            if mx >= dwellThresh
                selectedK = kbest;
                Eyelink('Message', sprintf('ENDSCREEN_SELECT_SLOT_%d', selectedK));
            end

            if (tNow - tStartChoose) > timeoutSec
                selectedK = kbest;
                Eyelink('Message', sprintf('ENDSCREEN_TIMEOUT_SELECT_SLOT_%d', selectedK));
            end
        end

        chosenVideoIdx = candMovieIdx(selectedK);
        fprintf('Chosen next video index = %d\n', chosenVideoIdx);
        Eyelink('Message', sprintf('CHOSEN_VIDEO_%d', chosenVideoIdx));
        Eyelink('Message','ENDSCREEN_END');
    end

    % =========================================================
    % --------- PLAY MOVIE #2 (CHOSEN) ----------
    % =========================================================
    if ~isempty(chosenVideoIdx)
        nextMovieFile = movieFiles{chosenVideoIdx};

        [moviePtr2, duration2, fps2, mw2, mh2] = Screen('OpenMovie', winStim, nextMovieFile, 0, 1, 2);
        Screen('PlayMovie', moviePtr2, 1, 0, 1.0);

        scale2 = min(stimW/mw2, stimH/mh2);
        dstStim2 = CenterRectOnPoint(ScaleRect([0 0 mw2 mh2], scale2, scale2), stimW/2, stimH/2);

        Eyelink('Message', sprintf('MOVIE_START_NEXT_%d', chosenVideoIdx));

        while true
            tex = Screen('GetMovieImage', winStim, moviePtr2, 1);
            if tex <= 0, break; end

            % (optional) keep gaze window updating while next movie plays:
            haveSample = false; gx = NaN; gy = NaN;
            if Eyelink('NewFloatSampleAvailable') > 0
                fs = Eyelink('NewestFloatSample');
                gx = fs.gx(1); gy = fs.gy(1);
                if gx == el.MISSING_DATA || gy == el.MISSING_DATA
                    gx = fs.gx(2); gy = fs.gy(2);
                end
                haveSample = isfinite(gx) && isfinite(gy) && gx~=el.MISSING_DATA && gy~=el.MISSING_DATA;
            end

            Screen('FillRect', winStim, 0);
            Screen('DrawTexture', winStim, tex, [], dstStim2);
            Screen('Close', tex);
            Screen('Flip', winStim);

            Screen('FillRect', winGaze, [20 20 20]);
            Screen('FrameRect', winGaze, [200 200 200], gazeRect, 2);
            DrawFormattedText(winGaze, 'Realtime gaze (STIM coords)', gazeRectIn(1), gazeRectIn(2)-25, [200 200 200]);

            if haveSample
                gxC = min(max(gx,0), stimW-1);
                gyC = min(max(gy,0), stimH-1);
                nx = gxC / stimW; ny = gyC / stimH;
                xDot = gazeRectIn(1) + nx * RectWidth(gazeRectIn);
                yDot = gazeRectIn(2) + ny * RectHeight(gazeRectIn);
                lastX = xDot; lastY = yDot; lastValid = true;
                Screen('FillOval', winGaze, [0 255 0], [xDot-rDot yDot-rDot xDot+rDot yDot+rDot]);
            else
                if lastValid
                    Screen('FillOval', winGaze, [255 255 0], [lastX-rDot lastY-rDot lastX+rDot lastY+rDot]);
                else
                    [cx,cy] = RectCenter(gazeRectIn);
                    Screen('FillOval', winGaze, [255 0 0], [cx-rDot cy-rDot cx+rDot cy+rDot]);
                end
            end
            Screen('Flip', winGaze);

            [down,~,keyCode] = KbCheck;
            if down && keyCode(escKey)
                Eyelink('Message','ABORT_BY_ESC');
                break;
            end
        end

        Screen('PlayMovie', moviePtr2, 0);
        Screen('CloseMovie', moviePtr2);
        Eyelink('Message', sprintf('MOVIE_END_NEXT_%d', chosenVideoIdx));
    end

    % =========================================================
    % Stop recording / save
    % =========================================================
    Eyelink('StopRecording');
    Eyelink('Message','RECORDING_STOP');
    Eyelink('CloseFile');

    localEdf = fullfile(pwd, edfFile);
    try
        Eyelink('ReceiveFile', edfFile, localEdf, 1);
        fprintf('EDF saved to: %s\n', localEdf);
    catch
        warning('Could not receive EDF automatically. Copy it from Host PC if needed.');
    end

    Eyelink('Shutdown');

    gazeLog = gazeLog(1:n,:);
    save('gaze_per_frame_log.mat', 'gazeLog', 'movieFiles', 'thumbFiles', 'tStart', 'mainScreen', 'stimScreen');

    Priority(0);
    ShowCursor;

    if ~isempty(thumbTex)
        Screen('Close', thumbTex);
    end

    sca;
    fprintf('Done. Frames with gaze samples logged (MAIN movie): %d\n', n);

catch ME
    try Screen('CloseAll'); catch, end
    try Eyelink('Shutdown'); catch, end
    Priority(0); ShowCursor;
    rethrow(ME);
end
end
