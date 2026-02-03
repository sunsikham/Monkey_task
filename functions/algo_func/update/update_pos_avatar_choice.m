function new_pos = update_pos_avatar_choice(current_pos, device_opt, ...
                                            movement_speed, visual_opt, ...
                                            game_opt, playArea)
% -------------------------------------------------------------------------
% playArea : polyshape 객체 (아바타 반경이 이미 반영된 상태)
% -------------------------------------------------------------------------

new_pos  = current_pos;            
avatar_r = game_opt.avatar_sz/2;    % (사실 playArea에 이미 반영돼 있음)

%% 1) 입력 벡터 계산 (기존 그대로) ---------------------------------------
joy_vec = [0 0];
if device_opt.KEYBOARD
    [keyIsDown, ~, keyCode] = KbCheck;
    if keyIsDown
        dx = double(keyCode(KbName('RightArrow'))) - ...
             double(keyCode(KbName('LeftArrow')));
        dy = double(keyCode(KbName('DownArrow')))  - ...
             double(keyCode(KbName('UpArrow')));
        joy_vec = joy_vec + [dx, dy];
    end
end
if device_opt.JOYSTICK
    [joy_tmp, ~] = JoyMEX(0);
    joy_tmp = joy_tmp(1:2);
    if norm(joy_tmp) >= device_opt.minInput
        joy_vec = joy_vec + joy_tmp;
    end
end
if norm(joy_vec) < device_opt.minInput
    return;
end
joy_vec = joy_vec / norm(joy_vec);
move    = joy_vec * movement_speed;

%% 2) 슬라이딩 스텝 분할 파라미터 ----------------------------------------
% maxStepDist: 한 스텝 당 최대 이동 거리 (px 단위)
%  - 작게 잡을수록 스텝이 많아져 벽에 더 “달라붙는” 느낌이 강해집니다.
%  - 크게 잡으면 스텝이 줄어들어 속도는 빠르나 미끄러짐 효과는 약해집니다.
maxStepDist = 1;  

%% 3) 스텝 수 계산 & 분할 이동 ------------------------------------------
dist  = norm(move);
if dist > 0
    Nstep = ceil(dist / maxStepDist);
else
    Nstep = 1;
end
step = move / Nstep;

pos = current_pos;
for s = 1:Nstep
    % (1) 원래 방향
    cand = pos + step;
    if isinterior(playArea, cand(1), cand(2))
        pos = cand;
        continue;
    end
    % (2) X 축만
    cand = [pos(1) + step(1), pos(2)];
    if isinterior(playArea, cand(1), cand(2))
        pos = cand;
        continue;
    end
    % (3) Y 축만
    cand = [pos(1), pos(2) + step(2)];
    if isinterior(playArea, cand(1), cand(2))
        pos = cand;
        continue;
    end
    % (4) 이동 불가 → 남은 스텝 취소
    break;
end

new_pos = pos;
end