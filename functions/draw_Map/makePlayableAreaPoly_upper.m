function playArea = makePlayableAreaPoly_upper(Upper_Rect, avatar_r)
% ------------------------------------------------------------------------
% 상단 사각형만 허용하는 Playable Area 생성
%  - 허용 = Upper_Rect
%  - 금지 = 그 외 전부
%  - 아바타 반경만큼 Shrink
% ------------------------------------------------------------------------

    % 1) 허용 영역: Upper_Rect
    allow = rect2poly(Upper_Rect);

    % 2) Shrink by avatar radius
    playArea = polybuffer(allow, -avatar_r);

    % 3) 단순화
    playArea = simplify(playArea);
end

% ─── 헬퍼: [L;T;R;B] → polyshape ───
function pg = rect2poly(r)
    pg = polyshape( ...
           [r(1) r(3) r(3) r(1)], ...  % x coords
           [r(2) r(2) r(4) r(4)], ...  % y coords
           'Simplify', true);
end