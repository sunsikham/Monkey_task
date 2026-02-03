function Upper_Rect= draw_new_MAP_pursuit(visual_opt,game_opt,check,data,L)

    win   = visual_opt.winPtr;
    W     = visual_opt.wWth;
    H     = visual_opt.wHgt;
    avatar_r       = game_opt.avatar_sz/2;

  
    % --- 0. 전체 배경을 검은색으로 채움 ---
    Screen('FillRect', win, [0 0 0], [0 0 W H]);

    % --- 1. 위쪽 사각형/아래 사각형 기본 좌표 ---
    [Upper_Rect, mapBottomY] = baseUpperRect(W,H);
    [bottom_Rect, boxTopY]   = baseBottomRect(W,H);

    % --- 2. 통로 (그리기용 좌표: corridors_draw / 충돌용 좌표: Corridors) ---
    [corridors_draw, Corridors] = buildCorridors(Upper_Rect, bottom_Rect, mapBottomY, boxTopY, avatar_r);
  

    % --- 3. 이동 영역(위/아래 사각형, 통로)을 흰색으로 채움 ---
    Screen('FillRect', win, [255 255 255], L.Upper_Rect);
    Screen('FillRect', win, [255 255 255], L.Bottom_Rect);
 


     draw_Corridor_Shapes_pursuit(visual_opt, corridors_draw,check,data);


    outlineClr = [0 0 0];  outlineW = 4;    % 원 테두리
% 하단 모서리 검정 삼각
    drawCircleWithRects(win, outlineClr, outlineW, L.Rect1);
    drawCircleWithRects(win, outlineClr, outlineW, L.Rect2);
    %drawTris(win, [128 0 128], unuseTri)
end

%% ===== 기본 위/아래 사각형 좌표 함수 =====
function [rect, yBottom] = baseUpperRect(W,H)
    width  = W * 0.60;
    height = H * 0.30;
    left   = (W - width)/2;
    top    = H * 0.05;
    rect   = [left, top, left+width, top+height];
    yBottom = rect(4);
end
function [rect, yTop] = baseBottomRect(W,H)
    width  = W * 0.40;
    height = H * 0.08;
    left   = (W - width)/2;
    bottom = H * 0.90;
    rect   = [left, bottom-height, left+width, bottom];
    yTop   = rect(2);
end

%% ===== 통로 좌표 생성 (그리기용/충돌용) =====
function [corridors_draw, corridors_collision] = ...
         buildCorridors(Upper_Rect, bottom_Rect, mapBottomY, boxTopY, avatar_r)

    numCorr  = 2;                                  % 통로 2개
    boxLeft  = bottom_Rect(1);
    boxWidth = bottom_Rect(3) - bottom_Rect(1);

    corrW = 1.0 * boxWidth / (numCorr*1.9 + 1);    % 원하는 비율(예 0.6)로 폭 결정
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




function [triangle_coords, hex_coords] = draw_Corridor_Shapes_pursuit (vOpt, CorridorsDraw,chosen_shape,data)
% CorridorsDraw : 4×3  [L;T;R;B] (그리기용 통로 rects)
% swap_shapes   : true  → 삼각형(왼→오른쪽)·사각형(오른→왼쪽) 위치 교환
% chosen_shape  : 1(세모 선택) / 2(네모 선택)  → 선택된 도형은 숨김

    % 색상
    TRI_COLOR = [  0 255   0];  % 초록
    HEX_COLOR = [255 0 0];

    % 크기 계산
    corridor_width = CorridorsDraw(3,1) - CorridorsDraw(1,1);
    shape_size     = corridor_width * 0.8;
    y_center       = mean(CorridorsDraw([2 4],1));

    % 좌/우 인덱스 결정
    if data.swap_shapes
        idx_tri = 2;  % 삼각형 오른쪽
        idx_hex  = 1;  % 사각형 왼쪽
    else
        idx_tri = 1;  % 삼각형 왼쪽
        idx_hex = 2;  % 사각형 오른쪽
    end

    %% ── 삼각형 좌표 ────────────────────────────
    tri_rect = CorridorsDraw(:, idx_tri);
    x_tri    = mean(tri_rect([1 3]));
    p1 = [x_tri,               y_center - 0.5*shape_size];
    p2 = [x_tri - 0.5*shape_size, y_center + 0.5*shape_size];
    p3 = [x_tri + 0.5*shape_size, y_center + 0.5*shape_size];
    tri_xy = [p1; p2; p3];
    triangle_coords = tri_xy.';   % 2×3 반환

    %% ── 사각형 좌표 ────────────────────────────
    hex_rect = CorridorsDraw(:, idx_hex);
    x_hex    = mean(hex_rect([1 3]));
    r        = shape_size/2;               % 육각형 외접반지름
    angles   = (0:5)*(pi/3);               % 0,60,…300 [rad]
    hex_xy   = [x_hex + r*cos(angles)', ...
                y_center + r*sin(angles)'];
    hex_coords = hex_xy.';       

    %% ── 그리기 (선택되지 않은 도형만) ───────────
   % % if chosen_shape ~= 1  % 삼각형이 "보여야” 하는 경우
   % %     Screen('FillPoly', vOpt.winPtr, TRI_COLOR, tri_xy, 1);
   % % end
   % % if chosen_shape ~= 2  % 사각형이 "보여야” 하는 경우
   %      Screen('FillPoly', vOpt.winPtr, HEX_COLOR, hex_xy, 1);
   %end
end



function drawCircleWithRects(win, clr, w, circRect)
   % Screen('FillOval',  win, clr, circRect.');   % 내부 채우기
    Screen('FrameOval', win, clr, circRect.', w);% 테두리
    
end
