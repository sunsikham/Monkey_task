function draw_tri(tri, color, winPtr)
    % tri : 3x2 또는 3x2xK 형태의 삼각형 좌표
    % color : [R G B]
    % winPtr : Psychtoolbox window pointer

    if isempty(tri)
        return;
    end

    sz = size(tri);

    % ---- 2D(3x2)로 들어온 경우: 3x2x1로 확장 ----
    if numel(sz) == 2          % 예: [3 2]
        if sz(1) ~= 3 || sz(2) ~= 2
            % 크기 이상할 때는 그냥 그리지 않고 경고만
            warning('draw_tri:badSize2D', ...
                'tri size is [%d %d], expected 3x2 or 3x2xK. Skipping.', sz(1), sz(2));
            return;
        end
        tri = reshape(tri, 3, 2, 1);

    % ---- 3D 이상으로 들어온 경우: 앞 두 차원만 체크 ----
    else                       % 예: [3 2 K], [3 2 K 1] 등
        if sz(1) ~= 3 || sz(2) ~= 2
            warning('draw_tri:badSizeND', ...
                'tri size is [%s], expected 3x2xK. Skipping.', ...
                sprintf('%d ', sz));
            return;
        end
        % 3x2xK 이면 그대로 사용
        % 3x2xKx1 이런 경우도 size(tri,3)만 쓰면 K는 정상적으로 잡힙니다.
    end

    % ---- 여기까지 왔으면 tri는 최소 3x2x1 보장 ----
    K = size(tri, 3);
    for k = 1:K
        % 각 삼각형의 3개 꼭짓점 (3x2)
        poly = tri(:,:,k);
        Screen('FillPoly', winPtr, color, poly, 1);
        % 필요시 테두리:
        % Screen('FramePoly', winPtr, [0 0 0], poly, 1);
    end
end
