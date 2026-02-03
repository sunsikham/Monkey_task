function [curr_trial_data, game_opt] = generate_eels_info(curr_trial_data, visual_opt, game_opt)
% GENERATE_EELS_INFO - Initializes eel-specific data for the current trial
%
% Syntax:
%   [curr_trial_data, game_opt] = generate_eels_info(curr_trial_data, visual_opt, game_opt)
%
% Inputs:
%   curr_trial_data - Struct containing current trial data (includes trial_idx)
%   visual_opt      - Struct containing visual options
%   game_opt        - Struct containing game options
%
% Outputs:
%   curr_trial_data - Updated trial data with eel information
%   game_opt        - Updated game options with persistent switch schedules

    % Either load premade trials or generate on-the-fly
    if game_opt.premade_eels
        % Try to load premade eel data
        eel_data_filename = fullfile(game_opt.eels_src, sprintf('trial_%03d.mat', curr_trial_data.trial_idx));
        if exist(eel_data_filename, 'file')
            loaded = load(eel_data_filename, 'curr_trial_data');
            
            
            sprintf('Loading');
            % Copy relevant fields from loaded data
            curr_trial_data.eels = loaded.curr_trial_data.eels;
            curr_trial_data.avtr_start_pos = loaded.curr_trial_data.avtr_start_pos;
            
        else
            warning('Premade eel data for trial %d not found. Generating on the fly.', curr_trial_data.trial_idx);
            [curr_trial_data, game_opt] = generate_eels_dynamically(curr_trial_data, visual_opt, game_opt);
        end
    else
        % Generate eels dynamically for this trial
        [curr_trial_data, game_opt] = generate_eels_dynamically(curr_trial_data, visual_opt, game_opt);
    end
end