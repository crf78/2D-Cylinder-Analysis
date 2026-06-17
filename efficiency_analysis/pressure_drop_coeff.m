%% For One bucket
%purpose: go through each of the trial folders and find the flux
%average fraction and then once it is complied, graph it. 
main()
function main()
clc; clear;
% Specify the parent directory containing the folders
% parentFolder = 'D:\hydroponics_PIV\trial_3_4_2026\';
% other_parentFolder = 'D:\hydroponics_PIV\trial_3_17_2026\';

parentFolder = 'D:\hydroponics_PIV\trial_4_3_2026\';
bucket_diam = 0.044;%m
numInterp = 1; % Change this number for finer or coarser mesh.

% u_in = 0.0110; %highest
% u_in = 0.0074; %medium
% u_in = 0.0023; %low
% Re_array = [100, 250, 480];
% u_in_array = [ 0.0023, 0.0056, 0.0110];
% speed_folders = {'low_speed','medium_speed', 'high_speed'};

u_in_array = [0.0111804,0.0130843, 0.0044968, 0.0016319];
Re_array = cast((u_in_array.* bucket_diam*1000) / 10^-3, 'int32');
speed_folders = {'flow_A', 'flow_B','flow_C', 'flow_D'};

% u_in_array =  [0.0016319];
% Re_array = cast((u_in_array.* bucket_diam*1000) / 10^-3, 'int32');
% speed_folders = {'flow_D'};

Cmap1 = nebula(4);

symbols = {'*', 'o', '^', '+','<', '>'};
% symbols = {'o', 'o', 'o', 'o','o', 'o'};
line_colors = winter(6); 
figure(1);
compiled_data = {}; count = 1;

for l = 1:length(speed_folders)
    parentDirectory = [parentFolder speed_folders{l}];
% figure(l)
% Get a list of all items in the parent directory
% if l == 2
%     parentDirectory = [other_parentFolder speed_folders{l}];
% else
%     parentDirectory = [parentFolder speed_folders{l}];
% end
        porosityFolders = dir(parentDirectory + "\*_porosity");
        
        for j = 1:length(porosityFolders)

        % Construct the path to the velocity_diff.mat file
        folderPath = fullfile(parentDirectory, porosityFolders(j).name);

        filePath = fullfile(folderPath,'PIVlab.mat');
        token = regexp(folderPath,'(\d+)_porosity','tokens');
        porosity = str2double(token{1}{1});
        solid_frac = abs(100-porosity)/100; %get solid fraction
        
        % Check if the file exists
        if isfile(filePath) %&& porosity == 73

            % Load the .mat file
            load(filePath);
            X = interp2(x{1,1}, numInterp);
            Y = interp2(y{1,1}, numInterp);

            [v1, v1_std, v2a, v2a_std, v2b, v2b_std] = time_ave_v1_v2(u_smoothed, v_smoothed, v_original, X, Y, bucket_diam, u_in_array(l), line_colors(j, :));
            % [total_flux] = compute_flux(u_smoothed, v_original, edge_column, bottom_row, top_row, y_, max_val_x, line_colors(j, :));
            
            title("Graphing Re:"+num2str(Re_array(l))+ " Solid Frac:"+ num2str(solid_frac))

            [Da, k] = get_permeability(porosity/100);
            compiled_u_time{j, 1} = v2a/v1;
            compiled_u_time{j, 2} = solid_frac;
            disp("Computing Re:"+num2str(Re_array(l))+ " Solid Frac:"+ num2str(solid_frac));
            disp("Ratio: "+num2str(v2a/v1)+", u1 = " +num2str(v1)+", u2 = "+num2str(v2a));
            grid on; 

            % xlabel('$Flux (m^{2}/s)$', Interpreter='latex'); ylabel('y/D', Interpreter='latex')
            % ylabel('$Flux (m^{2}/s)$', Interpreter='latex'); xlabel('Re', Interpreter='latex')
            % xlim([-1 4]*10^-4)
            % scatter(Re_array(l), total_flux, symbols{j}, 'filled', MarkerFaceColor=Cmap1(l,:), MarkerEdgeColor=Cmap1(l,:),DisplayName=['Re:', num2str(Re_array(l)), ', Solid:', num2str(solid_frac)]); hold on; 
            
            if j == 1
            scatter(Da, v2a/v1, 'o', 'filled', MarkerFaceColor=Cmap1(l,:), MarkerEdgeColor=Cmap1(l,:),DisplayName=['Re:', num2str(Re_array(l))]); hold on; 
            errorbar(Da, v2a/v1, v2a_std/v1_std, 'k', 'vertical', HandleVisibility='off');
            else
                scatter(Da, v2a/v1, 'o', 'filled', MarkerFaceColor=Cmap1(l,:), MarkerEdgeColor=Cmap1(l,:), HandleVisibility='off'); hold on; 
                errorbar(Da, v2a/v1, v2a_std/v1_std, 'k', 'vertical', HandleVisibility='off');
            end

            compiled_data{count, 1} = Re_array(l);
            compiled_data{count, 2} = Da;
            compiled_data{count, 3} = k;
            compiled_data{count, 4} = solid_frac;
            compiled_data{count, 5} = v2a/v1;
            compiled_data{count, 6} = v2a;
            compiled_data{count, 7} = v1;
            count = count +1 ;

        end
        end
end

legend(); hold off
%GRAPHING 
ylabel('$\frac{\bar{v}_{2}}{\bar{v}_{1}}$', Interpreter='latex'); xlabel('$Da$',Interpreter='latex', fontsize=15)
% ylim([0 2.5])
fontsize(gcf, 14, "points")
% ylim([0 30]);
% legend('Re:100','Re:330','Re:480');

saveas(gcf, 'v2_v1_compare_Da_new_flux.png')
saveas(gcf, 'v2_v1_compare_Da_new_flux.fig')

save_wake = cell2table(compiled_data);
save_wake.Properties.VariableNames = {'Re_num', 'Da', 'k', 'solid_frac', 'V2_V1', 'V2', 'V1'};
writetable(save_wake,'compare_v2_v1_new_flux.csv','Delimiter',',')  
end

function [v1, v1_std, v2a, v2a_std, v2b, v2b_std] = time_ave_v1_v2(u_smoothed, v_smoothed, v_original, X, Y, bucket_diam, u_in, linecolor)

%-----------u_vel only-----------%
numInterp = 1;
u_phaseAvg = cellfun(@(x) interp2(x, numInterp), u_smoothed, 'UniformOutput', false);
v_phaseAvg = cellfun(@(x) interp2(x, numInterp), v_smoothed, 'UniformOutput', false);
v_phaseAvg_mask = cellfun(@(x) interp2(x, numInterp), v_original, 'UniformOutput', false);
[new_bucket_A, new_bucket_edge, new_bucket_center] = locate_NAN(v_phaseAvg_mask{1,1});
mask_temp = ones(size(v_phaseAvg_mask{1,1}));
mask_temp(sub2ind(size(v_phaseAvg_mask{1,1}),new_bucket_A(:, 1), new_bucket_A(:, 2))) = NaN;

u_stackedData = cat(3, u_phaseAvg{:});
u_meanMatrix = mean(u_stackedData, 3, 'omitnan');

x_ = (X - X(1, new_bucket_center(1, 2)))./bucket_diam; 
y_ = (Y - Y(new_bucket_center(1, 1), 1))./bucket_diam; 
bucket_x = x_(sub2ind(size(x_), new_bucket_edge(: , 1), new_bucket_edge(:, 2)));
bucket_y = y_(sub2ind(size(y_), new_bucket_edge(: , 1), new_bucket_edge(:, 2)));

%call flux here
[v1, v1_std, v2a, v2a_std, v2b, v2b_std] = compute_cylinder_flux(u_meanMatrix, u_phaseAvg, v_phaseAvg, new_bucket_edge, x_, y_);

end

function [v1, v2, edge_column, bottom_row, top_row, y_, max_val_x] = time_ave_v1_v2_previous(u_original, v_original, X, Y, bucket_diam, u_in, linecolor)
%-----------u_vel only-----------%
numInterp = 2;

u_phaseAvg = cellfun(@(x) interp2(x, numInterp), u_original, 'UniformOutput', false);
v_phaseAvg = cellfun(@(x) interp2(x, numInterp), v_original, 'UniformOutput', false);
[new_bucket_A, new_bucket_edge, new_bucket_center] = locate_NAN(v_phaseAvg{1,1});
mask_temp = ones(size(v_phaseAvg{1,1}));
mask_temp(sub2ind(size(v_phaseAvg{1,1}),new_bucket_A(:, 1), new_bucket_A(:, 2))) = NaN;

u_stackedData = cat(3, u_phaseAvg{:});
u_meanMatrix = mean(u_stackedData, 3, 'omitnan');

% [max_val_x, edge_column] = max(new_bucket_edge(: , 2));
% 
% bottom_row = max(new_bucket_edge(:, 1));
% top_row = min(new_bucket_edge(:, 1)); 

x_ = (X - X(1, new_bucket_center(1, 2)))./bucket_diam; 
y_ = (Y - Y(new_bucket_center(1, 1), 1))./bucket_diam; 
bucket_x = x_(sub2ind(size(x_), new_bucket_edge(: , 1), new_bucket_edge(:, 2)));
bucket_y = y_(sub2ind(size(y_), new_bucket_edge(: , 1), new_bucket_edge(:, 2)));

edge_column = find(round(x_(1, :), 1) == 0.5, 1,'first');
max_val_x = x_(1, edge_column); 
top_row = find(round(y_(:, 1), 1) == -0.5, 1,'first');
bottom_row = find(round(y_(:, 1), 1) == 0.5, 1,'first');

v1 = mean(u_meanMatrix(top_row:bottom_row, edge_column+1));

v2_a = u_meanMatrix(1:top_row-1, edge_column+1);
v2_b = u_meanMatrix(bottom_row+1:end, edge_column+1);
v2 = mean([v2_a; v2_b]);

% [max_val_x_2, edge_column_2] = max(bucket_x);
% max_val_y_2 = max(bucket_y);
% bottom_row_2 = find(y_(:, 1)== max_val_y_2);
% min_val_y_2 = min(bucket_y); 
% top_row_2 = find(y_(:, 1)==min_val_y_2);
% plot(u_meanMatrix(top_row:bottom_row, edge_column+1), y_(top_row:bottom_row, 1), '-', color=linecolor,LineWidth=2.5); hold on;
% plot(u_meanMatrix(1:top_row-1, edge_column+1), y_(1:top_row-1, 1), 'o-' , color=linecolor,LineWidth=2.5); hold on;
% plot(u_meanMatrix(bottom_row+1:end, edge_column+1), y_(bottom_row+1:end, 1), '^-', color=linecolor, LineWidth=2.5); hold on;
% legend(['$\bar{u}_1$';'$\bar{u}_2$';'$\bar{u}_2$'], 'Interpreter', 'latex')
% pause(5);
% plot(max_val_x.*ones(length(y_(:, 1)),1), y_(:, 1), 'k-', LineWidth=2.5); hold on;
% plot(max_val_x.*ones(length(y_(1:top_row, 1)),1), y_(1:top_row, 1), 'y-', LineWidth=2.5); hold on;
% plot(max_val_x.*ones(length(y_(bottom_row:end, 1)),1), y_(bottom_row:end, 1), 'g-', LineWidth=2.5); hold on;
% 
% bucket_x = x_(sub2ind(size(x_), new_bucket_edge(: , 1), new_bucket_edge(:, 2)));
% bucket_y = y_(sub2ind(size(y_), new_bucket_edge(: , 1), new_bucket_edge(:, 2)));
% [max_val_x, edge_column] = max(bucket_x);
% max_val_y = max(bucket_y);
% bottom_row = find(y_(:, 1)==max_val_y);
% min_val_y = min(bucket_y); 
% top_row = find(y_(:, 1)==min_val_y);
% figure;
% imagesc(x_(1, :), y_(:, 1), u_meanMatrix); colormap('nebula'); 
% clim([0 u_in.*2]);
% colorbar('Ticks',[0,0.5, 1 ,1.5, 2, 2.5].*10^-2,...
%          'TickLabels',{'0.0','0.005','0.01','0.015','0.02','0.025'}) 
% c = colorbar;
% c.Label.String = 'Velocity (m/s)'; hold on;
% %scatter(bucket_x, bucket_y, 'ko', 'filled'); hold on;
% 
% %viscircles([0, 0], 0.50, 'Color', 'black')
% c=[0 0]; r = 0.58;
% r = rectangle('Position',[c-r 2*r 2*r],'Curvature',[1 1], 'FaceColor', 'black', 'Edgecolor','none'); hold on;
% plot(max_val_x.*ones(length(y_(:, 1)),1), y_(:, 1), 'k-', LineWidth=2.5); hold on;
% plot(max_val_x.*ones(length(y_(1:top_row, 1)),1), y_(1:top_row, 1), 'y-', LineWidth=2.5); hold on;
% plot(max_val_x.*ones(length(y_(bottom_row:end, 1)),1), y_(bottom_row:end, 1), 'g-', LineWidth=2.5); hold on;
% axis equal; ylim([y_(1, 1) y_(end, 1)]); xlim([x_(1, 1) x_(1, end)])
% hold off;
% xlabel('$y/D_{b}$', 'Interpreter','latex')
% ylabel('$x/D_{b}$', 'Interpreter','latex')
% title('Velocity Magnitude')

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

end

function [Da, k] = get_permeability(porosity)
    %from the carman-kozeny relation
    k = ((1/180)*(porosity^3*(0.002^2)))/((1-porosity)^2);
    Da = k/(0.044)^2;
end

function [total_flux] = compute_flux(u_meanMatrix, u_original, v_original, edge_column, bottom_row, top_row, y_, max_val_x, linecolor)
    numInterp = 2;
    dy = y_(2)-y_(1); 

    % Interpolate velocity fields
    u_phaseAvg = cellfun(@(x) interp2(x, numInterp), u_original, 'UniformOutput', false);

    u_stackedData = cat(3, u_phaseAvg{:});
    num_frames = length(u_stackedData);
    for i=1:num_frames
        % Extract velocities along the column
        u_col = u_stackedData(:, edge_column, i);
        % Flux density across vertical plane = u velocity
        flux_density = u_col*dy;

        % Store results
        u1_flux_array(i,:) = flux_density(top_row:bottom_row);
        u1_total_flux_array(i,1) = sum(flux_density(top_row:bottom_row));

        u2a_flux_array(i,:) = flux_density(1:top_row);
        u2a_total_flux_array(i,1) = sum(flux_density(1:top_row));

        u2b_flux_array(i,:) = flux_density(bottom_row:end);
        u2b_total_flux_array(i,1) = sum(flux_density(bottom_row:end));
        total_flux_array(i, :) = sum(flux_density); 

    end
    total_flux = mean(total_flux_array); 
    % xline(mean(total_flux_array, 1), '--', color=linecolor,LineWidth=2.5); hold on;
    % plot(mean(u1_flux_array, 1), y_(top_row:bottom_row), '-', color=linecolor,LineWidth=2.5); hold on;
    % plot(mean(u2a_flux_array, 1), y_(1:top_row, 1), 'o-' , color=linecolor,LineWidth=2.5); hold on;
    % plot(mean(u2b_flux_array, 1), y_(bottom_row:end, 1), '^-', color=linecolor, LineWidth=2.5); hold on;
end

function [v1, v1_std, v2_a, v2a_std, v2_b, v2b_std] = compute_cylinder_flux(u_meanMatrix, u_smoothed, v_smoothed, nan_loc, x_, y_)
    num_frames = length(u_smoothed);
    for i=1:num_frames
        u_curr_frame = u_smoothed{i};
        v_curr_frame = v_smoothed{i};
        
        u_edges = u_curr_frame(sub2ind(size(u_curr_frame), nan_loc(: , 1), nan_loc(:, 2)));
        v_edges = v_curr_frame(sub2ind(size(v_curr_frame), nan_loc(: , 1), nan_loc(:, 2)));

        u_x = x_(sub2ind(size(x_), nan_loc(: , 1), nan_loc(:, 2))); %circle velocity vectors
        u_y = y_(sub2ind(size(y_), nan_loc(: , 1), nan_loc(:, 2))); %circle velocity vectors
        phi = atan2d(u_y, u_x); 
        
        mag = (u_x.^2 + u_y.^2).^ (0.5);
        mag(mag == 0) = eps;
        phi = mod(phi, 360); 
        
        % Outward normal
        vn_x = -u_x ./ mag;
        vn_y = -u_y ./ mag;

        % Calculate the projection of 'vel' onto 'circle'
        vel_vec  = [u_edges, v_edges]; 
        n_circle = [vn_x, vn_y];

        flux_density = sum(vel_vec .* n_circle, 2);
        proj = flux_density .* n_circle;

        u_vel_in = proj(:, 1);
        v_vel_in = proj(:, 2);

        % ---- Correct arc length calculation ----
        % Angle for sorting

        % Sort points around circle
        [phi_sorted, idx] = sort(phi); %idx is the key!
        x_sorted = u_x(idx);
        y_sorted = u_y(idx);
        flux_sorted = flux_density(idx);

        % Segment lengths
        ds = sqrt(diff(x_sorted).^2 + diff(y_sorted).^2);

        % Total flux
        total_flux = sum(flux_sorted(1:end-1) .* ds);

        % Store results
        u_edges_array(i, :) = u_edges(idx); 
        flux_array(i,:) = flux_sorted;
        total_flux_array(i,1) = total_flux;

    end
ave_flux = mean(flux_array); 
std_flux = std(flux_array); 

beg_indx = find((ave_flux > 0) & (phi_sorted' > 20), 1, 'first');%find where we can see the switch from neg->pos flux
u_x_beg = x_sorted(beg_indx); u_y_beg = y_sorted(beg_indx); % in the whole x, y pos array
temp_last_indx = find(ave_flux(beg_indx+1:end) < 0, 1, 'first'); %find where we can see the switch from pos->neg flux
last_indx = beg_indx + temp_last_indx - 1; 
u_x_last = x_sorted(last_indx); u_y_last = y_sorted(last_indx); % in the whole x, y pos array

time_ave_u_edges_array = mean(u_edges_array);
edge_column = find(u_x_beg == x_(1, :)); 
max_val_x = x_(1, edge_column); 
top_row = find(u_y_last == y_(:, 1)); 
bottom_row = find(u_y_beg == y_(:, 1));

integral_cyl = zeros(num_frames,1);
integral_free = zeros(num_frames,1);

% Extract y vector (important for proper integration)
y_vec = y_(:,1);   % assumes meshgrid format

for t = 1:num_frames
    u_frame = u_smoothed{i};
    
    % Cylinder location
    u_cyl = u_edges_array(t, beg_indx:last_indx);
    y_segment = y_sorted(beg_indx:last_indx);
    
    % Free stream location
    u_free_a = u_frame(1:top_row-1, edge_column+1);
    u_free_b = u_frame(bottom_row+1:end, edge_column+1);
    
    y_segment_a = y_vec(1:top_row-1);
    y_segment_b = y_vec(bottom_row+1:end);
    
    % Integrate using trapezoidal rule
    integral_cyl(t) = trapz(flip(y_segment), u_cyl');
    integral_free_a(t) = trapz(y_segment_a, u_free_a);
    integral_free_b(t) = trapz(y_segment_b, u_free_b);
    
end

v1 = mean(integral_cyl);
v1_std = std(integral_cyl);
v2_a = mean(integral_free_a);
v2a_std = std(integral_free_a);
v2_b = mean(integral_free_b);
v2b_std = std(integral_free_b);

% figure()
% plot(1:num_frames, integral_cyl, 'b'); hold on;
% yline(v1, '--b', 'HandleVisibility','off'); hold on;
% plot(1:num_frames, integral_free_a, 'g'); hold on;
% yline(v2_a, '--g', 'HandleVisibility','off'); hold on;
% % plot(1:num_frames, integral_free_b, 'r'); hold on;
% % yline(v2_b, '--r'); hold on;
% ylim([-1e-2 1e-2]);
% grid on;
% xlabel('frames'); ylabel('Velocity (m/s)');
% legend('Cylinder', 'Gap')

% figure();
% scatter(u_x, u_y, 'ko', 'filled'); hold on; 
% quiver(x_, y_, u_smoothed{end}, v_smoothed{end}, 'color', 'b', 'LineWidth', 1); hold on;
% scatter(u_x_beg, u_y_beg, 'o', 'filled', 'MarkerEdgeColor', 'r', 'LineWidth', 1); hold on;
% scatter(u_x_last, u_y_last, 'o', 'filled', 'MarkerEdgeColor', 'g', 'LineWidth', 1); hold on;
% 
% scatter(x_sorted(beg_indx:last_indx), y_sorted(beg_indx:last_indx),'o', 'filled', 'MarkerEdgeColor', 'b', 'LineWidth', 1); hold on;
% % x is down the channel, y is up the channel
% % scatter(max_val_x.*ones(length(y_(:, 1)),1), y_(:, 1),'o', 'filled', 'MarkerEdgeColor', 'b', 'LineWidth', 1); hold on;
% scatter(max_val_x.*ones(length(y_(1:top_row, 1)),1), y_(1:top_row, 1),'o', 'filled', 'MarkerEdgeColor', 'b', 'LineWidth', 1); hold on;
% scatter(max_val_x.*ones(length(y_(bottom_row:end, 1)),1), y_(bottom_row:end, 1),'o', 'filled', 'MarkerEdgeColor', 'b', 'LineWidth', 1); hold on;
% 
% 
% title('Flux in the Bucket')
% grid on; axis equal
% hold off; 

end