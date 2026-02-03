function [gx, gy, valid] = draw_live_gaze(visual_opt, eye_opt, varargin)
% draw_live_gaze
% Draws a live gaze cursor (dot) on the PTB window and returns gaze position.
%
% USAGE (minimal):
%   [gx,gy,ok] = draw_live_gaze(visual_opt, eye_opt);
%
% USAGE (custom):
%   [gx,gy,ok] = draw_live_gaze(visual_opt, eye_opt, 'radius', 6, 'color', [0 255 0]);
%   [gx,gy,ok] = draw_live_gaze(visual_opt, eye_opt, 'map_from', [w h], 'map_to', [w2 h2]);
%
% Inputs:
%   visual_opt.winPtr (or visual_opt.window) : PTB window pointer
%   eye_opt.eyelink_on : true/false
%   eye_opt.eye_side   : 1 (left) or 2 (right)
%
% Outputs:
%   gx, gy : gaze in pixel coordinates (NaN if invalid/off)
%   valid  : true if gaze sample valid

% ---- defaults ----
p = inputParser;
p.addParameter('radius', 6, @(x) isnumeric(x) && isscalar(x) && x > 0);
p.addParameter('color',  [0 255 0], @(x) isnumeric(x) && numel(x)==3);
p.addParameter('draw_when_invalid', false, @(x) islogical(x) && isscalar(x));
p.addParameter('map_from', [], @(x) isempty(x) || (isnumeric(x) && numel(x)==2));
p.addParameter('map_to',   [], @(x) isempty(x) || (isnumeric(x) && numel(x)==2));
p.parse(varargin{:});

dotR  = p.Results.radius;
dotCol = p.Results.color;
drawInvalid = p.Results.draw_when_invalid;
mapFrom = p.Results.map_from;
mapTo   = p.Results.map_to;

% ---- outputs ----
gx = NaN; gy = NaN; valid = false;

% ---- find PTB window ----
if isfield(visual_opt,'winPtr')
    win = visual_opt.winPtr;
elseif isfield(visual_opt,'window')
    win = visual_opt.window;
else
    return; % no window pointer
end

% ---- eyelink gate ----
if ~isfield(eye_opt,'eyelink_on') || ~eye_opt.eyelink_on
    return;
end
if ~isfield(eye_opt,'eye_side')
    eye_opt.eye_side = 1;
end

% ---- read newest sample ----
try
    if Eyelink('NewFloatSampleAvailable') <= 0
        return;
    end
    s  = Eyelink('NewestFloatSample');
    ix = eye_opt.eye_side;
    gx = s.gx(ix);
    gy = s.gy(ix);
catch
    return;
end

% validity check (typical)
if isfinite(gx) && isfinite(gy) && gx > 0 && gy > 0
    valid = true;
end

% ---- optional mapping to another window size ----
if valid && ~isempty(mapFrom) && ~isempty(mapTo)
    gx = gx * (mapTo(1)-1) / max(mapFrom(1)-1, 1);
    gy = gy * (mapTo(2)-1) / max(mapFrom(2)-1, 1);
end

% ---- draw ----
if valid || drawInvalid
    Screen('FillOval', win, dotCol, [gx-dotR gy-dotR gx+dotR gy+dotR]);
end
end
