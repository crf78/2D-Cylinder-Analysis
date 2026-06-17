%% For One bucket
%purpose: go through each of the trial folders and find the flux
%average fraction and then once it is complied, graph it. 

clc; clear;
% Specify the parent directory containing the folders
parentDirectory = 'I:\high_flow\no_blockage';
u_in = 0.02;

% Get a list of all items in the parent directory
items = dir(parentDirectory);
j = 0;
compiled_u_time = {};
compiled_x = {};

trad_wake = [];
wake_compare = [];
wake_dead = [];

Cmap1 = winter(6);
figure(1)

% Iterate through all items
for i = 1:length(items)
    % Check if the item is a folder (excluding '.' and '..')
    if items(i).isdir && ~ismember(items(i).name, {'.', '..'})
        % Construct the path to the current folder
        folderPath = fullfile(parentDirectory, items(i).name);
        
        % Construct the path to the velocity_diff.mat file
        filePath = fullfile(folderPath, 'streamwise_variables.mat');
        
        % Check if the file existss
        if isfile(filePath)
            % Load the .mat file
                data = load(filePath);
                j =  j + 1; 
                compiled_u_time{j, 1} = data.u_time_ave;
                compiled_x{j, 1} = data.non_dim_x;

                temp_l = data.non_dim_x(data.end_row:end-1);
                % wake_smoothed = smooth(temp_l, data.u_time_ave(data.end_row:end-1),0.1,'rloess');
                wake_smoothed = data.u_time_ave(data.end_row:end-1);

                trad_idx = find(wake_smoothed > 0.90, 1, 'first'); %traditional Wake, saves position
                if ~isempty(trad_idx)
                    trad_wake_length(j, 1) = temp_l(trad_idx);
                else
                    trad_length = nan; 
                    trad_wake_length(j, 1) = nan;
                end
                idx = find(data.non_dim_x > 3, 1, 'first'); % compare at 3D, saves u_vel
                wake_compare(j, 1) = data.u_time_ave(idx);
                
                dead_idx = find(wake_smoothed < 0.1, 1, 'last'); %compare deadzone, saves the position
                wake_dead(j, 1) = temp_l(dead_idx);

                u_temp_before = data.u_time_ave(1:data.start_row);
                u_temp_after = wake_smoothed;
                
                plot(data.non_dim_x(1:data.start_row), data.u_time_ave(1:data.start_row), '-o', color=Cmap1(j,:), LineWidth=1.5); hold on; 
                plot(data.non_dim_x(data.end_row:end-1), wake_smoothed, '-o', color=Cmap1(j,:), LineWidth=1.5, HandleVisibility='off'); hold on;                
        end
    end
end

%GRAPHING 

figure(1)
plot(ones(1, length(-1:0.25:3)).*data.non_dim_x(data.start_row), -1:0.25:3, '-k', LineWidth=2, HandleVisibility='off'); hold on;
plot(ones(1, length(-1:0.25:3)).*data.non_dim_x(data.end_row), -1:0.25:3, '--k', LineWidth=2, HandleVisibility='off'); hold on;
% plot(trad_wake_length, 0.95, '*k', LineWidth=2); hold off;

ylabel('$\bar{u} / U_{\infty}$',Interpreter='latex', fontsize=15);
xlabel('$x / D_{b}$',Interpreter='latex', fontsize=15)
title('Streamwise Velocity Down the Channel')
legend('Solid', '64% porous','73% porous', '77% porous', '81% porous',location='southeast')
grid on; 
fontsize(gcf, 14, "points")
xlim([-2 8]); ylim([-0.5 1.5])
saveas(gcf, 'non_dimen_compiled_streamwise.png')

trial_name = {'0%';'64%';'73%';'77%';'81%'};
save_wake = table(trial_name, trad_wake_length, wake_compare, wake_dead);
writetable(save_wake,'wake_length.csv','Delimiter',',')  



%%

clc;clear;
wake_data_2D = readtable('D:\hydroponics_PIV\trail_2_5_2026\compiled_wake_length.csv');

% wake_data = readtable('D:\hydroponics_PIV\Previous PIV trials\Trial_2025_4_30\one_bucket\compiled_wake_length.csv');

porosity = [0; 64; 73; 77; 81];
compiled_data = [];

for j=1:length(porosity)
    % porosity_temp = wake_data(wake_data.porosity==porosity(j), :);
    % compiled_data(j, 1) = mean(porosity_temp.wake_length);
    % compiled_data(j, 2) = std(porosity_temp.wake_length);
    % compiled_data(j, 3) = mean(porosity_temp.wake_length);

    porosity_2D = wake_data_2D(wake_data_2D.porosity==porosity(j), :);
    compiled_data_2D(j, 1) = mean(porosity_2D.wake_length);
    compiled_data_2D(j, 2) = std(porosity_2D.wake_length);
    compiled_data_2D(j, 3) = mean(porosity_2D.wake_compare);
    compiled_data_2D(j, 4) = std(porosity_2D.wake_compare);
end

Cmap1 = winter(6);

figure(1)
% plot(porosity, compiled_data(:, 1),LineWidth=3, color='r'); hold on;
% errorbar(porosity, compiled_data(:, 1), compiled_data(:, 2),"vertical","LineStyle","none","color",'r'); hold on;

plot(porosity, compiled_data_2D(:, 1),'o-',LineWidth=1.5, color='b'); hold on;
errorbar(porosity, compiled_data_2D(:, 1), compiled_data_2D(:, 2),"vertical","LineStyle","none","color",'b', 'LineWidth',1.5); hold on;

grid on; 
yyaxis left
ylim([0 2]); xlim([-5 90]);
yticks(0:0.25:2)
ylabel('$x/D$', Interpreter='latex');
xlabel('Porosity (%)');
title('Wake lengths for different porosities')
fontsize(gcf, 12, "points")
% saveas(gcf, 'wake_lengths_porosity_differently_zero.png');
% saveas(gcf, 'wake_lengths_porosity_differently_zero.fig');

% figure(2)
yyaxis right
plot(porosity, compiled_data_2D(:, 3),'o-',LineWidth=1.5, color='r'); hold on;
errorbar(porosity, compiled_data_2D(:, 3), compiled_data_2D(:, 4),"vertical","LineStyle","none","color",'r', 'LineWidth',1.5); hold on;
xlabel('Porosity (%)'); xlim([-5 90]);
ylabel('$U/U_{\infty}$', Interpreter='latex');
% title('Velocity Recovery for $x/D=$3', Interpreter='latex')
fontsize(gcf, 12, "points")
grid on; 
% saveas(gcf, 'wake_lengths_porosity_recovery.png');
% saveas(gcf, 'wake_lengths_porosity_recovery.fig');

saveas(gcf, 'wake_lengths_porosity_both.png');
saveas(gcf, 'wake_lengths_porosity_both.fig');

%%

clc;clear;
% Import Data
T = readtable('H:\hydroponics_PIV\trial_4_3_2026\wake_length_compare.csv');


% Convert porosity from string ("54%") to numeric
T.porosity = str2double(erase(T.porosity,"%"));
porosity_array = unique(T.porosity);

% Get unique velocities
vel = unique(T.u_infty);
Re = round((1000.*(0.044)*vel) / (0.001), -1); % reynolds number

% Create tiled figure
figure
tiledlayout(1,2)

% ================================
% Traditional Wake Length
% ================================
% nexttile
% hold on
% symbols = {'*', 'o', '^', '+','<', '>'};
Cmap1 = winter(length(porosity_array));
% for i = 1:length(porosity_array)
% 
%     idx = T.porosity == porosity_array(i);
% 
%     p = T.porosity(idx);
%     k = ((1/180).*(p.^3*(0.002^2)))./((1-p).^2);
%     Da = k./(0.044).^2;
%     y = T.trad_wake_length(idx);
% 
%     % % Remove NaNs
%     % valid = ~isnan(y);
%     % p = Da(valid);
%     % y = y(valid);
%     % 
%     % % Sort to prevent zig-zag
%     % [p_sorted, order] = sort(p);
%     % y_sorted = y(order);
% 
%     scatter(Re,y,'o', 'filled', 'MarkerFaceColor', Cmap1(i, :), 'MarkerEdgeColor', Cmap1(i, :))
% 
% end
% % ylim([0 4])
% xlabel('Re')
% ylabel('Traditional Wake Length ($x/D$)', Interpreter='latex')
% title('Traditional Wake ($\bar{u} = 0.95U_{\infty}$)', Interpreter='latex')
% grid on

% ================================
% Dead Wake Length
% ================================
nexttile
hold on

for i = 1:length(porosity_array)

    % idx = T.u_infty == vel(i);
    idx = T.porosity == porosity_array(i);

    p = T.porosity(idx);
    k = ((1/180).*(p.^3*(0.002^2)))./((1-p).^2);
    Da = k./(0.044).^2;

    y = T.wake_dead(idx);

    valid = ~isnan(y);
    p = Da(valid);
    y = y(valid);

    [p_sorted, order] = sort(p);
    y_sorted = y(order);

    % plot(p_sorted,y_sorted,'-o','LineWidth',2, 'Color', Cmap1(i, :))
    plot(Re,y_sorted,'o-', 'Color', Cmap1(i, :)); hold on;
    % scatter(Re.*ones(length(y_sorted), 1), y_sorted,'-o','LineWidth',2, 'Color', Cmap1(i, :))

end
ylim([0 4])
% xlabel('Porosity (%)')
xlabel('Re')
ylabel('Dead Zone Length ($x/D$)', Interpreter='latex')
title('Dead Zone Wake ($\bar{u} < 0.1 U_{\infty}$)', Interpreter='latex')
grid on

% ================================
% Velocity Recovery Metric
% ================================
nexttile
hold on

for i = 1:length(porosity_array)

    % idx = T.u_infty == vel(i);
    idx = T.porosity == porosity_array(i);

    p = T.porosity(idx);
    k = ((1/180).*(p.^3*(0.002^2)))./((1-p).^2);
    Da = k./(0.044).^2;

    y = T.wake_compare(idx);

    valid = ~isnan(y);
    p = Da(valid);
    y = y(valid);

    [p_sorted, order] = sort(p);
    y_sorted = y(order);

    plot(Re,y_sorted,'o-',  'Color', Cmap1(i, :)); hold on;
    % plot(p_sorted,y_sorted,'-o','LineWidth',2, 'Color', Cmap1(i, :))
    % scatter(Re.*ones(length(y_sorted), 1), y_sorted,'-o','LineWidth',2, 'Color', Cmap1(i, :))

end
ylim([-0.5 3])
% xlabel('Porosity (%)')
% xlabel('Da')
xlabel('Re')
ylabel('Recovery Metric ($\bar{u}/U_{\infty}$)', Interpreter='latex')
title('Velocity Recovery at $x = 3D$', Interpreter='latex')
grid on

%Add legend (apply to whole layout)
% legend(string(vel) + " m/s",'Location','bestoutside')
legend({'Solid', '64% porosity', '73% porosity', '77% porosity', '81% porosity'},'Location','bestoutside')

saveas(gcf, 'wake_lengths_compare.png');
saveas(gcf, 'wake_lengths_compare.fig');

%%

T = readtable('I:\wake_length_compare.csv'); % load your data

% Convert porosity to categorical for grouping
T.solid = categorical(T.solid);

figure
tiledlayout(1,2)

groups = categories(T.solid); 
colors = winter(length(groups));
markers = {'o','s','d','^','v'}; % different markers for clarity

% ---- Plot 1: wake_compare ----
nexttile
hold on

for i = 1:numel(groups)
    idx = T.solid == groups{i};
    
    % Sort by u_infty
    [x_sorted, order] = sort(T.u_infty(idx));
    y_sorted = T.wake_compare(idx);
    y_sorted = y_sorted(order);
    
    Re = round((1000.*(0.03)*x_sorted) / (0.001), -1); % reynolds number
    plot(Re, y_sorted, ...
        '-o', ...
        'Color', colors(i,:), ...
        'Marker', markers{mod(i-1,numel(markers))+1}, ...
        'LineWidth', 1.5, ...
        'MarkerFaceColor', colors(i,:))
end
ylim([-0.5 3])
xlabel('Re')
ylabel('Recovery Metric ($\bar{u}/U_{\infty}$)', Interpreter='latex')
title('Velocity Recovery at $x = 3D$', Interpreter='latex')
legend(groups, 'Location','northwest')
grid on
fontsize(14, 'points')

% ---- Plot 2: wake_dead ----
nexttile
hold on

for i = 1:numel(groups)
    idx = T.solid == groups{i};
    
    % Sort by u_infty
    [x_sorted, order] = sort(T.u_infty(idx));
    y_sorted = T.wake_dead(idx);
    y_sorted = y_sorted(order);
    
    Re = round((1000.*(0.03)*x_sorted) / (0.001), -1); % reynolds number
    plot(Re, y_sorted, ...
        '-o', ...
        'Color', colors(i,:), ...
        'Marker', markers{mod(i-1,numel(markers))+1}, ...
        'LineWidth', 1.5, ...
        'MarkerFaceColor', colors(i,:))
end
ylim([0 10])
xlabel('Re')
ylabel('Dead Zone Length ($x/D$)', Interpreter='latex')
title('Dead Zone Wake ($\bar{u} < 0.1 U_{\infty}$)', Interpreter='latex')
legend(groups, 'Location','northwest')
grid on
fontsize(14, 'points')

saveas(gcf, 'current_wake_length_comparison.png');
saveas(gcf, 'current_wake_length_comparison.fig');