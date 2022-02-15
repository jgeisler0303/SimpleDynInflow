home_dir= fileparts(mfilename('fullpath'));
addpath(genpath(fullfile(home_dir, '..')))

cd(home_dir)

optDynInflowModel
plot_example_steps_paper
plot_result_steps_paper

% cd(fullfile(home_dir, '..', 'examlpe_data', 'sim'))
% !make
plot_result_sim_paper
