function [rel_swapped, comp_swapped, switch_schedules, game_opt] = get_eel_switch_state(trial_idx, game_opt)
% GET_EEL_SWITCH_STATE - Determines switching state for reliability and competency
%
% Syntax:
%   [rel_swapped, comp_swapped] = get_eel_switch_state(trial_idx, game_opt)
%   [rel_swapped, comp_swapped, switch_schedules] = get_eel_switch_state(trial_idx, game_opt)
%   [rel_swapped, comp_swapped, switch_schedules, game_opt] = get_eel_switch_state(trial_idx, game_opt)
%
% Inputs:
%   trial_idx - Current trial index
%   game_opt  - Structure containing game parameters
%
% Outputs:
%   rel_swapped      - Boolean indicating if reliability is swapped for this trial
%   comp_swapped     - Boolean indicating if competency is swapped for this trial
%   switch_schedules - (optional) Structure with generated switch schedules
%   game_opt         - (optional) Updated game_opt structure with saved schedules

    % Check if we have switch schedules already defined in game_opt
    has_rel_schedule = isfield(game_opt, 'reliability_switch_trials') && ~isempty(game_opt.reliability_switch_trials);
    has_comp_schedule = isfield(game_opt, 'competency_switch_trials') && ~isempty(game_opt.competency_switch_trials);
    
    % If we don't have the schedules, generate them
    if ~has_rel_schedule
        reliability_switch_trials = generate_switch_schedule(game_opt.reliability_offset, ...
                                                            game_opt.n_trials, ...
                                                            game_opt.min_rel_switch, ...
                                                            game_opt.max_rel_switch);
        % Save the generated schedule in game_opt
        game_opt.reliability_switch_trials = reliability_switch_trials;
    else
        reliability_switch_trials = game_opt.reliability_switch_trials;
    end
    
    if ~has_comp_schedule
        competency_switch_trials = generate_switch_schedule(game_opt.competency_switch_offset, ...
                                                           game_opt.n_trials, ...
                                                           game_opt.min_comp_switch, ...
                                                           game_opt.max_comp_switch);
        % Save the generated schedule in game_opt
        game_opt.competency_switch_trials = competency_switch_trials;
    else
        competency_switch_trials = game_opt.competency_switch_trials;
    end
    
    % Make sure initial states are defined (randomize if not)
    if ~isfield(game_opt, 'initial_rel_swapped')
        game_opt.initial_rel_swapped = (rand() > 0.5); % Random initial state
        fprintf('Randomized initial_rel_swapped = %d\n', game_opt.initial_rel_swapped);
    end
    
    if ~isfield(game_opt, 'initial_comp_swapped')
        game_opt.initial_comp_swapped = (rand() > 0.5); % Random initial state
        fprintf('Randomized initial_comp_swapped = %d\n', game_opt.initial_comp_swapped);
    end
    
    % Determine reliability switching state
    if trial_idx <= game_opt.reliability_offset
        rel_swapped = game_opt.initial_rel_swapped;
    else
        % XOR operation: If initial state is true, then odd count = false
        % If initial state is false, then odd count = true
        switches_count = sum(reliability_switch_trials <= trial_idx);
        rel_swapped = xor(mod(switches_count, 2) == 1, ~game_opt.initial_rel_swapped);
    end
    
    % Determine competency switching state
    if trial_idx <= game_opt.competency_switch_offset
        comp_swapped = game_opt.initial_comp_swapped;
    else
        % XOR operation: If initial state is true, then odd count = false
        % If initial state is false, then odd count = true
        switches_count = sum(competency_switch_trials <= trial_idx);
        comp_swapped = xor(mod(switches_count, 2) == 1, ~game_opt.initial_comp_swapped);
    end
    
    % If third output requested, return the generated schedules
    if nargout > 2
        switch_schedules.reliability_switch_trials = reliability_switch_trials;
        switch_schedules.competency_switch_trials = competency_switch_trials;
    end
end

function switch_trials = generate_switch_schedule(offset, n_trials, min_switch, max_switch)
    % Helper function to generate a switching schedule
    
    switch_trials = [];
    current_trial = offset;
    
    while current_trial <= n_trials
        switch_trials(end+1) = round(current_trial);
        % Use uniform distribution for switch interval
        interval = randi([min_switch, max_switch]);
        current_trial = current_trial + interval;
    end
end