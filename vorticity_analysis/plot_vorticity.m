%plot voriticity

clear; clc;

basePath = 'D:\hydroponics_PIV\trial_4_3_2026\';

folders = {'flow_A','flow_B','flow_C','flow_D'};

% Optional: label Reynolds numbers manually
Re_labels = {'Re_A','Re_B','Re_C','Re_D'};

porosity = {'36% Solid', '27% Solid','23% Solid', '19% Solid', 'Solid'};


% Store all data
allData = struct();
color_array = nebula(5);

% Load all data
for i = 1:length(folders)
    
    filePath = fullfile(basePath, folders{i}, 'vorticity_param.mat');
    S = load(filePath);
    
    fieldNames = fieldnames(S);

    Re_num = S.(fieldNames{1});
    data = S.(fieldNames{2});

    for j = 1:length(porosity)
        figure(j); % 64% porosity start, solid end
        plot(smooth(data{j, 2}), smooth(data{j, 3}), '-', 'Color', color_array(i, :), 'LineWidth', 1.5, 'DisplayName', ['Re:', num2str(Re_num)]); hold on
        plot(smooth(data{j, 2}), smooth(data{j, 4}), '-', 'Color', color_array(i, :), 'LineWidth', 1.5, 'DisplayName', data{j, 1}, 'HandleVisibility','off'); hold on
    end
end

for j = 1:length(porosity)
    figure(j); % 64% porosity
    title([porosity{j} ' case'])
    xline(0, '--k', 'HandleVisibility','off')
    ylim([-10 10])
    xlim([-1 4.5])
    xlabel('x/D');
    ylabel('\omega D / U_\infty');
    fontsize(14, 'points')
    legend();
    saveas(gcf, ['nondim_vorticity_comparison_reynolds_',porosity{j}, '.png'])
end

