function playArea = makePlayableAreaPoly_pursuit(Upper_Rect,avatar_r)
% ------------------------------------------------------------------------
% Pursuit 전용: 
%  - 허용 = 위 사각형 + 두 통로
%  - 금지 = 흰 삼각형(통로 사이) + 검정 삼각형(모서리)
%  - 아바타 반경만큼 축소
% ------------------------------------------------------------------------

    % 1) 허용 영역: 위 사각형
    allow = rect2poly(Upper_Rect);



    playArea = allow;
    playArea = polybuffer(playArea, -avatar_r);
    playArea = simplify(playArea);
end

% 헬퍼: [L;T;R;B] → polyshape
function pg = rect2poly(r)
    pg = polyshape([r(1) r(3) r(3) r(1)], ...
                   [r(2) r(2) r(4) r(4)], ...
                   'Simplify',true);
end