function [rKeyState, trialData] = check_reward_key( ...
            rKeyState, trialData, phaseStr, deviceOpt, reward_duration)
% CHECK_REWARD_KEY
% ──────────────────────────────────────────────────────────────
%  ‣ ‘r’ 키를 **새로** 눌렀을 때만 보상을 1 회 지급합니다.
%  ‣ Psychtoolbox KbQueue API를 사용하므로, 키가 눌린 순간이
%    화면·코드 루프 타이밍과 달라도 이벤트를 놓치지 않습니다.
%
% 입력
% ──
%   rKeyState        : 직전 호출 시 ‘r’키가 눌려 있었는지 (true/false)
%   trialData        : 현재 트라이얼 데이터 구조체
%   phaseStr         : 현재 phase 이름 (예: 'manual_check')
%   deviceOpt.kb     : KbQueue용 디바이스 인덱스
%   reward_duration  : 보상 지속 시간 (초)
%
% 출력
% ──
%   rKeyState        : 이번 호출 후 ‘r’키 현재 상태
%   trialData        : 보상 시각이 기록된 업데이트 버전
% ──────────────────────────────────────────────────────────────

    %% 1. 기록용 필드 확보
    if ~isfield(trialData, phaseStr) || ...
       ~isfield(trialData.(phaseStr), 'manual_reward_times')
        trialData.(phaseStr).manual_reward_times = [];
    end
    if ~isfield(trialData.(phaseStr), 'phase_start')
        trialData.(phaseStr).phase_start = GetSecs();
    end

    %% 2. 큐에서 최신 이벤트 확인
    [pressed, firstPress] = KbQueueCheck(deviceOpt.kb);
    is_r_key_down_now = pressed && firstPress(KbName('r')) ~= 0;

    %% 3. ‘새로운’ r‑press라면 보상 지급
    if is_r_key_down_now && ~rKeyState
        fprintf('R key pressed → delivering manual reward.\n');

        give_reward(deviceOpt, reward_duration);      % <‑‑ 사용자 정의 함수

        relTime = GetSecs() - trialData.(phaseStr).phase_start;
        trialData.(phaseStr).manual_reward_times(end+1) = relTime;

        KbQueueFlush(deviceOpt.kb);                   % 이미 처리한 press 제거
    end

    %% 4. 다음 호출을 위한 상태 보존
    rKeyState = is_r_key_down_now;
end
