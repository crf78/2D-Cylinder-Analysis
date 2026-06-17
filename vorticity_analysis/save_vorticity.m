clc; clear;
% Specify the parent directory containing the folders
parentDirectory = 'I:\high_flow\no_blockage\81_porosity_1_cylinder';
bucket_diam = 0.03;
% u_in = 0.0148; % m/s flow A
% u_in = 0.0152; % m/s flow B
% u_in = 0.0049; % m/s flow C
% u_in = 0.002; % m/s flow D
% u_in = 0.0062; %5V
% u_in = 0.0078; %12V
u_in = 0.02;
% Get a list of all items in the parent directory
items = dir(parentDirectory);
j = 0;
compiled_parameters = {};

Cmap1 = winter(5);
figure()

% Iterate through all items
for i = 1:length(items)
    % Check if the item is a folder (excluding '.' and '..')
    if  ~items(i).isdir && endsWith(items(i).name, '.mat')
        % Construct the path to the current folder
        filePath = fullfile(parentDirectory, items(i).name);

            % Load the .mat file
                data = load(filePath);

                j =  j + 1; 
                if j == 1
                    make_vorticity_video(data.x, data.y, data.vorticity, data.u_original, data.v_original, bucket_diam, u_in, parentDirectory, j)
                end
                % [x, min_vort, max_vort] = get_vorticity(data.x, data.y, data.vorticity, data.u_original, bucket_diam, Cmap1(j, :), u_in); 
                % compiled_parameters{j, 1} = items(i).name;
                % compiled_parameters{j, 2} = x;
                % compiled_parameters{j, 3} = min_vort;
                % compiled_parameters{j, 4} = max_vort;

    end
end
% xline(0, '--', LineWidth=1.5, HandleVisibility='off')
% legend('36% solid', '27% solid', '23% solid', '19% solid', 'Solid')
% xlabel('x/D')
% ylabel('\omega')
% title('Vorticity Envelope')
% ylim([-3 3]); fontsize(14, 'points');
% saveas(gcf, 'vorticity_plot.fig')
% saveas(gcf, 'vorticit_plot.png')

Re_num = (u_in*1000*bucket_diam)/ (10^-3);
% 
% save vorticity_param.mat compiled_parameters Re_num 

function [final_x, min_vort_pos, max_vort_neg] = get_vorticity(x, y, vorticity, u_original, bucket_diam, linecolor, u_in)
numInterp = 2; % Change this number for finer or coarser mesh.
X = interp2(x{1,1}, numInterp);
Y = interp2(y{1,1}, numInterp);

numInterp = 2;
vort_phaseAvg = cellfun(@(x) interp2(x, numInterp), vorticity, 'UniformOutput', false);
u_phaseAvg = cellfun(@(x) interp2(x, numInterp), u_original, 'UniformOutput', false);
[new_bucket_A, new_bucket_edge, new_bucket_center] = locate_NAN(u_phaseAvg{1,1});
mask_temp = ones(size(vort_phaseAvg{1,1}));
mask_temp(sub2ind(size(vort_phaseAvg{1,1}),new_bucket_A(:, 1), new_bucket_A(:, 2))) = NaN;

%time-averaged
vort_stackedData = cat(3, vort_phaseAvg{:});
non_dim_vort_stacked = vort_stackedData ;%.* (bucket_diam/u_in);
vort_meanMatrix = mean(non_dim_vort_stacked, 3, 'omitnan');
vort_SDMatrix = std(non_dim_vort_stacked, 0, 3, 'omitnan');
vort_SEMatrix = vort_SDMatrix./ sqrt(length(vort_phaseAvg)); %STANDARD ERROR

%post-process (look pretty :))
x_ = (X - X(1, new_bucket_center(1, 2)))./bucket_diam; 
y_ = (Y - Y(new_bucket_center(1, 1), 1))./bucket_diam; 
bucket_x = x_(sub2ind(size(x_), new_bucket_edge(: , 1), new_bucket_edge(:, 2)));
bucket_y = y_(sub2ind(size(y_), new_bucket_edge(: , 1), new_bucket_edge(:, 2)));

pos_half = vort_meanMatrix(1:new_bucket_center(1, 1), :); 
min_vort_pos = min(pos_half, [], 1, 'omitnan');

neg_half = vort_meanMatrix(new_bucket_center(1, 1)+1:end, :); 
max_vort_neg = max(neg_half, [], 1, 'omitnan');

plot(x_(1, :), smooth(max_vort_neg), '-', Color=linecolor, LineWidth = 1.5); hold on;
plot(x_(1, :), smooth(min_vort_pos), '-', Color=linecolor, LineWidth = 1.5, HandleVisibility='off'); hold on;
final_x = x_(1, :); 
end

function make_vorticity_video(x, y, vorticity, u_original, v_original, bucket_diam, u_in, folderPath, j)
% u_interp = imresize(u_original{1, 1}, [NaN 1880], 'nearest');

u_interm = cellfun(@(x) imresize(x,[NaN 1880], 'nearest'), u_original, ...
                   'UniformOutput', false);
v_interm = cellfun(@(x) imresize(x,[NaN 1880], 'nearest'), v_original, ...
                   'UniformOutput', false);
one_frame = u_interm{1, 1};
num_rows = length(one_frame(:, 1));
num_columns = length(one_frame); 
numInterp = 1;
X = interp2(x{1,1}, numInterp);
Y = interp2(y{1,1}, numInterp);

vort_interp = cellfun(@(x) interp2(x, numInterp), ...
    vorticity, 'UniformOutput', false);

u_interp = cellfun(@(x) interp2(x, numInterp), ...
    u_original, 'UniformOutput', false);

v_interp = cellfun(@(x) interp2(x, numInterp), ...
    v_original, 'UniformOutput', false);

% % CREATE MASK
% [new_bucket_A, new_bucket_edge, new_bucket_center] = ...
%     locate_NAN(u_interp{1,1});
% 
% mask_temp = ones(size(vort_interp{1,1}));
% 
% mask_temp(sub2ind(size(vort_interp{1,1}), ...
%     new_bucket_A(:,1), new_bucket_A(:,2))) = NaN;

% NON-DIMENSIONALIZE COORDINATES
x_ = X./ bucket_diam; %(X - X(1, new_bucket_center(1,2))) ./ bucket_diam;
y_ = Y./ bucket_diam; %(Y - Y(new_bucket_center(1,1), 1)) ./ bucket_diam;

% GLOBAL COLOR LIMITS
all_data = cat(3, vort_interp{:});
maxVal = max(abs(all_data(:)), [], 'omitnan');

% CREATE VIDEO
% video = VideoWriter([folderPath,'\vorticity_video.mp4'], 'MPEG-4');
video = VideoWriter([folderPath,'\vort_field_video_',num2str(j), '.mp4'], 'MPEG-4');
video.FrameRate = 10;

open(video);

% CUSTOM COLORMAP
cmap = create_colormap(256);

% FIGURE
figure;

for k = 1:length(vort_interp)
    clf;
    current_vort = vort_interp{k};
    imagesc(x_(1,:), y_(:,1), current_vort);
    % contour(x_, y_, current_vort,7, LineWidth= 2); 
    % current_u = u_interp{k};
    % current_v = v_interp{k};
    % quiver(x_, y_, current_u, current_v, 5);
    axis equal;
    axis tight;
    colormap(cmap);
    % IMPORTANT: keep limits fixed for all frames
    clim([-maxVal*0.75 maxVal*0.75]);
    colorbar;
    title(['Vorticity Frame ', num2str(k)]);
    xlabel('$y/D_b$', 'Interpreter','latex');
    ylabel('$x/D_b$', 'Interpreter','latex');

    % title('Streamlines');
    % l = streamslice(current_u, current_v); hold on;
    % set(l,'LineWidth',1.5)
    % set(l,'Color','b');
    % axis equal
    % ylim([1 length(current_u(:, 1))]); xlim([1 length(current_u)])

    drawnow;
    % Capture frame
    frame = getframe(gcf);

    % Write frame
    writeVideo(video, frame);

end

% CLOSE VIDEO
close(video);

disp('Video creation complete!');

end

function [bucket_A, edge_A, A_center] = locate_NAN(sample)
    %sample = data{1};

    %Find the NaN elements
    nanMask = isnan(sample); %assume the Nan values do not move (same for each frame)

    %Initialize an edge mask
    edgeMask = false(size(sample));

    %Check for edges in all four directions (left, right, up, down)
    edgeMask(:, 1:end-1) = edgeMask(:, 1:end-1) | (nanMask(:, 1:end-1) & ~nanMask(:, 2:end)); % Right edges
    edgeMask(:, 2:end)   = edgeMask(:, 2:end)   | (nanMask(:, 2:end) & ~nanMask(:, 1:end-1)); % Left edges
    edgeMask(1:end-1, :) = edgeMask(1:end-1, :) | (nanMask(1:end-1, :) & ~nanMask(2:end, :)); % Down edges
    edgeMask(2:end, :)   = edgeMask(2:end, :)   | (nanMask(2:end, :) & ~nanMask(1:end-1, :)); % Up edges

    %Get the locations of edge elements
    [edgeRows, edgeCols] = find(edgeMask);
    nan_loc = [edgeRows, edgeCols];

    % Get row and column indices of NaNs
    [rowIdx, colIdx] = find(nanMask);

    bucket_A(:, 1) = rowIdx(1:end); bucket_A(:, 2) = colIdx(1:end);

    % Compute approximate center
    A_center(1, 1) = round(mean(bucket_A(:, 1))); A_center(1, 2) = round(mean(bucket_A(:, 2)));

    %find the location difference of both buckets and their center
    edge_A(:, 1) = nan_loc(:, 1); edge_A(:, 2) = nan_loc(:, 2);

    %Display the results
    disp('Edge locations of NaN clusters for A Bucket:');
    disp(bucket_A);

    % figure;
    % imagesc(sample); colormap('parula'); colorbar;
    % hold on;
    % plot(edge_A(:, 2), edge_A(:, 1), 'k.', 'MarkerSize', 15);
    % plot(A_center(1, 2), A_center(1, 1), 'r*', 'MarkerSize', 15);
    % title('Edge Locations of NaN Clusters (new)');
    % axis equal; %ylim([-1 1])
    % hold off;
    % legend('Bucket A');
    %saveas(gcf, 'edges_graph.fig')

end

function cust_colormap = create_colormap(num_rows)

    red   = [1 0 0];
    white = [1 1 1];
    blue  = [0 0 1];

    n1 = floor(num_rows/2);
    n2 = num_rows - n1;

    t1 = linspace(0,1,n1)';
    cmap1 = (1-t1).*red + t1.*white;

    t2 = linspace(0,1,n2)';
    cmap2 = (1-t2).*white + t2.*blue;

    cust_colormap = [cmap1; cmap2];

end