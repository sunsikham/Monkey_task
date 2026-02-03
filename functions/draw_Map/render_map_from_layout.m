function render_map_from_layout(visual_opt, L)
    win = visual_opt.winPtr;
    W   = visual_opt.wWth; 
    H   = visual_opt.wHgt;

    outlineColor   = [0 96 128] / 255;
    outlineWidthPx = 3;

    % 배경 + 이동영역
    Screen('FillRect', win, [0 0 0], [0 0 W H]);
    Screen('FillRect', win, [255 255 255], L.Upper_Rect);
    Screen('FillRect', win, [255 255 255], L.Bottom_Rect);
    Screen('FillRect', win, [255 255 255], L.CorridorsDraw);

    % 프레임
    drawUpperFrame(win,  L.Upper_Rect,  L.CorridorsDraw, outlineColor, outlineWidthPx);
    drawBottomFrame(win, L.Bottom_Rect, L.CorridorsDraw, outlineColor, outlineWidthPx);
    drawCorridorSides(win, L.CorridorsDraw, outlineColor, outlineWidthPx);

    % 도형(보이는 경우만)
    if L.GrayTrig == 0
        if L.DrawMask(1), Screen('FillRect', win, L.Color1, L.Rect1.'); end
        if L.DrawMask(2), Screen('FillRect', win, L.Color2, L.Rect2.'); end
    elseif L.GrayTrig == 1
        % 정책에 따라: 보이지 않게 유지(기본) → 아무 것도 안 그림
        % 만약 한쪽만 보이게 하고 싶으면 L.DrawMask를 [true,false]/[false,true]로 만들어 두고 위와 동일 처리
        if any(L.DrawMask)
            if L.DrawMask(1), Screen('FillRect', win, L.Color1, L.Rect1.'); end
            if L.DrawMask(2), Screen('FillRect', win, L.Color2, L.Rect2.'); end
        end
    end
    % GrayTrig==2: 아무 도형도 그리지 않음
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
