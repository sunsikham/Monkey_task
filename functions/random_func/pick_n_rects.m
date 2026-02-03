function [n_rects, state, was_swapped] = pick_n_rects(num_rects, state)
% PICK_N_RECTS  후보 배열에서 중복 없이 숫자 2개를 뽑아 [왼, 오]로 배치하되,
%               "작은 수의 위치"가 같은 쪽으로 3회 연속 나오지 않도록 제어합니다.
%
% 사용법
%   [n_rects, state] = pick_n_rects([6 4 2]);
%   [n_rects, state] = pick_n_rects([6 4 2], state);
%
% 입력
%   num_rects : 1×N 숫자 배열 (예: [6 4 2]) — 서로 다른 값 권장
%   state     : (옵션) 상태 구조체. 비우거나 생략하면 내부에서 초기화
%               .streak_side  : 'L' 또는 'R' (작은 수가 있었던 쪽)
%               .streak_count : 같은 쪽이 연속된 횟수 (정수)
%
% 출력
%   n_rects    : 1×2, [왼, 오]
%   state      : 갱신된 상태 구조체 (다음 호출에 넘겨 연속성 추적)
%   was_swapped: 이번 호출에서 강제 스왑 발생 여부 (논리값)
%
% 규칙
%   - 매 호출마다 후보에서 서로 다른 두 수를 균일 랜덤 선정 → [a b]
%   - 작은 수가 왼쪽이면 'L', 오른쪽이면 'R'
%   - 같은 쪽이 3회 연속 나오지 않도록, 직전까지 2회 연속이고 이번에도 같아질 경우
%     이번 결과만 강제로 [b a]로 스왑해 연속 3회를 방지
%
% 비고
%   - num_rects에 중복값이 있어도 동작은 하나, 작은 수 판정이 애매해질 수 있으니
%     가급적 서로 다른 값을 사용하세요.

    if nargin < 2 || isempty(state)
        state = struct('streak_side','', 'streak_count', 0);
    else
        if ~isfield(state,'streak_side');  state.streak_side = ''; end
        if ~isfield(state,'streak_count'); state.streak_count = 0;  end
    end

    % 입력 검사
    assert(isvector(num_rects) && numel(num_rects) >= 2, ...
        'num_rects는 길이 2 이상인 벡터여야 합니다.');

    % 1) 후보에서 서로 다른 두 수 뽑기
    idx = randperm(numel(num_rects), 2);
    a = num_rects(idx(1));
    b = num_rects(idx(2));

    % 2) 작은 수가 있는 쪽 판정
    if a < b
        cur_side = 'L';
    elseif b < a
        cur_side = 'R';
   
    end

    % 3) 연속 3회 방지: 직전까지 2회 연속이고 이번에도 같아지려 하면 강제 스왑
    was_swapped = false;
    if state.streak_count >= 5 && ~isempty(state.streak_side) && state.streak_side == cur_side
        % 이번 결과를 뒤집어 작은 수 위치 반전
        tmp = a; a = b; b = tmp;
        cur_side = switch_side(cur_side);
        was_swapped = true;
        % 스왑했으니 새 패턴을 1회로 리셋
        state.streak_side  = cur_side;
        state.streak_count = 1;
    else
        % 스왑 없이 카운트 갱신
        if ~isempty(state.streak_side) && state.streak_side == cur_side
            state.streak_count = state.streak_count + 1;
        else
            state.streak_side  = cur_side;
            state.streak_count = 1;
        end
    end

    % 4) 결과 출력 (왼, 오)
    n_rects = [a, b];
end

function s2 = switch_side(s1)
    if s1 == 'L'; s2 = 'R'; else; s2 = 'L'; end
end

%{
%% 사용 예시
% state = [];
% for t = 1:20
%     [nr, state, sw] = pick_n_rects([6 4 2], state);
%     fprintf('%2d) n_rects = [%g %g], side=%s, count=%d, swap=%d\n', ...
%         t, nr(1), nr(2), state.streak_side, state.streak_count, sw);
% end
%}
