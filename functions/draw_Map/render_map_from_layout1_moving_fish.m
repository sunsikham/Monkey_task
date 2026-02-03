function render_map_from_layout1_moving_fish(visual_opt, L)
% ======================================================================
%   새 맵 그리기 (○ 테두리, 회색 사각형, 삼각형 포함)
% ======================================================================
win = visual_opt.winPtr;
W   = visual_opt.wWth;
H   = visual_opt.wHgt;

%% ── ① 배경 + 이동 가능 영역 채우기 ──────────────────────────
Screen('FillRect', win, 0, [0 0 W H]);
    % --- 3. 이동 영역(위/아래 사각형, 통로)을 흰색으로 채움 ---
Screen('FillRect', win, [255 255 255], L.Upper_Rect);
Screen('FillRect', win, [255 255 255], L.Bottom_Rect);


%% ── ② 파란 테두리 프레임 ──────────────────────────────────
outColor = [0 96 128]/255; penW = 3;
drawUpperFrame(win, L.Upper_Rect,  L.CorridorsDraw, outColor, penW);
drawBottomFrame(win,L.Bottom_Rect, L.CorridorsDraw, outColor, penW);


%% ── ④ 통로 내부 “원 + 회색 사각형” ─────────────────────────
outlineClr = [0 0 0];  outlineW = 4;    % 원 테두리

switch L.GrayTrig
    case 0   % 두 원 모두 활성
        drawCircleWithRects(win, outlineClr, outlineW, L.Rect1, L.Rects1_coords);
        drawCircleWithRects(win, outlineClr, outlineW, L.Rect2, L.Rects2_coords);
       

    case 1   % 한 원만 활성
        if L.IsActive(1)
            drawCircleWithRects(win, outlineClr, outlineW, L.Rect1, L.Rects1_coords);
         
        end
        if L.IsActive(2)
            drawCircleWithRects(win, outlineClr, outlineW, L.Rect2, L.Rects2_coords);
         
           
        end
    % case 2: 둘 다 비활성 → 아무것도 안 그림
end
end
% ======================================================================
% ▼▼▼  보조 루틴  ▼▼▼
% ======================================================================
function drawCircleWithRects(win, clr, w, circRect, rects)
   % Screen('FillOval',  win, clr, circRect.');   % 내부 채우기
    Screen('FrameOval', win, clr, circRect.', w);% 테두리
    
end
function drawTris(win, color, verts3x2xK)
    K = size(verts3x2xK, 3);
    for k = 1:K
        Screen('FillPoly', win, color, verts3x2xK(:,:,k), 1);
        % 필요하면 테두리:
        % Screen('FramePoly', win, color, verts3x2xK(:,:,k), 1);
    end
end


function drawUpperFrame(win, upperRect, corridors_draw, color, penW)
    % top/left/right
    Screen('DrawLine', win, color, upperRect(1), upperRect(2), upperRect(3), upperRect(2), penW);
    Screen('DrawLine', win, color, upperRect(1), upperRect(2), upperRect(1), upperRect(4), penW);
    Screen('DrawLine', win, color, upperRect(3), upperRect(2), upperRect(3), upperRect(4), penW);

    % bottom line segmented (통로 구간 비움)
    yBottom = upperRect(4);
    xs = sortrows([corridors_draw(1,:)' corridors_draw(3,:)'],1); % [L R]
    currentX = upperRect(1);
    for i = 1:size(xs,1)
        cL = xs(i,1); cR = xs(i,2);
        if cL > currentX
            Screen('DrawLine', win, color, currentX, yBottom, cL, yBottom, penW);
        end
        currentX = cR;
    end
    if currentX < upperRect(3)
        Screen('DrawLine', win, color, currentX, yBottom, upperRect(3), yBottom, penW);
    end
end
%% ===== 아래 사각형 테두리 (top open segments) =====
function drawBottomFrame(win, bottomRect, corridors_draw, color, penW)
    % left/right/bottom
    Screen('DrawLine', win, color, bottomRect(1), bottomRect(2), bottomRect(1), bottomRect(4), penW);
    Screen('DrawLine', win, color, bottomRect(3), bottomRect(2), bottomRect(3), bottomRect(4), penW);
    Screen('DrawLine', win, color, bottomRect(1), bottomRect(4), bottomRect(3), bottomRect(4), penW);

    
end


%% ===== 통로 테두리 (top line 제거, bottom line도 제거하여 튀어나옴 숨김) =====
function drawCorridorSides(win, corridors_draw, color, penW)
    for k = 1:size(corridors_draw,2)
        r = corridors_draw(:,k);
        % left/right만 그립니다 (top/bottom 생략)
        Screen('DrawLine', win, color, r(1), r(2), r(1), r(4), penW);
        Screen('DrawLine', win, color, r(3), r(2), r(3), r(4), penW);
    end
end


