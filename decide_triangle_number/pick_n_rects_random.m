function [n_rects, state] = pick_n_rects_random(base_pair, max_consecutive, state)
% pick_n_rects_random
%   - base_pair       : [작은값 큰값] (예: [2 5])
%   - max_consecutive : 한 방향 정답이 최대 몇 번까지 연속될 수 있는지 (예: 3)
%   - state           : 상태 유지 구조체

    % ---------- 0) 초기화 ----------
    if nargin < 3 || isempty(state)
        state = struct();
    end

    % consecutive_count: 같은 방향이 몇 번 연속되었는지
    if ~isfield(state, 'consecutive_count')
        state.consecutive_count = 0;
    end
    
    % last_side: 직전 정답 위치 (-1: 왼쪽, +1: 오른쪽)
    if ~isfield(state, 'last_side')
        state.last_side = 0; 
    end

    % ---------- 1) 이번 trial의 정답 위치 결정 ----------
    % 기본적으로는 랜덤 (1: 왼쪽 정답, 2: 오른쪽 정답)
    curr_choice = randi([1 2]);
    if curr_choice == 1, curr_side = -1; else, curr_side = 1; end

    % 만약 직전 방향이 max_consecutive만큼 반복되었다면 강제로 반전
    if state.consecutive_count >= max_consecutive
        curr_side = -state.last_side; % 무조건 반대 방향으로
    end

    % ---------- 2) 연속 카운트 갱신 ----------
    if curr_side == state.last_side
        state.consecutive_count = state.consecutive_count + 1;
    else
        % 방향이 바뀌었으면 다시 1부터 시작
        state.consecutive_count = 1;
    end
    state.last_side = curr_side;

    % ---------- 3) 숫자 배치 ----------
    lo = min(base_pair);
    hi = max(base_pair);

    if curr_side == -1
        % 왼쪽이 정답 (작은 숫자가 왼쪽)
        n_rects = [lo, hi];
    else
        % 오른쪽이 정답 (작은 숫자가 오른쪽)
        n_rects = [hi, lo];
    end
end