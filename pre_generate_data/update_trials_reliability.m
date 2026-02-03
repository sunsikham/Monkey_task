%% Update Trials: Modify Eel Reliabilities
% This script loads each trial file, updates reliabilities from [0.3, 0.15] to [0.4, 0.05], and saves the updated trial

clear; close all; clc;

%% Setup Paths
currentFolder = pwd; % Use current directory
data_directory = fullfile(currentFolder, 'pre_generate_data', 'data', 'Copy_of_premade_trials');

if ~exist(data_directory, 'dir')
    error('Trial data directory not found: %s', data_directory);
end

% Get list of all trial files
trial_files = dir(fullfile(data_directory, 'trial_*.mat'));
num_trials = length(trial_files);

if num_trials == 0
    error('No trial files found in directory: %s', data_directory);
end

fprintf('Found %d trial files to update.\n', num_trials);

%% Process Each Trial
for i = 1:num_trials
    % Load the trial data
    trial_path = fullfile(data_directory, trial_files(i).name);
    fprintf('Processing %s (%d/%d)\n', trial_files(i).name, i, num_trials);
    
    try
        load(trial_path, 'curr_trial_data');
        
        % Update each eel's reliability
        for e = 1:length(curr_trial_data.eels)
            % Get current reliability
            current_rel = curr_trial_data.eels(e).reliability;
            
            % Update based on color
            if isequal(curr_trial_data.eels(e).eel_col, [0, 0, 255])  % Blue eel
                if abs(current_rel - 0.3) < 0.01  % If close to old blue value
                    curr_trial_data.eels(e).reliability = 0.4;
                elseif abs(current_rel - 0.15) < 0.01  % If close to old purple value
                    curr_trial_data.eels(e).reliability = 0.05;
                end
            elseif isequal(curr_trial_data.eels(e).eel_col, [157, 0, 255])  % Purple eel
                if abs(current_rel - 0.3) < 0.01  % If close to old blue value
                    curr_trial_data.eels(e).reliability = 0.4;
                elseif abs(current_rel - 0.15) < 0.01  % If close to old purple value
                    curr_trial_data.eels(e).reliability = 0.05;
                end
            end
            
            fprintf('  - Updated eel %d reliability\n', e);
        end
        
        % Save the updated trial data back to the file
        save(trial_path, 'curr_trial_data');
        
    catch err
        warning('Error processing %s: %s', trial_files(i).name, err.message);
    end
end

fprintf('\nUpdate complete. Modified reliabilities in all trials.\n');

%% Verification (Optional)
% Let's verify a random trial to confirm the changes

try
    % Choose a random trial to verify
    verify_idx = randi(num_trials);
    verify_path = fullfile(data_directory, trial_files(verify_idx).name);
    
    fprintf('\nVerifying random trial: %s\n', trial_files(verify_idx).name);
    
    % Load the updated trial
    load(verify_path, 'curr_trial_data');
    
    % Display reliability values
    for e = 1:length(curr_trial_data.eels)
        eel_color = curr_trial_data.eels(e).eel_col;
        if isequal(eel_color, [0, 0, 255])
            color_name = 'Blue';
        elseif isequal(eel_color, [157, 0, 255])
            color_name = 'Purple';
        else
            color_name = 'Unknown';
        end
        
        reliability = curr_trial_data.eels(e).reliability;
        fprintf('  - %s eel has reliability: %.3f\n', color_name, reliability);
    end
catch
    fprintf('Verification failed.\n');
end