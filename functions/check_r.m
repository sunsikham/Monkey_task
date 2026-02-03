% 1. 큐 초기화 (제공된 초기화 코드 사용)
KbName('UnifyKeyNames');
allKb = GetKeyboardIndices;
kb = allKb(1);
KbQueueCreate(kb);
KbQueueStart(kb);
KbQueueFlush(kb);

% 2. 큐 확인 루프
fprintf("지금부터 'r' 키를 여러 번 눌러보세요. (종료: Ctrl+C)\n");
while true
    [pressed, firstPress] = KbQueueCheck(kb);
    % 'r' 키 눌림 이벤트가 큐에 있는지 확인
    if pressed && firstPress(KbName('r')) > 0
        fprintf("성공: 'r' 키 눌림 이벤트가 큐에서 확인되었습니다!\n");
        KbQueueFlush(kb); % 테스트를 위해 확인 후 바로 비움
    end
    WaitSecs(0.01);
end

rKeyState = false; % 상태 변수 초기화
dummyData = struct('manual_check', struct('phase_start', GetSecs())); % 더미 데이터
fprintf("함수 호출을 테스트합니다. 'r' 키를 눌러보세요. (종료: Ctrl+C)\n");
while true
    % check_reward_key 함수만 계속 호출
    [rKeyState, ~] = check_reward_key(rKeyState, dummyData, 'manual_check', device_opt, 0.1);
    WaitSecs(0.01);
end