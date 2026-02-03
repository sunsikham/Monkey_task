function playArea = makePlayableAreaPoly(Upper_Rect, bottom_Rect, ...
                                         CorridorsDraw, ...
                                         triMidL_coords, triMidR_coords, ...
                                         triLeftBlack_coords, triRightBlack_coords, ...
                                         avatar_r)
% -----------------------------------------------------------------------
% 반환:  polyshape 객체 (아바타 반경을 제외해 둔 Shrink 버전)
%        ⇒   isPlayable = isinterior(playArea, x, y) 로 바로 사용
% -----------------------------------------------------------------------

    % ── 1) 기본 허용 영역 -----------------------------------------------
    %    위 사각형 ∪ 아래 사각형 ∪ 두 통로 ∪ 흰 삼각형(2개)
    allow = polyshape();                    % 빈 집합

    allow = union(allow, rect2poly(Upper_Rect));
    allow = union(allow, rect2poly(bottom_Rect));

    for k = 1:2
        allow = union(allow, rect2poly(CorridorsDraw(:,k)));
    end

    allow = union(allow, polyshape(triMidL_coords,'Simplify',true));
    allow = union(allow, polyshape(triMidR_coords,'Simplify',true));

    % ── 2) 금지 영역(검정 삼각형) → 빼기 -------------------------------
    forbid = polyshape();                   % 역시 집합으로 관리
    forbid = union(forbid, polyshape(triLeftBlack_coords','Simplify',true));
    forbid = union(forbid, polyshape(triRightBlack_coords','Simplify',true));

    playArea = subtract(allow, forbid);
    playArea = polybuffer(playArea, -avatar_r);      % 'Simplify' 인자 제거
    playArea = simplify(playArea);      
end

% ─── 사각형 [L;T;R;B] → polyshape로 변환하는 헬퍼 ───
function pg = rect2poly(r)
    pg = polyshape([r(1) r(3) r(3) r(1)], [r(2) r(2) r(4) r(4)], ...
                   'Simplify',true);
end
