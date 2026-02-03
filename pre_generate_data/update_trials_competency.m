%% Update Trials: Scale Competency Values
% This script loads each trial file and scales either high or low competency values

clear; close all; clc;

%% Setup Parameters
SCALE_LOW_COMP = true;  % Set to true to scale low competency, false to scale high
SCALING_FACTOR = 4;   % 50% reduction

% Original competency values for reference
ORIGINAL_LOW_COMP = 0.04;
ORIGINAL_HIGH_COMP = 0.65;

%% Setup Paths
currentFolder = pwd;
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
if SCALE_LOW_COMP
    fprintf('Scaling low competency values by factor %.2f\n', SCALING_FACTOR);
else
    fprintf('Scaling high competency values by factor %.2f\n', SCALING_FACTOR);
end

%% Process Each Trial
for i = 1:num_trials
    % Load the trial data
    trial_path = fullfile(data_directory, trial_files(i).name);
    fprintf('Processing %s (%d/%d)\n', trial_files(i).name, i, num_trials);
    
    try
        load(trial_path, 'curr_trial_data');
        
        % Update each eel's competency
        for e = 1:length(curr_trial_data.eels)
            current_comp = curr_trial_data.eels(e).competency;
            
            % Determine if this is a low or high competency value
            % Use a tolerance to account for noise
            is_low_comp = abs(current_comp - ORIGINAL_LOW_COMP) < ...
                abs(current_comp - ORIGINAL_HIGH_COMP);
            
            % Scale the competency if it matches our target type
            if SCALE_LOW_COMP && is_low_comp
                % Scale low competency
                curr_trial_data.eels(e).competency = current_comp * SCALING_FACTOR;
                fprintf('  - Scaled low competency from %.3f to %.3f\n', ...
                    current_comp, curr_trial_data.eels(e).competency);
            elseif ~SCALE_LOW_COMP && ~is_low_comp
                % Scale high competency
                curr_trial_data.eels(e).competency = current_comp * SCALING_FACTOR;
                fprintf('  - Scaled high competency from %.3f to %.3f\n', ...
                    current_comp, curr_trial_data.eels(e).competency);
            end
            
            % Ensure competency stays within valid range [0,1]
            curr_trial_data.eels(e).competency = ...
                min(max(curr_trial_data.eels(e).competency, 0), 1);
        end
        
        % Save the updated trial data back to the file
        save(trial_path, 'curr_trial_data');
        
    catch err
        warning('Error processing %s: %s', trial_files(i).name, err.message);
    end
end

fprintf('\nUpdate complete. Modified competencies in all trials.\n');

%% Verification (Optional)
% Verify a random trial to confirm the changes

try
    % Choose a random trial to verify
    verify_idx = randi(num_trials);
    verify_path = fullfile(data_directory, trial_files(verify_idx).name);
    
    fprintf('\nVerifying random trial: %s\n', trial_files(verify_idx).name);
    
    % Load the updated trial
    load(verify_path, 'curr_trial_data');
    
    % Display competency values
    for e = 1:length(curr_trial_data.eels)
        eel_color = curr_trial_data.eels(e).eel_col;
        if isequal(eel_color, [0, 0, 255])
            color_name = 'Blue';
        elseif isequal(eel_color, [157, 0, 255])
            color_name = 'Purple';
        else
            color_name = 'Unknown';
        end
        
        competency = curr_trial_data.eels(e).competency;
        fprintf('  - %s eel has competency: %.3f\n', color_name, competency);
    end
catch
    fprintf('Verification failed.\n');
end