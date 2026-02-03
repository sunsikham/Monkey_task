function isFix = check_fixation(eye_data, dot_xy, radius_px)

dx = eye_data.eyeX - dot_xy(1);
dy = eye_data.eyeY - dot_xy(2);
isFix = sqrt(dx^2 + dy^2) < radius_px;
end
