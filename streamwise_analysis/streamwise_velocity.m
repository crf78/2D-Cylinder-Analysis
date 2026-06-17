%author: Crystal Fowler
%purpose: import the .mat files for the matlab export of PIVLab data

%% Import the PIV with .mat files
main()
function main()
clc; clear;
matrix = load('DSC_7898_PIVlab.mat');
bucket_diam = 0.03; %m
u_in = 0.007; %5V m/s

% Import the PIV data with each frame as .txt file
sub_x=matrix.x{1,1};
x=sub_x(1, :);

%Integrate across the x direction
[edge_A, A_center] = locate_NAN(matrix);
middle_row = A_center(1, 1);
start_row = edge_A(1, 2); end_row = edge_A(end, 2);

num_frames = length(matrix.u_smoothed);
for i=1:num_frames
    curr_frame = matrix.u_smoothed{i};
    u_ave = curr_frame(middle_row, :);
    temp(i, :) = u_ave./u_in;
    %plot(u_ave./u_in, y./bucket_diam, '-'); hold on;
end

%Integrates across time
u_time_ave = mean(temp); 
u_time_se = std(temp)/sqrt(num_frames); 

%plots the u-velocity vector
figure()
non_dim_x = (x-x(end_row))./bucket_diam;
non_dim_y = (ylim-x(end_row))./bucket_diam;
% errorbar(non_dim_x(1:start_row), u_time_ave(1:start_row), u_std_error(1:start_row)); hold on;
% errorbar(non_dim_x(end_row:end), u_time_ave(end_row:end) , u_std_error(end_row:end));
fUp = u_time_ave + u_time_se; fLow = u_time_ave - u_time_se;

x2_before = [non_dim_x(1:start_row), fliplr(non_dim_x(1:start_row))];
x2_after = [non_dim_x(end_row:end), fliplr(non_dim_x(end_row:end))];
fill(x2_before, [u_time_ave(1:start_row), fliplr(fUp(1:start_row))], 0.7 * ones(1, 3), 'linestyle', 'none', 'facealpha', 0.4, 'HandleVisibility','off'); hold on;
fill(x2_before, [fLow(1:start_row), fliplr(u_time_ave(1:start_row))], 0.7 * ones(1, 3), 'linestyle', 'none', 'facealpha', 0.4, 'HandleVisibility','off'); hold on;
fill(x2_after, [u_time_ave(end_row:end), fliplr(fUp(end_row:end))], 0.7 * ones(1, 3), 'linestyle', 'none', 'facealpha', 0.4, 'HandleVisibility','off'); hold on;
fill(x2_after, [fLow(end_row:end), fliplr(u_time_ave(end_row:end))], 0.7 * ones(1, 3), 'linestyle', 'none', 'facealpha', 0.4, 'HandleVisibility','off'); hold on;

plot(non_dim_x(1:start_row), u_time_ave(1:start_row), '-o'); hold on;
plot(non_dim_x(end_row:end), u_time_ave(end_row:end), '-o'); hold on;

plot(ones(1, length(-0.25:0.25:1.25)).*non_dim_x(start_row), -0.25:0.25:1.25, '-k', LineWidth=1.5); hold on;
plot(ones(1, length(-0.25:0.25:1.25)).*non_dim_x(end_row), -0.25:0.25:1.25, '--k', LineWidth=1.5); hold off;
ylabel('$U / U_{\infty}$',Interpreter='latex', fontsize=15);
xlabel('$x / D_{b}$',Interpreter='latex', fontsize=15)
title('Streamwise Velocity Down the Channel')
xlim([non_dim_x(1) non_dim_x(end)]); ylim([-0.25 1.25]);

save streamwise_variables.mat end_row non_dim_x start_row u_in u_time_ave u_time_se

grid on; 
saveas(gcf, 'streamwise_vel.fig')
end

function [edge_A, A_center] = locate_NAN(data)
    sample = data.u_original{1};

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

    figure;
    imagesc(sample); colormap('parula'); colorbar;
    hold on;
    plot(edge_A(:, 2), edge_A(:, 1), 'k.', 'MarkerSize', 15);
    plot(A_center(1, 2), A_center(1, 1), 'r*', 'MarkerSize', 15);
    title('Edge Locations of NaN Clusters (new)');
    axis equal; %ylim([-1 1])
    hold off;
    legend('Bucket A');
    %saveas(gcf, 'edges_graph.fig')

end