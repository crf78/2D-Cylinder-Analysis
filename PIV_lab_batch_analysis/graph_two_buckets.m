function graph_two_buckets(u_original, u_smoothed, v_smoothed, vorticity, X_all, Y_all, bucket_diam, numInterp, current_folder, video_name)
    
    %locate the two buckets:
    sample = u_original{1};
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

    
    %find the location difference of both buckets and their center
    for j=2:length(colIdx)
        diff = colIdx(j) - colIdx(j-1); 
        if diff > 5
            break;
        end
    end
    bucket_A(:, 1) = rowIdx(1:j); bucket_A(:, 2) = colIdx(1:j);
    bucket_B(:, 1) = rowIdx(j:end); bucket_B(:, 2) = colIdx(j:end);

    % Compute approximate center
    A_center(1, 1) = round(mean(bucket_A(:, 1))); A_center(1, 2) = round(mean(bucket_A(:, 2)));
    B_center(1, 1) = round(mean(bucket_B(:, 1))); B_center(1, 2) = round(mean(bucket_B(:, 2)));

    %find the location difference of both buckets and their center
    for l=2:length(nan_loc(:, 2))
        edge_diff = nan_loc(l, 2) - nan_loc(l-1, 2); 
        if edge_diff > 5
            break;
        end
    end
    edge_A(:, 1) = nan_loc(1:l-1, 1); edge_A(:, 2) = nan_loc(1:l-1, 2);
    edge_B(:, 1) = nan_loc(l:end, 1); edge_B(:, 2) = nan_loc(l:end, 2);

    middle_col = (A_center(1,2) + B_center(1, 2)) / 2;

    %Display the results
    % disp('Edge locations of NaN clusters for A Bucket:');
    % disp(bucket_A);
    % 
    % disp('Edge locations of NaN clusters for B Bucket:');
    % disp(bucket_B);

    %Optional: Visualize the array and the edges
    % figure;
    % imagesc(sample); colormap('parula'); colorbar;
    % hold on;
    % plot(edge_A(:, 2), edge_A(:, 1), 'k.', 'MarkerSize', 15);
    % plot(edge_B(:, 2), edge_B(:, 1), 'r.', 'MarkerSize', 15);
    % plot(A_center(1, 2), A_center(1, 1), 'r*', 'MarkerSize', 15);
    % plot(B_center(1, 2), B_center(1, 1), 'k*', 'MarkerSize', 15);
    % title('Edge Locations of NaN Clusters (old)');
    % axis equal; %ylim([-1 1])
    % hold off;
    % legend('Bucket A', 'Bucket B');
    %saveas(gcf, 'edges_graph.fig')


%-----------U_VEL-----------%
u_phaseAvg = cellfun(@(x) interp2(x, numInterp), u_smoothed, 'UniformOutput', false);
v_phaseAvg = cellfun(@(x) interp2(x, numInterp), v_smoothed, 'UniformOutput', false);
mask_temp = ones(size(u_phaseAvg{1,1}));
mask_temp(sub2ind(size(u_phaseAvg{1,1}),bucket_A(:, 1), bucket_A(:, 2))) = NaN;
mask_temp(sub2ind(size(u_phaseAvg{1,1}),bucket_B(:, 1), bucket_B(:, 2))) = NaN;

u_stackedData = cat(3, u_phaseAvg{:});
v_stackedData = cat(3, v_phaseAvg{:});
u_meanMatrix = mean(u_stackedData, 3, 'omitnan');
v_meanMatrix = mean(v_stackedData, 3, 'omitnan');

start_row = edge_A(1, 2)-1; end_row = edge_A(end, 2)+1;

%post-process (look pretty :))
X = interp2(X_all{1,1}, numInterp);
Y = interp2(Y_all{1,1}, numInterp);
x_ = (X - X(1, A_center(1, 2)))./bucket_diam; 
y_ = (Y - Y(A_center(1, 1), 1))./bucket_diam; 

figure;
imagesc(x_(1, :), y_(:, 1), u_meanMatrix); colormap('nebula'); 
colorbar('Ticks',[0,0.5, 1 ,1.5].*10^-2,...
         'TickLabels',{'0.0','0.005','0.01','0.015'}) 
c = colorbar;
c.Label.String = 'U-velocity (m/s)'; hold on;

% c_A=[0 0]; r_A = 0.58;
% circle_A = rectangle('Position',[c_A-r_A 2*r_A 2*r_A],'Curvature',[1 1], 'FaceColor', 'black', 'Edgecolor','none'); hold on;
% 
% temp_B_center = (X(1, B_center(1,2)) - X(1, A_center(1, 2))) ./ bucket_diam;
% c_B=[temp_B_center,y_(B_center(1,1))]; r_B = 0.58;
% circle_B = rectangle('Position',[c_B-r_B 2*r_B 2*r_B],'Curvature',[1 1], 'FaceColor', 'black', 'Edgecolor','none'); hold on;

axis equal; ylim([y_(1, 1) y_(end, 1)]); xlim([x_(1, 1) x_(1, end)])
hold off;
xlabel('$y/D_{b}$', 'Interpreter','latex')
ylabel('$x/D_{b}$', 'Interpreter','latex')
title('U-Velocity')
saveas(gcf,  [current_folder,'\', video_name, '_u_vel.fig'])

%-----------VORTICITY-----------%
vort_phaseAvg = cellfun(@(x) interp2(x, numInterp), vorticity, 'UniformOutput', false);
mask_temp = ones(size(vort_phaseAvg{1,1}));
mask_temp(sub2ind(size(vort_phaseAvg{1,1}),bucket_A(:, 1), bucket_A(:, 2))) = 0;

%time-averaged
vort_stackedData = cat(3, vort_phaseAvg{:});
non_dim_vort_stacked = vort_stackedData; %nondimensionalize here
vort_meanMatrix = mean(non_dim_vort_stacked, 3, 'omitnan');
vort_SDMatrix = std(non_dim_vort_stacked, 0, 3, 'omitnan');
vort_SEMatrix = vort_SDMatrix./ sqrt(length(vort_phaseAvg)); %STANDARD ERROR

    red   = [1 0 0];
    white = [1 1 1];
    blue  = [0 0 1];

    % Split into two halves
    n1 = floor(256/2);
    n2 = 256 - n1;

    % Red -> White
    t1 = linspace(0,1,n1)';
    cmap1 = (1 - t1).*red + t1.*white;

    % White -> Blue
    t2 = linspace(0,1,n2)';
    cmap2 = (1 - t2).*white + t2.*blue;

    % Combine
    cmap = [cmap1; cmap2];

figure;
imagesc(x_(1, :), y_(:, 1), vort_meanMatrix); colormap(cmap);
maxVal = max(abs(vort_meanMatrix(:)), [], 'omitnan');
clim([-maxVal maxVal]);
% clim([-10 10]);
% colorbar('Ticks',[-10 -8 -6 -4 -2 0 2 4 6 8 10],...
%          'TickLabels',{'-10', '-8', '-6', '-4', '-2','0','2','4','6','8', '10'}) 
c = colorbar;
c.Label.String = '\omega *'; hold on;
axis equal; ylim([y_(1, 1) y_(end, 1)]); xlim([x_(1, 1) x_(1, end)])
hold off;
xlabel('$y/D_{b}$', 'Interpreter','latex')
ylabel('$x/D_{b}$', 'Interpreter','latex')
title('Vorticity')
saveas(gcf, [current_folder,'\', video_name, '_vorticity_time_ave.png'])


%-----------STREAMLINES-----------%
y_index = find(y_(:, 1)==0, 1, 'first'); 

figure();
l = streamslice(u_meanMatrix, v_meanMatrix); hold on;
set(l,'LineWidth',1.5)
set(l,'Color','b');
% yline(y_index,'k--', 'LineWidth',1.5); hold on;
axis equal
ylim([1 length(u_meanMatrix(:, 1))]); xlim([1 length(u_meanMatrix)])
saveas(gcf, [current_folder,'\', video_name, '_streamlines.png'])

end