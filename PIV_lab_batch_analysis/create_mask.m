function mask = create_mask(video_file, ROI, calibration, bucket_diam, num_cylinders)

    % ============================================================
    % Command-line PIVlab processing for AVI/MOV video files
    % ============================================================
    % Add PIVlab to path
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
    if size(frame1,3) == 3
        frame1 = rgb2gray(frame1);
    end

    frame1 = imadjust(frame1); % 1% of data at extremes % or histeq, adapthisteq

    % ------------------------------------------------------------
    % CREATE ROI MASK
    % ------------------------------------------------------------

    [ny, nx] = size(frame1);
    mask = zeros(ny, nx);

    x1 = round(ROI(1)); y1 = round(ROI(2));
    w  = round(ROI(3)); h  = round(ROI(4));

    x2 = x1 + w - 1; y2 = y1 + h - 1;
    mask(y1:y2, x1:x2) = 1;

    % Apply mask
    % Convert to double
    frame_double = im2double(frame1);
    frame_masked = frame_double;
    frame_masked(~mask) = 0;

    % ========================================================
    % AUTOMATIC CYLINDER MASK
    % =========================================================

    % Smooth particles/noise
    frame_blur = imgaussfilt(frame_masked, 3);

    % Threshold
    % Adjust depending on cylinder brightness
    radius_low = (bucket_diam * (1/calibration)*(1000))*0.5-50;
    radius_high = (bucket_diam * (1/calibration)*(1000))*0.5+50;
    [centers, radii] = imfindcircles(frame_blur,[round(radius_low) round(radius_high)] ,'ObjectPolarity','dark'); %range in radius

    [X,Y] = meshgrid(1:size(frame1,2),1:size(frame1,1));

    % Initialize combined mask
    mask_inpt = false(size(frame1));

    % ---------------------------------------------------------
    % LOOP THROUGH ALL DETECTED CIRCLES
    % ---------------------------------------------------------
    for k = 1:num_cylinders

        % Create mask for current circle
        current_mask = (X - centers(k,1)).^2 + ...
                   (Y - centers(k,2)).^2 <= radii(k).^2;

        % Add to combined mask
        mask_inpt = mask_inpt | current_mask;

    end

    % ---------------------------------------------------------
    % CLEAN MASK
    % ---------------------------------------------------------

    % Remove tiny particle regions
    mask_inpt = bwareaopen(mask_inpt, 500);

    % Fill interior holes
    mask_inpt = imfill(mask_inpt, 'holes');

    % Optional:
    % Remove this section if you want ALL circles kept.
    %
    % Keep largest object only
    % cc = bwconncomp(mask_inpt);
    % numPixels = cellfun(@numel, cc.PixelIdxList);
    % [~, idx] = max(numPixels);
    % mask_clean = false(size(mask_inpt));
    % mask_clean(cc.PixelIdxList{idx}) = true;
    % mask = mask_clean;

    % Keep all circles
    mask = mask_inpt;

    % ---------------------------------------------------------
    % DISPLAY RESULT
    % ---------------------------------------------------------
    figure
    imshow(frame_masked, [])
    hold on

    % Show detected circles
    viscircles(centers, radii, 'Color', 'g');

    % Show mask boundaries
    visboundaries(mask, 'Color', 'r', 'LineWidth', 1)

    title('Automatic Cylinder Mask')
    
end