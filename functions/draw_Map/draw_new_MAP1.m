function [bottom_Rect, Upper_Rect, Corridors, CorridorsDraw, ...
          rect1_coords, rect2_coords, color1, color2, is_active, ...
          rects1_coords,...
          rects2_coords, tri1_polys,tri2_polys] = draw_new_MAP1(visual_opt,game_opt,data,n_rects)

    win   = visual_opt.winPtr;
    W     = visual_opt.wWth;
    H     = visual_opt.wHgt;
    avatar_r       = game_opt.avatar_sz/2;

    outlineColor   = [0 96 128] / 255; %#ok<NASGU>
    outlineWidthPx = 3;                %#ok<NASGU>

    % --- 0. 전체 배경을 검은색으로 채움 ---
    Screen('FillRect', win, [0 0 0], [0 0 W H]);

    % --- 1. 위쪽 사각형/아래 사각형 기본 좌표 ---
    [Upper_Rect, mapBottomY] = baseUpperRect(W,H);
    [bottom_Rect, boxTopY]   = baseBottomRect(W,H);

    % --- 2. 통로 (그리기용 좌표: corridors_draw / 충돌용 좌표: Corridors) ---
    [corridors_draw, Corridors] = buildCorridors(Upper_Rect, bottom_Rect, mapBottomY, boxTopY, avatar_r);
    [CorridorsDraw, Corridors] = alignCorridorsToBottomEdges(corridors_draw, Corridors, bottom_Rect);

    % --- 3. 이동 영역(위/아래 사각형)을 흰색으로 채움 ---
    Screen('FillRect', win, [255 255 255], Upper_Rect);
    Screen('FillRect', win, [255 255 255], bottom_Rect);
    % 통로를 흰색으로 채우고 싶으면 다음 줄 주석 해제
    % Screen('FillRect', win, [255 255 255], CorridorsDraw);

    % --- 4. 통로 위의 원/삼각형 그리기 ---
    [rect1_coords, rect2_coords, ...
     rects1_coords, rects2_coords, ...
     color1, color2, is_active, tri1_polys, tri2_polys] = ...
        draw_Corridor_Shapes(visual_opt, CorridorsDraw, bottom_Rect, ...
                             data.gray_triger, ...
                             0, n_rects);

    % tri_ratio 등은 이후에 사용할 여지를 남겨둔 상태
    tri_ratio = 0.20; %#ok<NASGU>
    base  = (bottom_Rect(3)-bottom_Rect(1))*tri_ratio; %#ok<NASGU>
    hght  = base; %#ok<NASGU>

end

%% ===== 기본 위/아래 사각형 좌표 함수 =====
function [rect, yBottom] = baseUpperRect(W,H)
    width  = W * 0.70;
    height = H * 0.40;
    left   = (W - width)/2;
    top    = H * 0.05;
    rect   = [left, top, left+width, top+height];
    yBottom = rect(4);
end

function [rect, yTop] = baseBottomRect(W,H)
    width  = W * 0.70;
    height = H * 0.20;
    left   = (W - width)/2;
    bottom = H;
    rect   = [left, bottom-height, left+width, bottom];
    yTop   = rect(2);
end

%% ===== 통로 좌표 생성 (그리기용/충돌용) =====
function [corridors_draw, corridors_collision] = ...
         buildCorridors(Upper_Rect, bottom_Rect, mapBottomY, boxTopY, avatar_r) %#ok<INUSD>

    numCorr  = 2;                                  % 통로 2개
    boxLeft  = bottom_Rect(1);
    boxWidth = bottom_Rect(3) - bottom_Rect(1);

    corrW = 1.0 * boxWidth / (numCorr*1.9 + 1);    % 원하는 비율로 폭 결정
    gapW  = (boxWidth - numCorr*corrW) / (numCorr+1);

    corridors_draw      = zeros(4,numCorr);
    corridors_collision = zeros(4,numCorr);

    for k = 1:numCorr
        left  = boxLeft + gapW*k + corrW*(k-1);    % gap + (gap+corr) 누적
        right = left + corrW;

        corridors_draw(:,k) = [left; mapBottomY; right; boxTopY];
        corridors_collision(:,k) = ...
            [left; mapBottomY-avatar_r; right; boxTopY+avatar_r];
    end
end



function [rect1_coords, rect2_coords, ...
          rects1_coords, rects2_coords, ...
          color1, color2, is_active, tri1_polys, tri2_polys] = ...
    draw_Corridor_Shapes(vOpt, CorridorsDraw, bottom_Rect, ...
                         gray_triger, ...
                         side_gray1, nRects)
% -------------------------------------------------------------------------
% vOpt.winPtr      : Psychtoolbox window pointer
% CorridorsDraw    : 4×2 matrix, 각 통로(좌/우) 바운딩박스 [x1;y1;x2;y2]
% bottom_Rect      : 아래 사각형 [x1;y1;x2;y2]
% gray_triger      : 0 = 두 원 모두, 1 = 한 원만 활성, 2 = 모두 비활성
% side_gray1       : gray_triger==1 일 때 0=랜덤, 1=왼쪽, 2=오른쪽
% nRects           : 삼각형 개수 지정
%                    • 스칼라 N        → 좌우 모두 N개
%                    • 벡터 [nL nR]   → (gray=0) nL·nR 값을 사용
% -------------------------------------------------------------------------
% 반환:
%  rect1_coords, rect2_coords   : 좌/우 원의 bounding rect (4×1)
%  rects1_coords, rects2_coords : 좌/우 삼각형 바운딩 박스들 (4×K)
%  color1, color2               : 원 테두리 색
%  is_active                    : [왼쪽, 오른쪽] 활성 여부 (논리값)
%  tri1_polys, tri2_polys       : 좌/우 삼각형 꼭짓점들 (3×2×K)
% -------------------------------------------------------------------------

%% ── 기본 인수 처리 ───────────────────────────────────────────
if nargin < 4 || isempty(gray_triger),  gray_triger = 0;  end
if nargin < 5 || isempty(side_gray1),   side_gray1  = 0;  end

if isscalar(nRects), nRects = [nRects nRects]; end   % [nL nR]

GREY     = [128 128 128];
OUTLINE  = [128 128 128];
PEN_W    = 4;                     % 원 테두리 두께
MAXTRY   = 100; %#ok<NASGU>       % (현재 미사용) 사각형 배치 최대 시도 횟수

%% ── 원 바운딩 박스 계산 : bottom_Rect 기준 ─────────────────
% bottom_Rect의 높이를 지름으로 사용
bottom_height = bottom_Rect(4) - bottom_Rect(2);
diam = bottom_height;
rad  = diam/2;

% y 중심은 bottom_Rect의 세로 중앙
yC = (bottom_Rect(2) + bottom_Rect(4)) / 2;

% x 중심은 여전히 각 통로의 가로 중앙을 사용
xL  = mean(CorridorsDraw([1 3],1));
xR  = mean(CorridorsDraw([1 3],2));

rect1_coords = [xL-rad, yC-rad, xL+rad, yC+rad]';
rect2_coords = [xR-rad, yC-rad, xR+rad, yC+rad]';

%% ── 삼각형 개수 결정 (gray_triger별) ───────────────────────
switch gray_triger
    case 0   % 두 원 모두
        nL = nRects(1); 
        nR = nRects(2);

    case 1   % 한 원만
        pool    = nRects(:).';                 % [2 4] 같은 풀
        kChosen = pool( 1+floor(rand*numel(pool)) );  % randi 대체
        side    = side_gray1; 
        if side==0
            side = 1+floor(rand*2);
        end
        if side==1
            nL=kChosen; nR=0; 
        else
            nL=0; nR=kChosen; 
        end

    otherwise  % gray_triger==2 → 둘 다 비활성
        nL = 0; nR = 0;
end

%% ── 삼각형 좌표 생성 ───────────────────────────────────────
[tri1_polys, rects1_coords] = local_makeTris_fixed(xL, yC, rad, nL);
[tri2_polys, rects2_coords] = local_makeTris_fixed(xR, yC, rad, nR);

%% ── 화면 그리기 ─────────────────────────────────────────────

switch gray_triger
    case 0  % 두 원 + (회색) 삼각형
        Screen('FrameOval', vOpt.winPtr, OUTLINE, rect1_coords, PEN_W);
        Screen('FrameOval', vOpt.winPtr, OUTLINE, rect2_coords, PEN_W);
        drawTris(vOpt.winPtr, GREY, tri1_polys);
        drawTris(vOpt.winPtr, GREY, tri2_polys);
        is_active = [true true];

    case 1  % 한 원만
        if ~isempty(tri1_polys)  % 왼쪽 활성
            Screen('FrameOval', vOpt.winPtr, OUTLINE, rect1_coords, PEN_W);
            drawTris(vOpt.winPtr, GREY, tri1_polys);
            is_active = [true false];
        else                     % 오른쪽 활성
            Screen('FrameOval', vOpt.winPtr, OUTLINE, rect2_coords, PEN_W);
            drawTris(vOpt.winPtr, GREY, tri2_polys);
            is_active = [false true];
        end

    otherwise % gray_triger==2
        is_active = [false false];
end

%% ── 반환용 색상 (호환) ───────────────────────────────────────
color1 = OUTLINE;   color2 = OUTLINE;
end  % ==== end draw_Corridor_Shapes ===========================

% ========================================================================
% ▼▼▼  보조 함수들  ▼▼▼
% ========================================================================
function [verts3x2xK, bbox4xK] = local_makeTris_fixed(cx, cy, rad, N)
% 출력
%   verts3x2xK : (3×2×K) 각 삼각형 꼭짓점 [x y] 3개를 한 장씩
%   bbox4xK    : (4×K)   각 삼각형 바운딩 박스 [minX; minY; maxX; maxY]

    if N <= 0
        verts3x2xK = zeros(3,2,0);
        bbox4xK    = zeros(4,0);
        return;
    end

    angle = deg2rad((0:7) * 45);    % 7개 고정 각도
    rPos  = 0.6 * rad;
    Cxy   = [cx + rPos*cos(angle);   % 2×7
             cy + rPos*sin(angle)];

    K     = min(N, numel(angle));
    pick  = randperm(numel(angle), K);

    side_len = 0.5 * rad;          % 정삼각형 한 변 길이
    R        = side_len / sqrt(3);  % 무게중심→꼭짓점 거리
    theta0s  = -pi/2 + (rand(1,K)-0.5) * (pi/6);  % 약간 랜덤 회전(±15°)

    verts3x2xK = zeros(3,2,K);
    bbox4xK    = zeros(4,K);

    for i = 1:K
        c  = Cxy(:, pick(i));
        t0 = theta0s(i);
        vs = [ c(1)+R*cos(t0),               c(2)+R*sin(t0);
               c(1)+R*cos(t0+2*pi/3),       c(2)+R*sin(t0+2*pi/3);
               c(1)+R*cos(t0+4*pi/3),       c(2)+R*sin(t0+4*pi/3) ];

        verts3x2xK(:,:,i) = vs;

        xs = vs(:,1); ys = vs(:,2);
        bbox4xK(:,i) = [min(xs); min(ys); max(xs); max(ys)];
    end
end

function drawTris(win, color, verts3x2xK)
    K = size(verts3x2xK, 3);
    for k = 1:K
        Screen('FillPoly', win, color, verts3x2xK(:,:,k), 1);
        % 필요하면 테두리:
        % Screen('FramePoly', win, color, verts3x2xK(:,:,k), 1);
    end
end



function [CorridorsDraw, Corridors] = alignCorridorsToBottomEdges(CorridorsDraw, Corridors, bottom_Rect)
    % 현재 통로 폭과 y범위 유지
    cw   = CorridorsDraw(3,1) - CorridorsDraw(1,1);     % corridor width
    y1D  = CorridorsDraw(2,1);  y2D = CorridorsDraw(4,1);
    y1C  = Corridors(2,1);      y2C = Corridors(4,1);

    % 아래 사각형 좌우 경계
    bL = bottom_Rect(1);
    bR = bottom_Rect(3);
    bW = bR - bL; %#ok<NASGU>

    % 안전장치: 통로 폭이 아래 사각형 폭을 넘지 않도록
    cw = min(cw, bW);

    % ── 왼쪽 통로: 아래 사각형의 왼쪽 변에 정렬
    CorridorsDraw(:,1) = [bL;       y1D; bL+cw;   y2D];
    Corridors(:,1)     = [bL;       y1C; bL+cw;   y2C];

    % ── 오른쪽 통로: 아래 사각형의 오른쪽 변에 정렬
    CorridorsDraw(:,2) = [bR-cw;    y1D; bR;      y2D];
    Corridors(:,2)     = [bR-cw;    y1C; bR;      y2C];

    % (선택) 픽셀 정렬이 필요하면 round() 추가:
    CorridorsDraw = round(CorridorsDraw);
    Corridors     = round(Corridors);
end

function bottomUsable = make_new_bottom_rect_coords(bottom_Rect, tri_ratio)
    if nargin<2, tri_ratio = 0.25; end
    base   = (bottom_Rect(3)-bottom_Rect(1))*tri_ratio;
    h      = base;                          % 동일 빗변

    bottomUsable = [ ...
        bottom_Rect(1)+base, bottom_Rect(2);               % 좌상
        bottom_Rect(3)-base, bottom_Rect(2);               % 우상
        bottom_Rect(3),       bottom_Rect(4)-h;            % 우하
        bottom_Rect(1),       bottom_Rect(4)-h ]';         % 좌하
end


function [triL, triR, trap] = buildGapTriangles( ...
        CorridorsDraw, bottom_Rect, height_ratio, base_gap, trap_h)
% buildGapTriangles   V자 흰 삼각형 + 중앙 사다리꼴
%   height_ratio : 삼각형 높이 비율 (0–1), 기본 0.25
%   base_gap     : 두 삼각형 밑변 사이 간격(px), 기본 0
%   trap_h       : 사다리꼴 높이(px), 기본 10
%   반환:
%       triL, triR : 3×2  (왼/오 삼각형 꼭짓점)
%       trap       : 4×2  (사다리꼴 꼭짓점 시계방향)

    if nargin<3, height_ratio = 0.25; end
    if nargin<4, base_gap     = 0;    end
    if nargin<5, trap_h       = 10;   end

    % ── 0) 공통 좌표 계산 ─────────────────────────────────────
    xL  = CorridorsDraw(3,1);          % 왼쪽 통로 우 X
    xR  = CorridorsDraw(1,2);          % 오른쪽 통로 좌 X
    y0  = bottom_Rect(2);              % 밑변 Y
    yH  = (CorridorsDraw(4,1)-CorridorsDraw(2,1))*height_ratio;
    yApex = y0 - yH;

    xMid  = (xL + xR)/2;
    halfG = base_gap/2;
    xMidL = xMid - halfG;
    xMidR = xMid + halfG;

    % ── 1) 삼각형 좌표 ───────────────────────────────────────
    triL = [ xL     , y0;
             xL     , yApex;
             xMidL  , y0 ];

    triR = [ xR     , y0;
             xR     , yApex;
             xMidR  , y0 ];

    % ── 2) 중앙 사다리꼴 좌표 ────────────────────────────────
    yTop = y0 - trap_h;                % 윗변 Y = 밑변보다 trap_h 위
    trap = [ xMidL , y0;               % BL
             xMidR , y0;               % BR
             xR    , yTop;             % TR
             xL    , yTop ];           % TL
end
