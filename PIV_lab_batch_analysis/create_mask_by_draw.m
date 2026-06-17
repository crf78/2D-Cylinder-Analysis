function mask = create_mask_by_draw(video_file, ROI, calibration, bucket_diam, num_cylinders)

    % ============================================================
    % MANUAL MASK CREATION
    % Draw mask(s) by hand using the mouse
    % ============================================================

    % Add project path
    project_root = fileparts(fileparts(mfilename('fullpath')));
    addpath(genpath(project_root))

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

    % Read first frame
    frame1 = readFrame(video_obj);

    % Convert to grayscale if RGB
    if size(frame1,3) == 3
        frame1 = rgb2gray(frame1);
    end

    % Improve contrast
    frame1 = imadjust(frame1);

    % ------------------------------------------------------------
    % CREATE ROI MASK
    % ------------------------------------------------------------

    [ny, nx] = size(frame1);

    roi_mask = false(ny, nx);

    x1 = round(ROI(1));
    y1 = round(ROI(2));
    w  = round(ROI(3));
    h  = round(ROI(4));

    x2 = x1 + w - 1;
    y2 = y1 + h - 1;

    roi_mask(y1:y2, x1:x2) = true;

    % Apply ROI mask
    frame_double = im2double(frame1);

    frame_masked = frame_double;
    frame_masked(~roi_mask) = 0;

    % ------------------------------------------------------------
    % MANUAL MASK DRAWING
    % ------------------------------------------------------------

    figure('Name','Draw Manual Circle Mask')

    imshow(frame_masked, [])
    title({'Draw circle mask by hand', ...
       'Click and drag to size the circle', ...
       'Double-click inside circle to confirm'})

    hold on

    % Initialize empty mask
    mask = false(size(frame1));

    keep_drawing = true;

    while keep_drawing

    % Draw circle manually
    h_circle = drawcircle('Color','r','LineWidth',2);

    % Wait until circle placement finished
    wait(h_circle);

    % Convert circle to mask
    current_mask = createMask(h_circle);

    % Add to combined mask
    mask = mask | current_mask;

    % Show mask boundary
    visboundaries(mask,'Color','g','LineWidth',1)

    % Ask if another circle should be added
    choice = questdlg('Add another circle?', ...
                      'Continue?', ...
                      'Yes','No','No');

    if strcmp(choice,'No')
        keep_drawing = false;
    end

    end

    % ------------------------------------------------------------
    % CLEAN MASK
    % ------------------------------------------------------------
    % 
    % % Fill holes
    % mask = imfill(mask,'holes');
    % 
    % % Remove tiny regions if desired
    % mask = bwareaopen(mask,500);

    % ------------------------------------------------------------
    % DISPLAY FINAL RESULT
    % ------------------------------------------------------------

    figure('Name','Final Manual Mask')

    imshow(mask, [])
    hold on

    % visboundaries(mask,'Color','r','LineWidth',1.5)

    title('Final Manual Mask')

end