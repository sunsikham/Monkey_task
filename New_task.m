%% if you want to change the triangle number go line 31 the maximum number is now 6
%  if you want to change initial number of fish, go phase choice and check line 56 
% if you want to change reward amount, go display_score check line 136

clear all

% Initialize PsychPortAudio once (safe even if audio is not used)
try
    InitializePsychSound(1);
catch ME
    warning('PsychSound init failed: %s', ME.message);
end
 
manual_eyelink_calibration = true;
if manual_eyelink_calibration
    Eyelink_BigOnScreen1_SmallOnScreen2_GainOffset_WASD_LOG_FlipXY;
end
% 1. 모든 설정을 초기화하여 visual_opt, device_opt 등의 변수를 생성합니다.
[visual_opt, device_opt, game_opt, eye_opt, save_directory] = initalize(manual_eyelink_calibration);

% 2. 이제 device_opt가 존재하므로, 여기에 logFileID를 안전하게 추가합니다.
visual_opt.color_fish = [128 128 128];

% Ensure PTB window is valid (reopen if needed)
visual_opt.winPtr = ptb_get_winptr(visual_opt, true);
visual_opt.refresh_rate = Screen('NominalFrameRate', visual_opt.winPtr);
[visual_opt.wWth, visual_opt.wHgt] = Screen('WindowSize', visual_opt.winPtr);
visual_opt.screen_center = [visual_opt.wWth / 2, visual_opt.wHgt / 2];

% 변수 조정 
game_opt.avatar_speed=12;
game_opt.fast_spd=3.5;

game_opt.choice_time=10;
game_opt.pursuit_time=15;

max_fish=6;
max_time=1;

% 추출할 숫자의 개수
k = 2;

acc_map=struct();

trial_onset = true;
num_rects={ [2 5], [1 4] };
% 실험 정보 초기화
time_info = struct();
time_info.exp_init_time = GetSecs;
all_trials = initialize_all_trials_info();

% ======================= [수정된 부분 시작] =======================
% 마지막으로 저장된 trial을 찾는 대신, 항상 0부터 시작하도록 초기화합니다.
trial_files = dir(fullfile(save_directory, 'trial_*.mat'));

if isempty(trial_files)
    % 이전에 저장된 파일이 없으면 0부터 시작합니다.
    prev_trial_idx = 0;
    fprintf('저장된 데이터가 없습니다. 새로운 실험을 시작합니다 (Trial 1).\n');
else
    % 저장된 파일이 있으면, 파일 이름에서 trial 번호를 추출하여 가장 큰 값을 찾습니다.
    trial_numbers = [];
    for i = 1:length(trial_files)
        % 정규표현식을 사용하여 'trial_123.mat' 같은 파일명에서 숫자(123)만 추출합니다.
        num = regexp(trial_files(i).name, '\d+', 'match');
        if ~isempty(num)
            trial_numbers(end+1) = str2double(num{1});
        end
    end
    
    if isempty(trial_numbers)
        % 파일은 있지만 숫자 패턴을 찾지 못한 경우
        prev_trial_idx = 0;
        fprintf('파일을 찾았지만 trial 번호를 확인할 수 없습니다. 새로운 실험을 시작합니다 (Trial 1).\n');
    else
        % 찾은 trial 번호 중 가장 큰 값을 prev_trial_idx로 설정합니다.
        prev_trial_idx = max(trial_numbers);
        fprintf('이전 데이터가 확인되었습니다. Trial %d 부터 실험을 재개합니다.\n', prev_trial_idx + 1);
    end
end
% ======================== [수정된 부분 끝] ========================

total_trials = 2500;
KbName('UnifyKeyNames');
kbList        = GetKeyboardIndices;
if isempty(kbList)
    device_opt.kb = -1;
else
    device_opt.kb = -1; % listen to all keyboards to catch 'r' reliably
end
KbQueueCreate(device_opt.kb);
KbQueueStart(device_opt.kb);
KbQueueFlush(device_opt.kb);
rKeyState = false; 
count=0;
last_correct = NaN;
% 메인 Trial 루프
while trial_onset && prev_trial_idx < total_trials
    if ~exist('state','var') || isempty(state)
    state = struct('streak_side','', 'streak_count', 0);
    end
    
    rect_colors = [128 128 128];
    
    %% Trial별 초기화
    time_info = initialize_time_info(time_info);
    time_info.trial_init_time = GetSecs;
    curr_trial_data = struct();
    curr_trial_data.trial_idx = prev_trial_idx + 1;
    
    %% Trial 단계(Phase) 실행
    is_special_trigger_trial=0;
    
    
   
    pairs    = { [2,5],[1 4]};
    idx      = randi(numel(pairs));
    base_pair = pairs{idx};   
    

    [n_rects, state] = pick_n_rects_block(base_pair, [2,4], state, last_correct);
    %[n_rects, state] = pick_n_rects_random(base_pair, 2, state);

    [curr_trial_data, game_opt, visual_opt] = phase_iti(curr_trial_data, visual_opt, game_opt, eye_opt, device_opt, true, 'ITI1');
   
    % 특별 트리거가 발생한 trial인지 여부를 데이터에 저장합니다.
    curr_trial_data.gray_triger = is_special_trigger_trial;
    
    [curr_trial_data,unuseTri,layout] = phase_choice(curr_trial_data, visual_opt, game_opt, eye_opt, 'CHOICE', device_opt, rKeyState, n_rects, rect_colors);

    if curr_trial_data.CHOICE.choice == -1
        % ── ① 시간 초과 or 선택 실패 ─────────────────────
        display_gray_screen(visual_opt, game_opt);   % 0.5~1 s 정도
        % (원하면 give_reward 0 등 추가 로직)

        % trial 로그 저장 & 다음 trial 로 이동
        save(fullfile(save_directory, ...
              ['trial_', num2str(curr_trial_data.trial_idx), '.mat']), ...
              'curr_trial_data');
        prev_trial_idx = curr_trial_data.trial_idx;
        continue;     % ▶︎ while trial_onset … 의 다음 loop 로
    end
    

    
    curr_trial_data = phase_pursuit(curr_trial_data, visual_opt, device_opt, game_opt, eye_opt, 'PURSUIT', rKeyState,layout);

    [data, all_trials] = display_score(curr_trial_data, visual_opt, game_opt, device_opt, all_trials, max_fish, max_time);

    % 현재 Trial 데이터 저장
    acc_map = update_accuracy(acc_map, n_rects, curr_trial_data.correct);
    curr_trial_data.rect_number=n_rects;
    full_file_path = fullfile(save_directory, ['trial_', num2str(curr_trial_data.trial_idx), '.mat']);
    save(full_file_path, 'curr_trial_data');
    prev_trial_idx = curr_trial_data.trial_idx;
    last_correct = curr_trial_data.correct;
    
end
