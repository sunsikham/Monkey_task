function render_map_from_layout1(visual_opt, L, tri_color)
% ======================================================================
%   새 맵 그리기 (○ 테두리, 삼각형 포함)
% ======================================================================
win = visual_opt.winPtr;
W   = visual_opt.wWth;
H   = visual_opt.wHgt;

%% ── ① 배경 + 이동 가능 영역 채우기 ──────────────────────────
Screen('FillRect', win, 0, [0 0 W H]);
% 이동 영역(위/아래 사각형, 통로)
Screen('FillRect', win, [255 255 255], L.Upper_Rect);
Screen('FillRect', win, [255 255 255], L.Bottom_Rect);



%% ── ④ 통로 내부 “원 + 회색 삼각형” ─────────────────────────
outlineClr = [0 0 0];  outlineW = 4;    % 원 테두리

switch L.GrayTrig
    case 0   % 두 원 모두 활성
        drawCircleWithTris(win, outlineClr, outlineW, L.Rect1, L.tri1_polys, tri_color);
        drawCircleWithTris(win, outlineClr, outlineW, L.Rect2, L.tri2_polys, tri_color);

    case 1   % 한 원만 활성
        if L.IsActive(1)
            drawCircleWithTris(win, outlineClr, outlineW, L.Rect1, L.tri1_polys, tri_color);
        end
        if L.IsActive(2)
            drawCircleWithTris(win, outlineClr, outlineW, L.Rect2, L.tri2_polys, tri_color);
        end
    % case 2: 둘 다 비활성 → 아무것도 안 그림
end
end

% ======================================================================
% ▼▼▼  보조 루틴  ▼▼▼
function drawCircleWithTris(win, clr, w, circRect, tri3x2xK, fillColor)
    % 원 테두리
    Screen('FrameOval', win, clr, circRect.', w);

    % 삼각형 정보가 비어 있으면 종료
    if isempty(tri3x2xK), return; end

    % 크기 확인
    sz = size(tri3x2xK);

    % =========================
    % 1) 삼각형이 1개인 경우: 3x2
    % =========================
    if numel(sz) == 2
        % 3x2인지 체크
        assert(sz(1) == 3 && sz(2) == 2, ...
            'Single triangle must be 3x2 (3 vertices x [x y]).');

        % 삼각형 1개만 그리기
        Screen('FillPoly', win, fillColor, tri3x2xK, 1);
        % 필요하면 외곽선:
        % Screen('FramePoly', win, fillColor, tri3x2xK, 1);
        return;
    end

    % =========================
    % 2) 삼각형이 여러 개인 경우: 3x2xK
    % =========================
    assert(sz(1) == 3 && sz(2) == 2 && ndims(tri3x2xK) == 3, ...
        'tri3x2xK must be a 3x2xK numeric array.');

    K = sz(3);
    for k = 1:K
        Screen('FillPoly', win, fillColor, tri3x2xK(:,:,k), 1);
        % 필요하면 외곽선:
        % Screen('FramePoly', win, fillColor, tri3x2xK(:,:,k), 1);
    end
end

