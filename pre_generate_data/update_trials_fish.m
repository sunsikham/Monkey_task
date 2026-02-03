%% Update Trials: Remove 2 Fish per Eel
% This script loads each trial file, removes 2 fish from each eel, and saves the updated trial

clear; close all; clc;

%% Setup Paths
currentFolder = pwd; % Use current directory
data_directory = fullfile(currentFolder, 'pre_generate_data', 'data', 'premade_trials');

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
        
        % Update each eel's fish data
        for e = 1:length(curr_trial_data.eels)
            % Current number of fish
            current_fish = size(curr_trial_data.eels(e).fish_pos, 1);
            
            % Target number of fish (remove 2)
            target_fish = current_fish - 2;
            
            if target_fish < 1
                warning('Eel %d in trial %s has only %d fish. Cannot remove 2 fish. Skipping.', ...
                    e, trial_files(i).name, current_fish);
                continue;
            end
            
            % Choose random indices to keep (remove 2 random fish)
            keep_indices = randperm(current_fish, target_fish);
            
            % Update fish positions
            curr_trial_data.eels(e).fish_pos = curr_trial_data.eels(e).fish_pos(keep_indices, :);
            
            fprintf('  - Updated eel %d: Reduced fish from %d to %d\n', e, current_fish, target_fish);
        end
        
        % Save the updated trial data back to the file
        save(trial_path, 'curr_trial_data');
        
    catch err
        warning('Error processing %s: %s', trial_files(i).name, err.message);
    end
end

fprintf('\nUpdate complete. Removed 2 fish from each eel in all trials.\n');

%% Verification (Optional)
% Let's verify a random trial to confirm the changes

try
    % Choose a random trial to verify
    verify_idx = randi(num_trials);
    verify_path = fullfile(data_directory, trial_files(verify_idx).name);
    
    fprintf('\nVerifying random trial: %s\n', trial_files(verify_idx).name);
    
    % Load the updated trial
    load(verify_path, 'curr_trial_data');
    
    % Display fish counts
    for e = 1:length(curr_trial_data.eels)
        eel_color = curr_trial_data.eels(e).eel_col;
        if isequal(eel_color, [0, 0, 255])
            color_name = 'Blue';
        elseif isequal(eel_color, [157, 0, 255])
            color_name = 'Purple';
        else
            color_name = 'Unknown';
        end
        
        fish_count = size(curr_trial_data.eels(e).fish_pos, 1);
        fprintf('  - %s eel has %d fish\n', color_name, fish_count);
    end
catch
    fprintf('Verification failed.\n');
end