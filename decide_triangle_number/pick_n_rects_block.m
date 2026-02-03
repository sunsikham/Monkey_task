function [n_rects, state] = pick_n_rects_block(base_pair, len_range, state, last_correct)
% pick_n_rects_block
%   - base_pair    : 예) [2 5], [1 4] 처럼 "두 숫자"만 정해서 넘겨줌
%                    (어느 쪽이 정답인지는 이 함수에서 블록에 맞게 정리)
%   - len_range    : [10 15] 이면, 10~15번 "성공"할 때마다
%                    정답 위치(왼/오) 블록 전환
%   - state        : 블록 상태 struct
%   - last_correct : 직전 trial 의 curr_trial_data.correct (0/1 또는 없음)
%
% 출력
%   - n_rects : 이번 trial 에 실제로 사용할 [nL nR]
%               👉 항상 "숫자 적은 쪽이 정답"이 되도록 배치
%   - state   : 갱신된 상태

    % ---------- 0) state / last_correct 초기화 ----------
    if nargin < 3 || isempty(state)
        state = struct();
    end

    if nargin < 4 || isempty(last_correct)
        last_correct = NaN;
    end

    % curr_side:
    %   -1 : 이번 블록은 "왼쪽이 정답" (작은 숫자가 왼쪽에 오도록 배치)
    %   +1 : 이번 블록은 "오른쪽이 정답" (작은 숫자가 오른쪽에 오도록 배치)
    if ~isfield(state, 'curr_side') || isempty(state.curr_side)
        % 처음 시작: 원하는 대로 왼/오 중 하나로 시작 (여기서는 오른쪽 정답으로 시작)
        state.curr_side = +1;
        % 랜덤 스타트로 하고 싶으면:
        % state.curr_side = randi([0 1])*2 - 1;  % -1 또는 +1
    end

    % 현재까지 성공 trial 수
    if ~isfield(state, 'success_count') || isempty(state.success_count)
        state.success_count = 0;
    end

    % 이번 블록에서 목표로 할 "성공 trial 수"
    if ~isfield(state, 'target_success') || isempty(state.target_success)
        state.target_success = randi(len_range);
    end

    % ---------- 1) 직전 trial 결과로 성공 카운트 갱신 ----------
    if ~isnan(last_correct)
        if last_correct == 1
            state.success_count = state.success_count + 1;
        end
        % 연속 성공 기준으로 쓰고 싶으면:
        % else
        %     state.success_count = 0;
        % end
    end

    % ---------- 2) 목표 성공 횟수에 도달했으면 블록 전환 ----------
    if state.success_count >= state.target_success
        state.success_count  = 0;
        state.target_success = randi(len_range);
        state.curr_side      = -state.curr_side;   % 왼↔오 스위치
    end

    % ---------- 3) 이번 trial 의 숫자 배치 계산 ----------
    % 숫자 적은 쪽이 항상 정답이 되도록 min/max 사용
    lo = min(base_pair);
    hi = max(base_pair);

    if state.curr_side == 1
        % 이번 블록은 "왼쪽이 정답" → 작은 숫자를 왼쪽에
        n_rects = [lo, hi];
    else
        % 이번 블록은 "오른쪽이 정답" → 작은 숫자를 오른쪽에
        n_rects = [hi, lo];
    end
end
