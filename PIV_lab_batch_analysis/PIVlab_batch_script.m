%script to call whatever videos/images you want analyzed

clc
clear
close all
restoredefaultpath;
tic;

% Add PIVlab to MATLAB path
% Project root
project_root = 'D:\hydroponics_PIV\test_PIV_command';

% Add PIVlab toolbox
addpath(genpath(fullfile(project_root,'PIVlab')))

rehash toolboxcache

% Folders containing videos
folders = {
 'D:\hydroponics_PIV\test_PIV_command\test_if_vortex_present\64_porosity_1_cylinder',...
 'D:\hydroponics_PIV\test_PIV_command\test_if_vortex_present\81_porosity_1_cylinder'
};

disp(path)

% Processing settings
calibration = 1/6.39;   % mm/pixel
dt = 1/30;            % seconds between frames
interrogationarea = 64;
smooth = 0;            % true or false (0 or 1)
smoothfactor = 50;     % any positive scalar
ROI = [40,370, 1880, 360];%[1, 210, 1919, 670]; % [] means: use the full image. Otherwise: [x, y, width, height]
MASK = [];
graph_results = 1; % true or false (0 or 1)
bucket_diam = 0.03; %m
interp = 1;
num_cylinders = 1;
matfile_exist = 0; 

% Loop through folders
for i = 1:length(folders)
    current_folder = folders{i};
    fprintf('Processing folder:\n%s\n', current_folder)

    % Find AVI and MOV files
    avi_files = dir(fullfile(current_folder, '*.avi'));
    mov_files = dir(fullfile(current_folder, '*.mov'));
    video_files = [avi_files; mov_files];

    % Skip empty folders
    if isempty(video_files)
        warning('No video files found in:\n%s', current_folder)
        continue
    end

    % Process each video
    for j = 1:length(video_files)
        video_name = video_files(j).name;
        video_path = fullfile(current_folder, video_name);
        fprintf('\nProcessing video %d of %d:\n%s\n', ...
            j, length(video_files), video_name)
        % Create save name
        [~, base_name, ~] = fileparts(video_name);

        save_name = fullfile( ...
            current_folder, ...
            [base_name '_PIVlab.mat']);

        try %try to analyze the video
        % Create mask

        if ~matfile_exist %if the .mat file does not exist, then run the PIV analysis

        if num_cylinders > 0
            MASK = create_mask_emma(video_path, ROI, calibration, bucket_diam, num_cylinders); 
        end

        % Run PIV analysis
        results = run_PIV_analysis( ...
            video_path, ...
            calibration, ...
            dt, ...
            ROI, ...
            MASK,...
            interrogationarea,...
            smooth,...
            smoothfactor);

        % Save like native PIVlab format
        save(save_name, '-struct', 'results', '-v7.3')
        fprintf('Saved:\n%s\n', save_name)

        else
            results = load(save_name);
        end

        if graph_results && num_cylinders == 0 % freeflow
            graph_u_vel_y_direction(...
                results.u_original, ...
                results.v_original, ...
                results.vorticity, ...
                results.x, ...
                results.y, ...
                bucket_diam, ...
                interp, ...
                current_folder, ...
                base_name)
        elseif graph_results && num_cylinders == 1 % one cylinder
            graph_one_bucket(...
                results.u_original,...
                results.u_smoothed,...
                results.v_smoothed, ...
                results.vorticity,...
                results.x, results.y, ...
                bucket_diam,...
                interp,...
                current_folder, ...
                base_name)
        elseif graph_results && num_cylinders == 2 %two cylinders
            graph_two_buckets(...
                results.u_original,...
                results.u_smoothed,...
                results.v_smoothed,...
                results.vorticity,...
                results.x, results.y, ...
                bucket_diam,...
                interp,...
                current_folder,...
                base_name)
        end

        clf; close all; 


        catch % ME if the PIV doesn't work for some reason, display message and continue to the rest of the videos
            fprintf('\n PROBLEM WITH VIDEO %d of %d:\n%s\n', ...
                j, length(video_files), video_name)
        end

    end
end

disp('All processing finished.')
toc;
%script to call whatever videos/images you want analyzed