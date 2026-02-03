function joy_Vec = norm_joy(joy_Vec)
    if (sum(joy_Vec.^2)) == 0
        return
    end
    [~ , max_index] = max(abs(joy_Vec));
    max_vec = joy_Vec*(1/abs(joy_Vec(max_index)));
    joy_Vec = joy_Vec*(1/(sqrt(sum(max_vec.^2))));
end