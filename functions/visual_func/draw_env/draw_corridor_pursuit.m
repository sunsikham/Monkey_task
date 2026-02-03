function visual_opt = draw_corridor_pursuit(visual_opt)
    % 이 함수는 'pursuit' 단계 전용으로, 틈이 없는 통짜 벽을 그립니다.

    % 전체 벽 영역의 좌표를 계산
    upper_left = visual_opt.corridor_coord(1, :);
    upper_right = visual_opt.corridor_coord(3, :);
    
    wall_x = upper_left(1);
    wall_y = 0; % 화면 맨 위
    wall_width = upper_right(1) - upper_left(1);
    wall_height = visual_opt.wHgt; % 화면 전체 높이
    
    solid_wall_rect = [wall_x, wall_y, wall_x + wall_width, wall_height];
    
    % 통짜 벽 그리기
    Screen('FillRect', visual_opt.winPtr, visual_opt.corridor_color, solid_wall_rect);
    
    % 충돌 감지를 위해 통짜 벽의 좌표를 visual_opt에 저장
    visual_opt.solid_wall_rect = solid_wall_rect;
end