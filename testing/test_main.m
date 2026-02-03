[visual_opt, device_opt, game_opt, eye_opt, save_directory] = initalize();
% Force dynamic trial generation
game_opt.premade_eels = false;
% Run the test
test_switching_logic(game_opt);