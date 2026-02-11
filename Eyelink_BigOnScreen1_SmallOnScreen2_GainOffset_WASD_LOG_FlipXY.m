function ok = Eyelink_BigOnScreen1_SmallOnScreen2_GainOffset_WASD_LOG_FlipXY(varargin)
% ============================================================
% BIG subject screen (Screen 1): ONLY RED target shown
% SMALL operator window (Screen 2): RED target + CYAN mapped gaze + GREEN smoothed gaze
%
% EyeLink-style mapping:
%   x_mapped = gx * x_raw + ox   (optionally flipX first)
%   y_mapped = gy * y_raw + oy   (optionally flipY first)
%
% Controls (letter-only):
%   Offset (ox, oy):   W/A/S/D  (SHIFT big / ALT small)
%   Gain gx:           O (down) / P (up)
%   Gain gy:           K (down) / L (up)
%   Toggle flipY:      F
%   Toggle flipX:      G
%   Reset params:      Backspace
%   Save/Load params:  1 / 2
%   Manual reward:     R
%   Quit:              ESC / X
% ============================================================

ok = true;
KbName('UnifyKeyNames');
ListenChar(2);

Screen('Preference','SkipSyncTests', 1);
PsychDefaultSetup(2);
AssertOpenGL;

% ---------------- USER SETTINGS ----------------
subjectScreen  = 1;
operatorScreen = 2;

reuse_windows = false;
visual_opt = [];
eye_opt = [];
device_opt = [];
if nargin >= 1 && isstruct(varargin{1})
    visual_opt = varargin{1};
    reuse_windows = isfield(visual_opt, 'winPtr') && ~isempty(visual_opt.winPtr);
end
if nargin >= 2 && isstruct(varargin{2})
    eye_opt = varargin{2};
end
if nargin >= 3 && isstruct(varargin{3})
    device_opt = varargin{3};
end

if reuse_windows
    try
        subjectScreen = Screen('WindowScreenNumber', visual_opt.winPtr);
    catch
    end
    if isfield(visual_opt, 'operator_screen') && ~isempty(visual_opt.operator_screen)
        operatorScreen = visual_opt.operator_screen;
    end
end
owns_windows = ~reuse_windows;

% Windowed rect uses global desktop coords; offset by operator screen origin.
smallRectLocal = [50 50 900 650];
try
    opRect = Screen('GlobalRect', operatorScreen);
catch
    opRect = Screen('Rect', operatorScreen);
end
smallRect = smallRectLocal + [opRect(1) opRect(2) opRect(1) opRect(2)];

showCrossBig   = true;
showCrossSmall = true;

targDotRadBig   = 70;
targDotRadSmall = 24;

rawDotRadSmall    = 10;   % CYAN
smoothDotRadSmall = 20;   % GREEN

alpha = 0.10;

bgColor     = [0 0 0];
txtColor    = [255 255 255];
targColor   = [255 0 0];
rawColor    = [0 200 255];
smoothColor = [0 255 0];
crossColor  = [200 200 200];
warnColor   = [255 255 0];

% --------- Gain/Offset parameters ----------
gx = 1.00;  gy = 1.00;
ox = 0.0;   oy = 0.0;

flipY = true;   % you already needed this earlier
flipX = true;   % NEW: left/right inverted -> start TRUE
% ------------------------------------------

stepSmall  = 1;
stepNormal = 5;
stepBig    = 20;

gainStep = 0.01;

paramFile = get_gain_offset_param_path();

logEveryNFrames = 1;
% -----------------------------------------------------------

% ---------- Manual reward (Arduino) ----------
enableReward   = true;
rewardDuration = 2; % seconds
rewardPin      = 'D2';
arduinoPort    = 'COM8';  % fixed port
activateArduino = 1;  % 1: HIGH opens valve, 0: LOW opens valve
% -----------------------------------------------------------
if ~isempty(device_opt)
    if isfield(device_opt, 'ARDUINO')
        enableReward = logical(device_opt.ARDUINO);
    end
    if isfield(device_opt, 'rewardPin') && ~isempty(device_opt.rewardPin)
        rewardPin = device_opt.rewardPin;
    end
    if isfield(device_opt, 'activate_arduino') && ~isempty(device_opt.activate_arduino)
        activateArduino = device_opt.activate_arduino;
    end
    if isfield(device_opt, 'arduino_port') && ~isempty(device_opt.arduino_port)
        arduinoPort = device_opt.arduino_port;
    end
end

% ---------- Keycodes ----------
KEY.ESC   = mustKey({'ESCAPE'});
KEY.X     = mustKey({'x','X'});
KEY.R     = mustKey({'r','R'});

KEY.LSHFT = maybeKey({'LeftShift','LeftShiftKey'});
KEY.RSHFT = maybeKey({'RightShift','RightShiftKey'});
KEY.LALT  = maybeKey({'LeftAlt','LeftOption'});
KEY.RALT  = maybeKey({'RightAlt','RightOption'});

KEY.W = mustKey({'w','W'});
KEY.A = mustKey({'a','A'});
KEY.S = mustKey({'s','S'});
KEY.D = mustKey({'d','D'});

KEY.GX_DOWN = mustKey({'o','O'});
KEY.GX_UP   = mustKey({'p','P'});

KEY.GY_DOWN = mustKey({'k','K'});
KEY.GY_UP   = mustKey({'l','L'});

KEY.FLIPY   = mustKey({'f','F'});
KEY.FLIPX   = mustKey({'g','G'});

KEY.RESET = mustKey({'BackSpace','Backspace','DELETE','Delete'});

KEY.SAVE = mustKey({'1','1!'});
KEY.LOAD = mustKey({'2','2@'});
% --------------------------------------------------

% ---------- Arduino init (optional) ----------
arduinoObj = [];
if enableReward
    try
        useExisting = false;
        if ~isempty(device_opt) && isfield(device_opt, 'arduino') && ~isempty(device_opt.arduino)
            try
                useExisting = isvalid(device_opt.arduino);
            catch
                useExisting = true;
            end
        end

        if useExisting
            arduinoObj = device_opt.arduino;
            configurePin(arduinoObj, rewardPin, 'DigitalOutput');
            writeDigitalPin(arduinoObj, rewardPin, ~activateArduino);
            disp('Using existing Arduino object for manual reward.');
        else
            portList = serialportlist("available");
            if isempty(portList)
                disp('No available serial ports found. Manual reward disabled.');
                enableReward = false;
            else
                if ~ismember(arduinoPort, portList)
                    fprintf('Configured COM port "%s" not available. Manual reward disabled.\n', arduinoPort);
                    enableReward = false;
                else
                    arduinoObj = arduino(arduinoPort, 'Uno');
                    configurePin(arduinoObj, rewardPin, 'DigitalOutput');
                    writeDigitalPin(arduinoObj, rewardPin, ~activateArduino);
                    fprintf('Arduino connected on %s for manual reward.\n', arduinoPort);
                end
            end
        end
    catch ME
        disp(['Arduino init failed: ', ME.message]);
        enableReward = false;
    end
end
% --------------------------------------------------

% Open BIG
if reuse_windows
    winBig = visual_opt.winPtr;
    rectBig = Screen('Rect', winBig);
else
    [winBig, rectBig] = Screen('OpenWindow', subjectScreen, bgColor);
end
Screen('BlendFunction', winBig, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
bigW = rectBig(3) - rectBig(1);
bigH = rectBig(4) - rectBig(2);
Screen('TextSize', winBig, 26);

% Open SMALL (windowed on desktop)
if reuse_windows && isfield(visual_opt, 'op_winPtr') && ~isempty(visual_opt.op_winPtr)
    winSmall = visual_opt.op_winPtr;
    rectSmall = Screen('Rect', winSmall);
else
    [winSmall, rectSmall] = Screen('OpenWindow', 0, bgColor, smallRect);
end
Screen('BlendFunction', winSmall, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
smallW = rectSmall(3) - rectSmall(1);
smallH = rectSmall(4) - rectSmall(2);
Screen('TextSize', winSmall, 18);

ShowCursor('Arrow');

% ---------------- Create log file ----------------
logName = get_gaze_target_log_path(device_opt);
fid = fopen(logName, 'w');
if fid < 0
    if owns_windows
        sca;
    end
    error('Could not open log file for writing.');
end
fprintf(fid, 'tSec,targX,targY,rawX,rawY,mapX,mapY,smoothX,smoothY,isValid,whichEye,gx,gy,ox,oy,flipX,flipY\n');

% ---------------- EyeLink init ----------------
status = Eyelink('Initialize');
if status ~= 0
    fclose(fid);
    if owns_windows
        sca;
    end
    error('Eyelink Initialize failed. Check Ethernet/link/Host state.');
end

EyelinkInitDefaults(winBig);

if Eyelink('IsConnected') <= 0
    try Eyelink('Shutdown'); catch, end
    fclose(fid);
    if owns_windows
        sca;
    end
    error('Eyelink is not connected. Check tracker link/host state.');
end

cmd = sprintf('screen_pixel_coords = %d %d %d %d', 0, 0, round(bigW-1), round(bigH-1));
msg = sprintf('DISPLAY_COORDS %d %d %d %d', 0, 0, round(bigW-1), round(bigH-1));
Eyelink('Command', cmd);
Eyelink('Message', msg);

Eyelink('Command', 'link_sample_data = LEFT,RIGHT,GAZE,GAZERES,AREA,STATUS');
Eyelink('Command', 'link_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,BUTTON,MESSAGE');

err = Eyelink('StartRecording', 0, 0, 1, 1);
if err ~= 0
    try Eyelink('Shutdown'); catch, end
    fclose(fid);
    if owns_windows
        sca;
    end
    error('StartRecording failed (err=%d). Check tracker streaming/mode.', err);
end
WaitSecs(0.1);

smoothXY   = [NaN; NaN];
lastMapped = [NaN; NaN];
frameCount = 0;
rWasDown   = false;
rewardActive = false;
rewardEndTime = 0;

try
    while true
        frameCount = frameCount + 1;

        % ---- Target from mouse in SMALL window -> BIG coords ----
        % Use global mouse position so cursor can move outside the small window.
        [mxGlobal, myGlobal] = GetMouse(0);
        mxWin = mxGlobal - smallRect(1);
        myWin = myGlobal - smallRect(2);
        mxWin = min(max(mxWin, 0), smallW-1);
        myWin = min(max(myWin, 0), smallH-1);

        targSmall = [mxWin; myWin];
        targBig   = [ (mxWin/(smallW-1))*(bigW-1);
                      (myWin/(smallH-1))*(bigH-1) ];

        % ---- Keys ----
        [kd,~,kc] = KbCheck;
        rDown = kd && kc(KEY.R);
        if kd
            if kc(KEY.ESC) || kc(KEY.X), break; end
            if rDown && ~rWasDown
                if enableReward && ~isempty(arduinoObj)
                    if ~rewardActive
                        writeDigitalPin(arduinoObj, rewardPin, activateArduino);
                    end
                    rewardActive = true;
                    rewardEndTime = GetSecs + rewardDuration;
                    fprintf('Manual reward started (%.2f s).\n', rewardDuration);
                else
                    disp('Manual reward requested, but Arduino is not active.');
                end
            end

            step = stepNormal;
            if (KEY.LSHFT>0 && kc(KEY.LSHFT)) || (KEY.RSHFT>0 && kc(KEY.RSHFT))
                step = stepBig;
            end
            if (KEY.LALT>0 && kc(KEY.LALT)) || (KEY.RALT>0 && kc(KEY.RALT))
                step = stepSmall;
            end

            % offsets
            if kc(KEY.A), ox = ox - step; end
            if kc(KEY.D), ox = ox + step; end
            if kc(KEY.W), oy = oy - step; end
            if kc(KEY.S), oy = oy + step; end

            % gains
            if kc(KEY.GX_DOWN), gx = gx * (1 - gainStep); end
            if kc(KEY.GX_UP),   gx = gx * (1 + gainStep); end

            if kc(KEY.GY_DOWN), gy = gy * (1 - gainStep); end
            if kc(KEY.GY_UP),   gy = gy * (1 + gainStep); end

            % flip toggles
            if kc(KEY.FLIPY)
                flipY = ~flipY; smoothXY = [NaN; NaN];
                WaitSecs(0.15);
            end
            if kc(KEY.FLIPX)
                flipX = ~flipX; smoothXY = [NaN; NaN];
                WaitSecs(0.15);
            end

            % reset
            if kc(KEY.RESET)
                gx = 1.00; gy = 1.00; ox = 0.0; oy = 0.0; flipX = true; flipY = true;
                smoothXY = [NaN; NaN];
                WaitSecs(0.15);
            end

            % save/load
            if kc(KEY.SAVE)
                try, save(paramFile, 'gx','gy','ox','oy','flipX','flipY'); catch, end
                WaitSecs(0.15);
            end
            if kc(KEY.LOAD)
                try
                    tmp = load(paramFile);
                    if isfield(tmp,'gx'), gx = tmp.gx; end
                    if isfield(tmp,'gy'), gy = tmp.gy; end
                    if isfield(tmp,'ox'), ox = tmp.ox; end
                    if isfield(tmp,'oy'), oy = tmp.oy; end
                    if isfield(tmp,'flipX'), flipX = tmp.flipX; end
                    if isfield(tmp,'flipY'), flipY = tmp.flipY; end
                    smoothXY = [NaN; NaN];
                catch
                end
                WaitSecs(0.15);
            end
        end
        rWasDown = rDown;

        if rewardActive && GetSecs >= rewardEndTime
            try
                writeDigitalPin(arduinoObj, rewardPin, ~activateArduino);
            catch
            end
            rewardActive = false;
        end

        % ---- Read EyeLink gaze ----
        rawGaze = [NaN; NaN];
        isValid = false;
        whichEye = 'None';

        if Eyelink('NewFloatSampleAvailable') > 0
            evt = Eyelink('NewestFloatSample');
            gxL = evt.gx(1); gyL = evt.gy(1);
            gxR = evt.gx(2); gyR = evt.gy(2);

            okL = gxL > -32000 && gyL > -32000;
            okR = gxR > -32000 && gyR > -32000;

            if okL
                rawGaze = [double(gxL); double(gyL)];
                whichEye = 'L';
                isValid = true;
            elseif okR
                rawGaze = [double(gxR); double(gyR)];
                whichEye = 'R';
                isValid = true;
            end
        end

        % ---- Apply mapping ----
        mapped = [NaN; NaN];
        outOfRange = false;

        if isValid
            mapped = applyGainOffsetFlipXY(rawGaze, gx, gy, ox, oy, flipX, flipY, bigW, bigH);

            outOfRange = mapped(1)<0 || mapped(1)>bigW-1 || mapped(2)<0 || mapped(2)>bigH-1;

            mapped(1) = min(max(mapped(1), 0), bigW-1);
            mapped(2) = min(max(mapped(2), 0), bigH-1);

            lastMapped = mapped;

            if any(isnan(smoothXY)), smoothXY = mapped; end
            smoothXY = alpha * mapped + (1-alpha) * smoothXY;
        else
            mapped = lastMapped;
        end

        % ---- Convert gaze to SMALL coords ----
        mappedSmall = [NaN;NaN];
        smoothSmall = [NaN;NaN];
        if ~any(isnan(mapped))
            mappedSmall(1) = mapped(1) * (smallW-1)/(bigW-1);
            mappedSmall(2) = mapped(2) * (smallH-1)/(bigH-1);
        end
        if ~any(isnan(smoothXY))
            smoothSmall(1) = smoothXY(1) * (smallW-1)/(bigW-1);
            smoothSmall(2) = smoothXY(2) * (smallH-1)/(bigH-1);
        end

        % ---- Logging ----
        if mod(frameCount, logEveryNFrames) == 0
            tSec = GetSecs;
            fprintf(fid, '%.6f,%.1f,%.1f,%.1f,%.1f,%.1f,%.1f,%.1f,%.1f,%d,%s,%.6f,%.6f,%.3f,%.3f,%d,%d\n', ...
                tSec, ...
                targBig(1), targBig(2), ...
                rawGaze(1), rawGaze(2), ...
                mapped(1), mapped(2), ...
                smoothXY(1), smoothXY(2), ...
                int32(isValid), whichEye, ...
                gx, gy, ox, oy, int32(flipX), int32(flipY));
        end

        % ================= DRAW BIG (subject): ONLY RED target =================
        Screen('FillRect', winBig, bgColor);
        if showCrossBig
            cx0 = bigW/2; cy0 = bigH/2;
            Screen('DrawLine', winBig, crossColor, cx0-40, cy0, cx0+40, cy0, 3);
            Screen('DrawLine', winBig, crossColor, cx0, cy0-40, cx0, cy0+40, 3);
        end
        Screen('DrawDots', winBig, targBig, targDotRadBig*2, targColor, [], 2);
        Screen('Flip', winBig);

        % ================= DRAW SMALL (operator) =================
        Screen('FillRect', winSmall, bgColor);
        if showCrossSmall
            cx0 = smallW/2; cy0 = smallH/2;
            Screen('DrawLine', winSmall, crossColor, cx0-25, cy0, cx0+25, cy0, 2);
            Screen('DrawLine', winSmall, crossColor, cx0, cy0-25, cx0, cy0+25, 2);
        end

        Screen('DrawDots', winSmall, targSmall, targDotRadSmall*2, targColor, [], 2);

        if ~any(isnan(mappedSmall))
            Screen('DrawDots', winSmall, mappedSmall, rawDotRadSmall*2, rawColor, [], 2);
        end
        if ~any(isnan(smoothSmall))
            Screen('DrawDots', winSmall, smoothSmall, smoothDotRadSmall*2, smoothColor, [], 2);
        end

        errPix = NaN;
        if ~any(isnan(smoothXY))
            errPix = norm(smoothXY - targBig);
        end

        s1 = sprintf('Target(BIG): (%.0f, %.0f) | err=%.1f px', targBig(1), targBig(2), errPix);
        if isValid
            s2 = sprintf('Eye(%s) raw: (%.0f, %.0f) | mapped: (%.0f, %.0f)', whichEye, rawGaze(1), rawGaze(2), mapped(1), mapped(2));
        else
            s2 = 'Eye: NaN (no valid sample)';
        end
        s3 = sprintf('gx=%.3f gy=%.3f  ox=%.0f oy=%.0f  flipX=%d flipY=%d', gx, gy, ox, oy, int32(flipX), int32(flipY));

        DrawFormattedText(winSmall, s1, 15, 15, txtColor);
        DrawFormattedText(winSmall, s2, 15, 40, txtColor);
        DrawFormattedText(winSmall, s3, 15, 65, txtColor);

        if outOfRange
            DrawFormattedText(winSmall, 'WARNING: mapped gaze was out-of-range (clipped)', 15, 92, warnColor);
        end

        help = 'WASD offset | O/P gx | K/L gy | F flipY | G flipX | BS reset | 1 save | 2 load | R reward | ESC/X quit';
        DrawFormattedText(winSmall, help, 15, smallH-30, txtColor);

        Screen('Flip', winSmall);
    end
    % Auto-save latest calibration params on exit
    try
        save(paramFile, 'gx','gy','ox','oy','flipX','flipY');
    catch
    end

catch ME
    if owns_windows
        try Eyelink('StopRecording'); catch, end
        try Eyelink('Shutdown'); catch, end
    end
    try fclose(fid); catch, end
    if ~isempty(arduinoObj)
        try writeDigitalPin(arduinoObj, rewardPin, ~activateArduino); catch, end
        try clear arduinoObj; catch, end
    end
    ListenChar(0);
    ShowCursor;
    if owns_windows
        sca;
    end
    % Auto-save latest params on error if possible
    try
        save(paramFile, 'gx','gy','ox','oy','flipX','flipY');
    catch
    end
    ok = false;
    rethrow(ME);
end

if owns_windows
    try Eyelink('StopRecording'); catch, end
    try Eyelink('Shutdown'); catch, end
end
try
    save(paramFile, 'gx','gy','ox','oy','flipX','flipY');
catch
end
try fclose(fid); catch, end
if ~isempty(arduinoObj)
    try writeDigitalPin(arduinoObj, rewardPin, ~activateArduino); catch, end
    try clear arduinoObj; catch, end
end
ListenChar(0);
ShowCursor;
if owns_windows
    sca;
end

fprintf('Closed. Log saved: %s\n', logName);
fprintf('Calibration exited. You can continue to the task.\n');
end

% ==================== Mapping function =====================
function mapped = applyGainOffsetFlipXY(rawGaze, gx, gy, ox, oy, flipX, flipY, W, H)
x = rawGaze(1);
y = rawGaze(2);

if flipX
    x = (W-1) - x;
end
if flipY
    y = (H-1) - y;
end

mapped = [ gx * x + ox;
           gy * y + oy ];
end

% ==================== Key helpers ==========================
function code = maybeKey(names)
code = 0;
for i = 1:numel(names)
    try
        c = KbName(names{i});
        if ~isempty(c) && isnumeric(c) && c > 0
            code = c; return;
        end
    catch
    end
end
end

function code = mustKey(names)
code = maybeKey(names);
if code == 0
    error('Could not resolve keycode for any of: %s', strjoin(names, ', '));
end
end

function paramFile = get_gain_offset_param_path()
    % Use a fixed path relative to the project root (where initalize.m lives).
    baseDir = fileparts(which('initalize'));
    if isempty(baseDir)
        baseDir = pwd;
    end
    calibDir = fullfile(baseDir, 'logs', 'calibration');
    if ~exist(calibDir, 'dir')
        mkdir(calibDir);
    end
    paramFile = fullfile(calibDir, 'gain_offset_params.mat');
end

function logPath = get_gaze_target_log_path(device_opt)
    baseDir = fileparts(which('initalize'));
    if isempty(baseDir)
        baseDir = pwd;
    end

    dateDir = fullfile(baseDir, 'logs', 'gaze_target', datestr(now, 'yyyy-mm-dd'));
    if ~exist(dateDir, 'dir')
        mkdir(dateDir);
    end

    prefix = get_log_prefix(device_opt);
    stamp = datestr(now, 'yyyymmdd_HHMMSS');
    if isempty(prefix)
        fileName = sprintf('gaze_target_log_%s.csv', stamp);
    else
        fileName = sprintf('%s_gaze_target_log_%s.csv', prefix, stamp);
    end
    logPath = fullfile(dateDir, fileName);
end

function prefix = get_log_prefix(device_opt)
    prefix = '';
    if isempty(device_opt) || ~isstruct(device_opt)
        return;
    end

    candidateFields = {'session_prefix', 'monkey_name', 'monkey', 'subject', 'id'};
    for i = 1:numel(candidateFields)
        fname = candidateFields{i};
        if isfield(device_opt, fname)
            value = device_opt.(fname);
            if isstring(value)
                value = char(value);
            end
            if ischar(value) && ~isempty(strtrim(value))
                prefix = regexprep(strtrim(value), '[^A-Za-z0-9_-]', '_');
                return;
            end
        end
    end
end
