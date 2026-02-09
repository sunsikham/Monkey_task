function [curr_trial_data,unuseTri,layout] = phase_choice(curr_trial_data, visual_opt, ...
                                        game_opt, eye_opt, phase_str, ...
                                        device_opt, rKeyState,n_rects,rect_colors)

%% 0. 맵·도형·좌표 만들기
visual_opt.winPtr = ptb_get_winptr(visual_opt, true);
visual_opt.refresh_rate = Screen('NominalFrameRate', visual_opt.winPtr);
[visual_opt.wWth, visual_opt.wHgt] = Screen('WindowSize', visual_opt.winPtr);
visual_opt.screen_center = [visual_opt.wWth / 2, visual_opt.wHgt / 2];
swap_shapes = rand < 0.5;      % (지금은 안 쓰더라도 일단 유지)
curr_trial_data.swap_shapes = swap_shapes;

visual_opt.color_fish = [128 128 128];   % 물고기 색(회색)

[bottom_rect, upper_rect, corridor_rects, corridorsDraw, ...
    rect1_coords, rect2_coords, color1, color2, is_active, ...
    rects1_coords, rects2_coords, tri1_polys, tri2_polys] = ...
    draw_new_MAP1(visual_opt,game_opt,curr_trial_data,n_rects);

layout = struct( ...
    'Upper_Rect',    upper_rect, ...
    'Bottom_Rect',   bottom_rect, ...
    'Corridors',     corridor_rects, ...
    'CorridorsDraw', corridorsDraw, ...
    'Rect1',         rect1_coords, ...
    'Rect2',         rect2_coords, ...
    'Rects1_coords', rects1_coords, ...
    'Rects2_coords', rects2_coords, ...
    'Color1',        color1, ...
    'Color2',        color2, ...
    'IsActive',      logical(is_active), ...
    'GrayTrig',      curr_trial_data.gray_triger, ...
    'tri1_polys',    tri1_polys, ...
    'tri2_polys',    tri2_polys);

layout.DrawMask = [any(layout.Color1 ~= 128), any(layout.Color2 ~= 128)];

% default 출력값
unuseTri = [];

%% 1. 아바타·물고기 초기화
playArea = makePlayableAreaPoly_choice( upper_rect, bottom_rect, ...
                                        game_opt.avatar_sz/2);

box_cx    = mean(bottom_rect([1 3]));  % 하단 BOX 중심
box_cy    = mean(bottom_rect([2 4]));
avtr_pos  = [box_cx, box_cy];         % 아바타 시작점
avatar_speed = 8;

nFish      = 7;
fishSizePx = 25;
xL = upper_rect(1) + fishSizePx;
xR = upper_rect(3) - fishSizePx;
yT = upper_rect(2) + fishSizePx;
yB = upper_rect(4) - fishSizePx;

fish_curr_pos = [rand(nFish,1)*(xR-xL)+xL, ...
                 rand(nFish,1)*(yB-yT)+yT];
fish_prev_pos = fish_curr_pos;

% Gaze monitor disabled for task stability.

%% 2. trial-data 기본 필드
if ~isfield(curr_trial_data, phase_str)
    curr_trial_data.(phase_str) = struct();
end
curr_trial_data.(phase_str).choice      = -1;
curr_trial_data.(phase_str).phase_start = GetSecs();

% 지연시간(무빙 lock) 설정
delay_time        = 0.5 + 0.25*rand();
movement_allowed  = false;
start_time        = GetSecs();

% 포지션/eye 데이터 버퍼
num_steps      = round(visual_opt.refresh_rate * 20);
all_avatar_pos = -1 * ones(num_steps,2);
all_eye_data(num_steps) = struct('eyeX',[],'eyeY',[],'pupSize',[]);

[rKeyState, curr_trial_data] = check_reward_key( ...
    rKeyState, curr_trial_data, 'manual_check', device_opt, 0.5);

%% 3. CHOICE 메인 루프
choice_on = true;
t_step    = 1;
op_frame  = 0;
op_update_every = 3;

render_map_from_layout1(visual_opt, layout, [0 0 255]);
draw_fishes(fish_curr_pos, visual_opt.color_fish, ...
            fishSizePx, visual_opt.winPtr);
draw_avatar(avtr_pos, [255 255 0], game_opt.avatar_sz, visual_opt.winPtr);

vbl = Screen('Flip', visual_opt.winPtr);
WaitSecs('UntilTime', vbl + 1);

while choice_on
    [rKeyState, curr_trial_data] = check_reward_key( ...
        rKeyState, curr_trial_data, 'manual_check', device_opt, 0.5);

    now = GetSecs();

    % 3-1. 입력 허용 체크 & 아바타 이동
    if ~movement_allowed && (now - start_time) >= delay_time
        movement_allowed = true;
    end

    if movement_allowed
        avtr_pos = update_pos_avatar_choice(avtr_pos, device_opt, ...
                                            avatar_speed, visual_opt, ...
                                            game_opt, playArea);
    end

    % 3-2. 물고기 이동 (upper_rect 내부)
    fish_fut_pos = move_fishes_no_eel( ...
        fish_curr_pos, fish_prev_pos, avtr_pos, ...
        game_opt, upper_rect);

    fish_prev_pos = fish_curr_pos;
    fish_curr_pos = fish_fut_pos;

    % 3-3. 그리기
    render_map_from_layout1(visual_opt, layout, [0 0 255]);
    draw_fishes(fish_curr_pos, visual_opt.color_fish, ...
                fishSizePx, visual_opt.winPtr);
    draw_avatar(avtr_pos, [255 255 0], game_opt.avatar_sz, ...
                visual_opt.winPtr);

    if t_step <= num_steps
        all_avatar_pos(t_step,:) = avtr_pos;
    end
    Screen('Flip', visual_opt.winPtr);

    % Operator gaze window (throttled)
    op_frame = op_frame + 1;
    if mod(op_frame, op_update_every) == 0
        draw_operator_scene(visual_opt, eye_opt, layout, 'choice', [0 0 255]);
    end

    % 3-4. 눈 데이터 저장
    eye_data = sample_eyes(eye_opt);
    all_eye_data(t_step).eyeX    = eye_data.eyeX;
    all_eye_data(t_step).eyeY    = eye_data.eyeY;
    all_eye_data(t_step).pupSize = eye_data.eyePupSz;

    % 3-5. 충돌(원 터치) 판정
    n1 = size(rects1_coords,2);      % 왼쪽 원 삼각형 개수
    n2 = size(rects2_coords,2);      % 오른쪽 원 삼각형 개수

    hit_rect1 = (avtr_pos(1) >= rect1_coords(1) && avtr_pos(1) <= rect1_coords(3) && ...
                 avtr_pos(2) >= rect1_coords(2) && avtr_pos(2) <= rect1_coords(4));
    hit_rect2 = (avtr_pos(1) >= rect2_coords(1) && avtr_pos(1) <= rect2_coords(3) && ...
                 avtr_pos(2) >= rect2_coords(2) && avtr_pos(2) <= rect2_coords(4));

    if curr_trial_data.gray_triger == 0
        % 두 쪽 모두 유효
        if (hit_rect1 && is_active(1)) || (hit_rect2 && is_active(2))
            if hit_rect1
                curr_trial_data.color     = rect_colors;
                curr_trial_data.hit_rects = rects1_coords;   % 왼쪽 원 안 삼각형 바운딩
                nHit   = n1;
                nOther = n2;
            else
                curr_trial_data.color     = rect_colors;
                curr_trial_data.hit_rects = rects2_coords;   % 오른쪽 원 안 삼각형 바운딩
                nHit   = n2;
                nOther = n1;
            end
            curr_trial_data.correct              = double(nHit < nOther);
            curr_trial_data.(phase_str).choice   = 1;
            choice_on = false;
        end

    elseif curr_trial_data.gray_triger == 1
        % 한쪽만 유효: is_active로 제한
        if (hit_rect1 && is_active(1)) || (hit_rect2 && is_active(2))
            if hit_rect1
                curr_trial_data.color = color1;
            else
                curr_trial_data.color = color2;
            end
            curr_trial_data.(phase_str).choice = 1;
            choice_on = false;
            WaitSecs(0.5);
        elseif (hit_rect1 || hit_rect2)
            curr_trial_data.(phase_str).choice = 1;
            curr_trial_data.color = [128,128,128];
            choice_on = false;
        end

    elseif curr_trial_data.gray_triger == 2 && (hit_rect1 || hit_rect2)
        curr_trial_data.color = [128,128,128];
        curr_trial_data.(phase_str).choice = 1;
        choice_on = false;
    end

    t_step = t_step + 1;
end

%% 4. 오답 피드백
if isfield(curr_trial_data,'correct') && curr_trial_data.correct == 0
    Screen('FillRect', visual_opt.winPtr, [255 0 0]);
    Screen('Flip', visual_opt.winPtr);
    WaitSecs(1);
else 
    Screen('FillRect', visual_opt.winPtr, [0 255 0]);
    Screen('Flip', visual_opt.winPtr);
    WaitSecs(0.5);

end
%% 원래 맵 그리기
    render_map_from_layout1(visual_opt, layout, [0 0 255]);
    draw_fishes(fish_curr_pos, visual_opt.color_fish, ...
                fishSizePx, visual_opt.winPtr);
    draw_avatar(avtr_pos, [255 255 0], game_opt.avatar_sz, ...
                visual_opt.winPtr);
    Screen('Flip', visual_opt.winPtr);

 WaitSecs(0.5);


%% 5. 삼각형 + 물고기 축소 단계 (gray_triger == 0 & hit_rects 가 있는 경우만)
if curr_trial_data.gray_triger == 0 && ...
   isfield(curr_trial_data,'hit_rects') && ~isempty(curr_trial_data.hit_rects)

    rects  = curr_trial_data.hit_rects;      % 4×Krect
    Krect  = size(rects,2);

    triL   = layout.tri1_polys;  KL = size(triL,3);
    triR   = layout.tri2_polys;  KR = size(triR,3);

    % --- 어느 쪽 원이 선택되었는지: hit_rects 개수와 tri1/tri2 개수 비교 ---
    if KL == Krect && KR ~= Krect
        useTri   = triL;    
        unuseTri = triR;    
    elseif KR == Krect && KL ~= Krect
        useTri   = triR;
        unuseTri = triL;
    else
      
        useTri   = triL;
        unuseTri = triR;
    end

    Ktri  = size(useTri,3);        
    Nfish = size(fish_curr_pos,1); 

 
    Kmove = min([Krect, Ktri, Nfish]);

    % 색상 정의
    tri_color_static  = [0 0 255];          % 아직 남아 있는 삼각형 (회색)
    tri_color_active  = [255   0   0];          % 축소 중인 삼각형 (빨간색)
    fish_color_static = visual_opt.color_fish;  % 원래 물고기 색
    fish_color_active = [255   0   0];          % 축소 중인 물고기 (빨간색)

   
    aliveTriMask  = true(1, Ktri);
  
    aliveFishMask = ~any(fish_curr_pos == -1, 2)';   % 1×Nfish 논리벡터

    if Kmove > 0
        % 물고기 중에서 Kmove 개를 랜덤으로 골라서 매칭
        selIdx = randperm(Nfish, Kmove);

        nFrm = 20;   % 한 삼각형/물고기 축소 애니메이션 프레임 수

        for iTri = 1:Kmove
            % --- ① 이번에 축소할 삼각형 원본 정보 ---
            tri0 = useTri(:,:,iTri);        % 3×2
            cTri = mean(tri0, 1);           % 중심 1×2

            % --- ② 이번 삼각형과 매칭될 물고기 인덱스 ---
            fish_idx = selIdx(iTri);
            if fish_idx < 1 || fish_idx > Nfish
                continue;
            end
            fish_center = fish_curr_pos(fish_idx,:);  % 1×2

            % 이미 죽어 있는 물고기면 스킵
            if any(fish_center == -1)
                aliveTriMask(iTri)    = false;
                aliveFishMask(fish_idx) = false;
                continue;
            end

            % --- ③ 프레임 루프: 삼각형 + 물고기 동시 축소 ---
            for f = 1:nFrm
                t = (f-1)/(nFrm-1);          % 0 → 1
                % 삼각형/물고기 스케일: 1 → 0.1
                scale = 1 - 0.99*t;

                % (a) 삼각형 축소 (중심 기준)
                tri_scaled = (tri0 - cTri) * scale + cTri;   % 3×2
                triNow     = reshape(tri_scaled, 3, 2, 1);   % 3×2×1

                % (b) 물고기 크기 축소
                fish_size_scaled = fishSizePx * scale;

             
                % 1) 배경 (원/사각형 등, 삼각형은 안 그리는 버전)
                render_map_from_layout1_moving_fish(visual_opt, layout);


                if ~isempty(unuseTri)
                    draw_tri(unuseTri, tri_color_static, visual_opt.winPtr);
                end

             
                staticIdx = find(aliveTriMask);
                staticIdx = staticIdx(staticIdx ~= iTri);
                if ~isempty(staticIdx)
                    draw_tri(useTri(:,:,staticIdx), tri_color_static, visual_opt.winPtr);
                end

                % 4) 지금 줄어들고 있는 삼각형 (빨간색)
                draw_tri(triNow, tri_color_active, visual_opt.winPtr);

                % 5) 물고기들 그리기
                for j = 1:Nfish
                    c = fish_curr_pos(j,:);
                    if any(c == -1)
                        continue;  % 이미 제거된 물고기
                    end

                    if j == fish_idx
                        % 이번에 줄어들고 있는 물고기: 빨간색 + 축소 크기
                        sz  = fish_size_scaled;
                        col = fish_color_active;
                    else
                        % 나머지 물고기: 원래 색 + 원래 크기
                        sz  = fishSizePx;
                        col = fish_color_static;
                    end

                    fish_coord = [ ...
                        c(1)-sz, c(2)-sz, ...
                        c(1)+sz, c(2)+sz];
                    Screen('FillRect', visual_opt.winPtr, col, fish_coord);
                end

                % 6) 아바타: CHOICE 단계 마지막 위치 그대로
                draw_avatar(avtr_pos, [255 255 0], game_opt.avatar_sz, visual_opt.winPtr);

                Screen('Flip', visual_opt.winPtr);
            end

            % --- ④ 애니메이션 끝: 해당 물고기/삼각형을 실제로 제거 ---
            fish_curr_pos(fish_idx, :) = [-1 -1];  % 물고기 제거
            aliveTriMask(iTri)         = false;    % 삼각형 제거
            aliveFishMask(fish_idx)    = false;
        end
    end

    % 최종적으로 살아 있는 물고기 좌표만 다음 phase 로 넘김
    keepMask = ~any(fish_curr_pos == -1, 2);
    curr_trial_data.(phase_str).final_fish_pos = fish_curr_pos(keepMask, :);

else
    % 삼각형/물고기 축소 단계가 없을 때도 final_fish_pos 는 그대로 넘김
    curr_trial_data.(phase_str).final_fish_pos = fish_curr_pos;
end



%% 6. trial-data 마무리 저장
final_eye_data = all_eye_data(1:t_step-1);
valid_steps    = min(t_step-1, num_steps);

curr_trial_data.(phase_str).phase_end = GetSecs();
curr_trial_data.(phase_str).phase_duration = ...
    curr_trial_data.(phase_str).phase_end - ...
    curr_trial_data.(phase_str).phase_start;

% 아바타 마지막 위치 (삼각형 애니메이션 동안에는 고정)
curr_trial_data.(phase_str).final_avatar_pos = avtr_pos;

curr_trial_data = concatenate_pos_data(curr_trial_data, ...
    all_avatar_pos(1:valid_steps,:), -1, final_eye_data, phase_str);

WaitSecs(0.5);

end
