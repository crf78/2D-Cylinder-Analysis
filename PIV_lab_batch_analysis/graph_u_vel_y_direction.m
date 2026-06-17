function graph_u_vel_y_direction(u_original, v_original, vorticity, X_all, Y_all, bucket_diam, numInterp, current_folder, video_name)
temp_y = Y_all{1,1};
y = temp_y(:, 1);
X = interp2(X_all{1,1}, numInterp);
Y = interp2(Y_all{1,1}, numInterp);

%---------Integrate across the x direction-----------
% figure()
num_frames = length(u_original);
for i=1:num_frames
    curr_frame = u_original{i};
    u_ave = mean(curr_frame, 2, 'omitnan');
    u_std = std(curr_frame, 0, 2, 'omitnan'); 
    temp(:, i) = u_ave;

end
% grid on;
% hold off

%Integrates across time
u_time_ave = mean(temp, 2); 
u_time_std = std(temp, 0, 2); 
u_std_error = u_time_std ./ num_frames;

%plots the u-velocity vector
figure()
plot(temp, y, 'o');
errorbar(u_time_ave, y, u_std_error, 'horizontal')
xlabel('U-Velocity (m/s)');
ylabel('X-Direction')
title('Time Average Velocity Profile Across the Channel')
% xlim([0 max(u_time_ave)+0.01])
grid on; 
saveas(gcf, [current_folder,'\',video_name, '_time_ave_vel_profile.fig'])

numInterp = 2;
u_phaseAvg = cellfun(@(x) interp2(x, numInterp), u_original, 'UniformOutput', false);
v_phaseAvg = cellfun(@(x) interp2(x, numInterp), v_original, 'UniformOutput', false);
v_phaseAvg = cellfun(@(x) interp2(x, numInterp), vorticity, 'UniformOutput', false);

u_stackedData = cat(3, u_phaseAvg{:});
u_meanMatrix = mean(u_stackedData, 3, 'omitnan');
v_stackedData = cat(3, v_phaseAvg{:});
v_meanMatrix = mean(v_stackedData, 3, 'omitnan');
vort_stackedData = cat(3, v_phaseAvg{:});
vort_meanMatrix = mean(vort_stackedData, 3, 'omitnan');

middle = cast(length(u_meanMatrix(:, 1))/2, 'int32');
u_in = u_meanMatrix(middle, 1); 

mag = sqrt(u_meanMatrix.^2 + v_meanMatrix.^2);

x_ = X(1, :)./bucket_diam; 
y_ = Y(:, 1)./bucket_diam; 

% %plots the u-velocity vector
% figure()
% for iter = 1:4
%     [~, loc] = find( round(x_(1,:),1) == iter, 1, 'first');
%     plot(smooth(u_meanMatrix(:, loc)), y_(:, loc), '--o', 'DisplayName',['location: x=', num2str(iter)]); hold on;
% end
% legend()
% xlabel('U-Velocity (m/s)');
% ylabel('X-Direction')
% title('Time Average Velocity Profile Across the Channel')
% % xlim([0 max(u_time_ave)+0.01])
% grid on; 
% saveas(gcf, 'time_ave_vel_profile_developing.fig')

figure;
imagesc(x_(1, :), y_(:, 1), u_meanMatrix); colormap('nebula'); 
% clim([0 u_in.*2]);
% colorbar('Ticks',[0,0.5, 1 ,1.5, 2, 2.5].*10^-2,...
%          'TickLabels',{'0.0','0.005','0.01','0.015','0.02','0.025'}) 
% c = colorbar;
% c.Label.String = 'Velocity (m/s)'; hold on;
% axis equal; 
% ylim([y_(1, 1) y_(end, 1)]); xlim([x_(1, 1) x_(1, end)])
hold off;
xlabel('$y/D_{b}$', 'Interpreter','latex')
ylabel('$x/D_{b}$', 'Interpreter','latex')
title('Velocity Magnitude')
saveas(gcf, [current_folder,'\',video_name,'_vel_u_time_ave.fig'])
saveas(gcf, [current_folder,'\',video_name,'_vel_u_time_ave.png'])

figure;
imagesc(x_, y_, vort_meanMatrix); colormap('nebula'); 
% clim([0 u_in.*2]);
% colorbar('Ticks',[0,0.5, 1 ,1.5, 2, 2.5].*10^-2,...
%          'TickLabels',{'0.0','0.005','0.01','0.015','0.02','0.025'}) 
c = colorbar;
c.Label.String = 'Vorticity (1/s)'; hold on;
ylim([y_(1, 1) y_(end, 1)]); xlim([x_(1, 1) x_(1, end)])
hold off;
xlabel('$y/D_{b}$', 'Interpreter','latex')
ylabel('$x/D_{b}$', 'Interpreter','latex')
title('Vorticity')
saveas(gcf, [current_folder,'\', video_name,'_vort_time_ave.fig'])
saveas(gcf, [current_folder,'\',video_name,'_vort_time_ave.png'])


end
