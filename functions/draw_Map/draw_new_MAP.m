function [bottom_Rect,Upper_Rect,Corridors,CorridorsDraw, ...
          rect1_coords, rect2_coords, color1, color2, is_active] = draw_new_MAP(visual_opt,game_opt,data)

    win   = visual_opt.winPtr;
    W     = visual_opt.wWth;
    H     = visual_opt.wHgt;
    avatar_r       = game_opt.avatar_sz/2;

    outlineColor   = [0 96 128] / 255;
    outlineWidthPx = 3;

    % --- 0. 전체 배경을 검은색으로 채움 ---
    Screen('FillRect', win, [0 0 0], [0 0 W H]);

    % --- 1. 위쪽 사각형/아래 사각형 기본 좌표 ---
    [Upper_Rect, mapBottomY] = baseUpperRect(W,H);
    [bottom_Rect, boxTopY]   = baseBottomRect(W,H);

    % --- 2. 통로 (그리기용 좌표: corridors_draw / 충돌용 좌표: Corridors) ---
    [corridors_draw, Corridors] = buildCorridors(Upper_Rect, bottom_Rect, mapBottomY, boxTopY, avatar_r);
    [CorridorsDraw, Corridors] = alignCorridorsToBottomEdges(corridors_draw, Corridors, bottom_Rect);

    % --- 3. 이동 영역(위/아래 사각형, 통로)을 흰색으로 채움 ---
    Screen('FillRect', win, [255 255 255], Upper_Rect);
    Screen('FillRect', win, [255 255 255], bottom_Rect);
    Screen('FillRect', win, [255 255 255], CorridorsDraw);

    % --- 4. 테두리 (열린 변 처리) ---
    drawUpperFrame(win, Upper_Rect, CorridorsDraw, outlineColor, outlineWidthPx);
    drawBottomFrame(win, bottom_Rect, CorridorsDraw, outlineColor, outlineWidthPx);
    drawCorridorSides(win, CorridorsDraw, outlineColor, outlineWidthPx);

    % --- 5. 도형(삼각형/사각형) : 그리기용 통로좌표 사용 ---
  
   
% 통로·도형 그릴 때 플래그 전달
    
    [rect1_coords, rect2_coords, color1, color2,is_active] = ...
         draw_Corridor_Shapes(visual_opt, CorridorsDraw, data.swap_shapes,data.gray_triger);

   
end

%% ===== 기본 위/아래 사각형 좌표 함수 =====
function [rect, yBottom] = baseUpperRect(W,H)
    width  = W * 0.70;
    height = H * 0.30;
    left   = (W - width)/2;
    top    = H * 0.05;
    rect   = [left, top, left+width, top+height];
    yBottom = rect(4);
end
function [rect, yTop] = baseBottomRect(W,H)
    width  = W * 0.40;
    height = H * 0.10;
    left   = (W - width)/2;
    bottom = H * 0.95;
    rect   = [left, bottom-height, left+width, bottom];
    yTop   = rect(2);
end

%% ===== 통로 좌표 생성 (그리기용/충돌용) =====
function [corridors_draw, corridors_collision] = ...
         buildCorridors(Upper_Rect, bottom_Rect, mapBottomY, boxTopY, avatar_r)

    numCorr  = 2;                                  % 통로 2개
    boxLeft  = bottom_Rect(1);
    boxWidth = bottom_Rect(3) - bottom_Rect(1);

    corrW = 1.0 * boxWidth / (numCorr*1.6 + 1);    % 원하는 비율(예 0.6)로 폭 결정
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


%% ===== 위 사각형 테두리 (bottom open segments) =====
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

    % top line segmented (통로 구간 비움)
    yTop = bottomRect(2);
    xs = sortrows([corridors_draw(1,:)' corridors_draw(3,:)'],1);
    currentX = bottomRect(1);
    for i = 1:size(xs,1)
        cL = xs(i,1); cR = xs(i,2);
        if cL > currentX
            Screen('DrawLine', win, color, currentX, yTop, cL, yTop, penW);
        end
        currentX = cR;
    end
    if currentX < bottomRect(3)
        Screen('DrawLine', win, color, currentX, yTop, bottomRect(3), yTop, penW);
    end
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

function [rect1_coords, rect2_coords, color1, color2, is_active] = ...
         draw_Corridor_Shapes(vOpt, CorridorsDraw, swap_shapes, gray_triger, side_gray1, draw_one_on_gray1)

    % --- 기본값 ---
    if nargin < 4 || isempty(gray_triger),     gray_triger     = 0; end
    if nargin < 5 || isempty(side_gray1),      side_gray1      = 0; end  % 0=random, 1=left, 2=right
    if nargin < 6 || isempty(draw_one_on_gray1), draw_one_on_gray1 = true; end

    COLORS = [255 0 0; 0 255 0; 0 0 255];
    GREY   = [128 128 128];

    % 기본 두 색(보이는 모드에서만 사용)
    idx    = randperm(3,2);
    colorL = COLORS(idx(1),:);
    colorR = COLORS(idx(2),:);

    % swap_shapes면 좌우 색 바꿈(필요시)
    if swap_shapes
        tmp = colorL; colorL = colorR; colorR = tmp;
    end

    % ── 기하 계산: 좌표는 항상 반환 ──────────────────────────────
    corridor_width = CorridorsDraw(3,1) - CorridorsDraw(1,1);
    shape_w = corridor_width * 0.9;
    shape_h = shape_w * 1;

    y_center = mean(CorridorsDraw([2 4],1));
    L_rect   = CorridorsDraw(:,1);
    R_rect   = CorridorsDraw(:,2);
    xL = mean(L_rect([1 3]));
    xR = mean(R_rect([1 3]));

    rect1_coords = [xL-shape_w/2; y_center-shape_h/2; xL+shape_w/2; y_center+shape_h/2];
    rect2_coords = [xR-shape_w/2; y_center-shape_h/2; xR+shape_w/2; y_center+shape_h/2];

    % 기본 반환값(수정 예정)
    color1 = colorL; 
    color2 = colorR;
    is_active = [false false];

    % ── 동작 모드 ───────────────────────────────────────────────
    switch gray_triger
        case 0
            % 보임: 두 도형 그림, 두 영역 활성
            Screen('FillRect', vOpt.winPtr, color1, rect1_coords.');
            Screen('FillRect', vOpt.winPtr, color2, rect2_coords.');
            is_active = [true true];

        case 1
            % 숨김: 한쪽만 유효
            % 어떤 쪽을 유효로 할지 결정
            if side_gray1 == 0, side = randi(2); else, side = side_gray1; end
            if swap_shapes, side = 3 - side; end     % 좌우 토글(원치 않으면 제거)

            is_active = [side==1, side==2];
            
            if draw_one_on_gray1
                % (옵션) 한쪽만 그리기: 세 가지 색 중 하나로
                if rand() < 0.7
                    oneColor = COLORS(1,:);
                else
                    oneColor = COLORS(2,:);
                end
                if side == 1
                    Screen('FillRect', vOpt.winPtr, oneColor, rect1_coords.');
                    color1 = oneColor;     % 그려진 쪽의 색
                    color2 = GREY;         % 안 그린 쪽은 그레이로 반환
                else
                    Screen('FillRect', vOpt.winPtr, oneColor, rect2_coords.');
                    color1 = GREY;
                    color2 = oneColor;
                end
                
            else
                % 아무 것도 그리지 않음: 두 색 모두 그레이로 반환
                color1 = GREY;
                color2 = GREY;
            end

        case 2
            % 숨김: 두쪽 모두 비유효, 그림 없음, 색은 그레이 반환
            is_active = [false false];
            color1 = GREY;
            color2 = GREY;

        otherwise
            error('gray_triger must be 0, 1, or 2.');
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
    bW = bR - bL;

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

