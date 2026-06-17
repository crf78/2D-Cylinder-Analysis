function graph_one_bucket(u_original ,u_smoothed, v_smoothed, vorticity,X_all, Y_all, bucket_diam, numInterp, current_folder, video_name)
    %-----------locate NaN-----------%
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

    bucket_A(:, 1) = rowIdx(1:end); bucket_A(:, 2) = colIdx(1:end);

    % Compute approximate center
    A_center(1, 1) = round(mean(bucket_A(:, 1))); A_center(1, 2) = round(mean(bucket_A(:, 2)));

    %find the location difference of both buckets and their center
    edge_A(:, 1) = nan_loc(:, 1); edge_A(:, 2) = nan_loc(:, 2);

    %Display the results
    % disp('Edge locations of NaN clusters for A Bucket:');
    % disp(bucket_A);

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

%-----------QUIVER-----------%
u_mask_phaseAvg = cellfun(@(x) interp2(x, numInterp), u_original, 'UniformOutput', false);
mask_temp = ones(size(u_mask_phaseAvg{1,1}));
mask_temp(sub2ind(size(u_mask_phaseAvg{1,1}),bucket_A(:, 1), bucket_A(:, 2))) = 0;

u_phaseAvg = cellfun(@(x) interp2(x, numInterp), u_smoothed, 'UniformOutput', false);
u_stackedData = cat(3, u_phaseAvg{:});
u_meanMatrix = mean(u_stackedData, 3, 'omitnan');
v_phaseAvg = cellfun(@(x) interp2(x, numInterp), v_smoothed, 'UniformOutput', false);
v_stackedData = cat(3, v_phaseAvg{:});
v_meanMatrix = mean(v_stackedData, 3, 'omitnan');

%post-process (look pretty :))
X = interp2(X_all{1,1}, numInterp);
Y = interp2(Y_all{1,1}, numInterp);
x_ = (X - X(1, A_center(1, 2)))./bucket_diam; 
y_ = (Y - Y(A_center(1, 1), 1))./bucket_diam; 

figure();
title('U and V Vectors');
quiver(x_, y_, u_meanMatrix, v_meanMatrix, 'color', 'b', 'LineWidth', 1.5); hold on;
axis equal
hold off; ylim([y_(1, 1) y_(end, 1)]); xlim([x_(1, 1) x_(1, end)])
xlabel('$y/D_{b}$', 'Interpreter','latex')
ylabel('$x/D_{b}$', 'Interpreter','latex')
saveas(gcf, [current_folder,'\', video_name,'_u_v_quiver.png'])
% disp('Quiver done!')

%-----------VORTICITY-----------%
vort_phaseAvg = cellfun(@(x) interp2(x, numInterp), vorticity, 'UniformOutput', false);

%time-averaged
vort_stackedData = cat(3, vort_phaseAvg{:});
vort_meanMatrix = mean(vort_stackedData, 3, 'omitnan');
vort_SDMatrix = std(vort_stackedData, 0, 3, 'omitnan');
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
saveas(gcf, [current_folder,'\',video_name,'_vorticity_time_ave.png'])
% disp('Vorticity done!')

%-----------STREAMLINES-----------%
figure();
title('Streamlines');
l = streamslice(u_meanMatrix, v_meanMatrix); hold on;
set(l,'LineWidth',1.5)
set(l,'Color','b');
axis equal
ylim([1 length(u_meanMatrix(:, 1))]); xlim([1 length(u_meanMatrix)])
saveas(gcf, [current_folder,'\',video_name,'_streamlines.png'])
% disp(['Streamlines done!'])
end
