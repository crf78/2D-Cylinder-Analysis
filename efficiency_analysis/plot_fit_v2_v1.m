%author: Crystal + Chatgpt

table = readtable('D:\hydroponics_PIV\trial_4_3_2026\compare_v2_v1_new_flux.csv');
V2 = table.V2; 
V1 = table.V1; 
Re = table.Re_num;
solid_frac = table.solid_frac;
Da = table.Da;

% Compute shear layer growth factor
shear_ratio = abs(V2 - V1) ./ (V2 + V1);

% Plot
figure;
hold on;

Re_unique = unique(Re);
Cmap1 = winter(length(Re_unique));
for i = 1:length(Re_unique)
    idx = Re == Re_unique(i);
    plot(Da(idx), shear_ratio(idx), '--o', 'Color', Cmap1(i, :),'LineWidth',1.5,'DisplayName', ['Re = ' num2str(Re_unique(i))]);
end

xlabel('Darcy Number');
ylabel('(V_2 - V_1) / (V_2 + V_1)');
title('Shear Layer Growth Parameter');
legend;
grid on;

D = 0.044; % example diameter
N = 0.065;  % empirical constant (adjust later)

L = (D / N) .* ((V2 + V1) ./ abs(V2 - V1));

% Plot wake length
figure(2);
hold on;

for i = 1:length(Re_unique)
    idx = Re == Re_unique(i);
    plot(Da(idx), L(idx), '--o', 'Color', Cmap1(i, :),'LineWidth',1.5, 'DisplayName', ['Re = ' num2str(Re_unique(i)) ' Theo.']); hold on;
end

xlabel('Darcy Number');
ylabel('Predicted Wake Length');
title('Wake Length Prediction from Shear Layer Model');
legend;
grid on;

%

% Import Data
T = readtable('D:\hydroponics_PIV\trial_4_3_2026\wake_length_compare.csv');


% Convert porosity from string ("54%") to numeric
T.porosity = str2double(erase(T.porosity,"%"));
porosity_array = unique(T.porosity);

% Get unique velocities
vel = unique(T.u_infty);
Re_array = round((1000.*(0.044)*vel) / (0.001), 0); % reynolds number

% Create tiled figure
figure(2)
% figure()
% tiledlayout(1,3)

% ================================
% Traditional Wake Length
% ================================
% nexttile
% hold on
symbols = {'*', 'o', '^', '+','<', '>'};
Cmap1 = winter(length(Re_array));
for i = 1:length(Re_array)

    idx = T.u_infty == vel(i);
    Da = T.Da(idx);
    % y = T.trad_wake_length(idx);
    y = T.wake_dead(idx);
    

    % % Remove NaNs
    % valid = ~isnan(y);
    % p = Da(valid);
    % y = y(valid);
    % 
    % % Sort to prevent zig-zag
    % [p_sorted, order] = sort(p);
    % y_sorted = y(order);

    plot(Da,y,'-sq', 'Color', Cmap1(i, :), 'LineWidth', 1.5, 'DisplayName', ['Re = ' num2str(Re_array(i))]);

end
legend
ylim([0 5])
xlabel('Da')
ylabel('Wake Length ($u < 0.1U_{\infty}$)', Interpreter='latex')
% title('Traditional Wake ($\bar{u} = 0.90U_{\infty}$)', Interpreter='latex')
grid on
fontsize(14, 'points')

%%
% ================================
% Dead Wake Length
% ================================
nexttile
hold on

for i = 1:length(Re_array)

    % idx = T.u_infty == vel(i);
    idx = T.u_infty == vel(i);

    Da = T.Da(idx);
    y = T.wake_dead(idx);

    valid = ~isnan(y);
    p = Da(valid);
    y = y(valid);

    [p_sorted, order] = sort(p);
    y_sorted = y(order);

    % plot(p_sorted,y_sorted,'-o','LineWidth',2, 'Color', Cmap1(i, :))
    plot(Da,y,'-o', 'Color', Cmap1(i, :), 'LineWidth', 1.5); hold on;
    % scatter(Re.*ones(length(y_sorted), 1), y_sorted,'-o','LineWidth',2, 'Color', Cmap1(i, :))

end
ylim([0 4])
% xlabel('Porosity (%)')
xlabel('Da')
ylabel('Dead Zone Length ($x/D$)', Interpreter='latex')
title('Dead Zone Wake ($\bar{u} < 0.1 U_{\infty}$)', Interpreter='latex')
grid on

% ================================
% Velocity Recovery Metric
% ================================
nexttile
hold on

for i = 1:length(Re_array)

    % idx = T.u_infty == vel(i);
    idx = T.u_infty == vel(i);

    Da = T.Da(idx);
    y = T.wake_compare(idx);

    valid = ~isnan(y);
    p = Da(valid);
    y = y(valid);

    [p_sorted, order] = sort(p);
    y_sorted = y(order);

    plot(Da,y,'-o', 'Color', Cmap1(i, :), 'LineWidth', 1.5); hold on;
    % scatter(Re.*ones(length(y_sorted), 1), y_sorted,'-o','LineWidth',2, 'Color', Cmap1(i, :))

end
ylim([-0.5 4])
% xlabel('Porosity (%)')
% xlabel('Da')
xlabel('Da')
ylabel('Recovery Metric ($\bar{u}/U_{\infty}$)', Interpreter='latex')
title('Velocity Recovery at 3D')
grid on

%Add legend (apply to whole layout)
% legend(string(vel) + " m/s",'Location','bestoutside')
legend('Re:'+string(Re_array(1)),'Re:'+string(Re_array(2)), 'Re:'+string(Re_array(3)),'Location','bestoutside')

% saveas(gcf, 'wake_lengths_compare.png');
% saveas(gcf, 'wake_lengths_compare.fig');