function results = run_piv_analysis( ...
    video_file, ...
    calxy, ...
    dt, ...
    roi_inpt,...
    mask_inpt,...
    interrogationarea,...
    smoothFrames,...
    smoothFactor)

% ============================================================
% Command-line PIVlab processing for AVI/MOV video files
% ============================================================

% % Add PIVlab to path
% project_root = fileparts(mfilename('fullpath'));
% 
% addpath(genpath(fullfile(project_root,'PIVlab')))
% rehash toolboxcache

% Check video exists
if ~isfile(video_file)
    error('Video file not found.')
end
disp(['Loading video: ' video_file])

% Create video reader
video_obj = VideoReader(video_file);

% Total frames
num_frames = floor(video_obj.Duration * video_obj.FrameRate);
disp(['Video contains ' num2str(num_frames) ' frames'])

% Need at least 2 frames
if num_frames < 2
    error('Video must contain at least 2 frames.')
end

% Number of PIV pairs
num_pairs = num_frames - 1;
disp(['Processing ' num2str(num_pairs) ' frame pairs'])

% ============================================================
% PREPROCESSING SETTINGS
% ============================================================

% roi_inpt = [];
clahe = 1;
clahesize = 64;
highp = 0; % HIGH PASS VECTOR FIELD, CAN CHANGE IF YOU WANT
highpsize = 15;
intenscap = 0;
wienerwurst = 0;
wienerwurstsize = 3;
minintens = 0.0;
maxintens = 1.0;

% ============================================================
% PIV SETTINGS
% ============================================================

step = interrogationarea / 2;
subpixfinder = 1;
% mask_inpt = [];
passes = 2;
int2 = interrogationarea / 2; % CAN CHANGE IF YOU WANT
int3 = interrogationarea / 4;
int4 = interrogationarea / 4;

imdeform = '*linear';
repeat = 0;
mask_auto = 0;
do_linear_correlation = 0;
repeat_last_pass = 0;
delta_diff_min = 0.025;
limit_peak_search_area = 1;

% ============================================================
% POSTPROCESSING SETTINGS
% ============================================================

% Convert pixels/frame --> physical units/second
calxy = calxy*0.001; %change from mm to m; 
calu = calxy / dt;
calv = calxy / dt;
valid_vel = [-50; 50; -50; 50]; %PROBABLY A GOOD RANGE, FROM THE ORIGINAL COMMANDLINE SCRIPT

do_stdev_check = 1;
stdthresh = 7;
do_local_median = 1;
neigh_thresh = 3;
paint_nan = 1;

% ============================================================
% PREALLOCATE VARIABLES
% ============================================================

x = []; y = [];
u = []; v = [];

u_filt = []; v_filt = [];

typevector = [];
typevector_filt = [];
correlation_map = [];

% ============================================================
% RESET VIDEO TO START
% ============================================================

video_obj.CurrentTime = 0;

% Read first frame
frame1 = readFrame(video_obj);
if size(frame1,3) == 3
    frame1 = rgb2gray(frame1);
end

% ============================================================
% MAIN LOOP
% ============================================================
h = waitbar(0, 'Please wait...');
for pair_idx = 1:num_pairs
    % elapsed_time = toc;
    percent_done = pair_idx / num_pairs;
    waitbar(percent_done, h); %PROGRESS BAR, CAN COMMENT OUT IF YOU DON'T WANT.

    % fprintf('\rProgress: %6.2f %% | Elapsed: %s', ...
    %     percent_done * 100, ...
    %     datestr(seconds(elapsed_time),'HH:MM:SS'));

    % Read next frame
    frame2 = readFrame(video_obj);
    if size(frame2,3) == 3
        frame2 = rgb2gray(frame2);
    end
    % Convert to double
    image1_raw = im2double(frame1);
    image2_raw = im2double(frame2);

    % ========================================================
    % PREPROCESSING
    % =========================================================

    image1_preprocessed = preproc.PIVlab_preproc( ...
        in=image1_raw, ...
        roirect=roi_inpt, ...
        clahe=clahe, ...
        clahesize=clahesize, ...
        highp=highp, ...
        highpsize=highpsize, ...
        intenscap=intenscap, ...
        wienerwurst=wienerwurst, ...
        wienerwurstsize=wienerwurstsize, ...
        minintens=minintens, ...
        maxintens=maxintens);

    image2_preprocessed = preproc.PIVlab_preproc( ...
        in=image2_raw, ...
        roirect=roi_inpt, ...
        clahe=clahe, ...
        clahesize=clahesize, ...
        highp=highp, ...
        highpsize=highpsize, ...
        intenscap=intenscap, ...
        wienerwurst=wienerwurst, ...
        wienerwurstsize=wienerwurstsize, ...
        minintens=minintens, ...
        maxintens=maxintens);

    % ========================================================
    % PIV ANALYSIS
    % =========================================================

    [x(:,:,pair_idx), y(:,:,pair_idx), ...
        u(:,:,pair_idx), v(:,:,pair_idx), ...
        typevector(:,:,pair_idx), ...
        correlation_map(:,:,pair_idx)] = piv.piv_FFTmulti( ...
        image1=image1_preprocessed, ...
        image2=image2_preprocessed, ...
        interrogationarea=interrogationarea, ...
        step=step, ...
        subpixfinder=subpixfinder, ...
        mask_inpt=mask_inpt, ...
        roi_inpt=roi_inpt, ...
        passes=passes, ...
        int2=int2, ...
        int3=int3, ...
        int4=int4, ...
        imdeform=imdeform, ...
        repeat=repeat, ...
        mask_auto=mask_auto, ...
        do_linear_correlation=do_linear_correlation, ...
        repeat_last_pass=repeat_last_pass, ...
        delta_diff_min=delta_diff_min, ...
        limit_peak_search_area=limit_peak_search_area);

    % ========================================================
    % POSTPROCESSING
    % =========================================================

    [u_filt(:,:,pair_idx), ...
        v_filt(:,:,pair_idx)] = postproc.PIVlab_postproc( ...
        u=u(:,:,pair_idx), ...
        v=v(:,:,pair_idx), ...
        calu=calu, ...
        calv=calv, ...
        valid_vel=valid_vel, ...
        do_stdev_check=do_stdev_check, ...
        stdthresh=stdthresh, ...
        do_local_median=do_local_median, ...
        neigh_thresh=neigh_thresh);


    % Track filtered vectors
    typevector_filt_slice = typevector(:,:,pair_idx);
    typevector_filt_slice(isnan(u_filt(:,:,pair_idx))) = 2;
    typevector_filt_slice(isnan(v_filt(:,:,pair_idx))) = 2;
    typevector_filt_slice(typevector(:,:,pair_idx) == 0) = 0;
    typevector_filt(:,:,pair_idx) = typevector_filt_slice;

    % Fill NaNs
    if paint_nan
        u_filt(:,:,pair_idx) = ...
            misc.inpaint_nans(u_filt(:,:,pair_idx),4);
        v_filt(:,:,pair_idx) = ...
            misc.inpaint_nans(v_filt(:,:,pair_idx),4);
    end

    % Shift frames
    frame1 = frame2;

end
close(h);

% Keep masked regions NaN
u_filt(typevector == 0) = NaN;
v_filt(typevector == 0) = NaN;
disp('Done processing the vector field.')

% =========================
% DERIVED QUANTITIES
% -look in \PIVlab\+plot\derivative_calc.m to see the original calc
% ==========================


velocity_magnitude = sqrt(u_filt.^2 + v_filt.^2);
vectorangle = atan2(v_filt, u_filt);

% Preallocate
shear_rate = nan(size(u_filt));
strain_rate = nan(size(u_filt));
diver = nan(size(u_filt));

results = struct(); % SAVE %

for k = 1:size(u_filt,3)
    X = x(:,:,k);
    Y = y(:,:,k);

    %The direction of the coordinate system influences derivatives with gradients.
    % ENSURE X IS INCREASING LEFT --> RIGHT
    if mean(diff(X(1,:))) < 0
    X = fliplr(X);
    end
    % ENSURE Y IS INCREASING BOTTOM --> TOP
    if mean(diff(Y(:,1))) < 0
    Y = flipud(Y);
    end

    if smoothFrames
        U = misc.smoothn(u_filt(:,:,k),smoothFactor/10)*calu;
        V = misc.smoothn(v_filt(:,:,k),smoothFactor/10)*calv;
    else
        U = u_filt(:,:,k)*calu;
        V = v_filt(:,:,k)*calv;
    end

    % Vorticity
    [curlz,~]= curl(X*calxy,Y*calxy,U*calu,V*calv);

    % Shear rate
    shear_rate(:,:,k) = plot.shear(X*calxy,Y*calxy,U*calu,V*calv);

    % Strain rate magnitude
    strain_rate(:,:,k) = plot.strain(X*calxy,Y*calxy,U*calu,V*calv);

    % Divergence
    diver(:,:,k) = divergence(X*calxy,Y*calxy,U*calu,V*calv);

    % SAVE %
    % Coordinates
    results.x{k, 1} = X.*calxy;
    results.y{k, 1} = Y.*calxy;
    results.u_original{k, 1} = u(:,:,k).*calu;
    results.v_original{k, 1} = v(:,:,k).*calv;

    % Filtered
    results.u_filtered{k, 1} = u_filt(:,:,k);
    results.v_filtered{k, 1} = v_filt(:,:,k);

    % Smoothed / component
    results.u_smoothed{k, 1} = U;
    results.v_smoothed{k, 1} = V;

    results.u_component{k, 1} = u(:,:,k); %same as u_original
    results.v_component{k, 1} = v(:,:,k);

    % Type vectors
    results.typevector_original{k, 1} = typevector(:,:,k);
    results.typevector_filtered{k, 1} = typevector_filt(:,:,k);

    % Correlation
    results.correlation_map{k, 1} = correlation_map(:,:,k);

    % Derived fields
    results.vorticity{k, 1} = -curlz;
    results.shear_rate{k, 1} = shear_rate(:,:,k);
    results.strain_rate{k, 1} = strain_rate(:,:,k);
    results.divergence{k, 1} = diver(:,:,k);

    results.velocity_magnitude{k, 1} = velocity_magnitude(:,:,k);
    results.vectorangle{k, 1} = vectorangle(:,:,k);
end
disp('Derived parameter calculations finished.')

disp('Processing finished.')

% =========================
% BUILD PIVLAB-LIKE SAVE STRUCTURE
% ==========================

% Calibration
results.calu = calu;
results.calv = calv;
results.calxy = calxy;

% Metadata
results.information = struct();
results.information.interrogationarea = interrogationarea;
results.information.calibration = calxy;
results.information.dt = dt;
results.information.process_date = datestr(now);

disp('Save finished.')

end %end main function