%author: Crystal + ChatGPT
%purpose: go through each of the trial folders and find the flux
%average fraction and then once it is complied, graph it. 

clc; clear;
% Specify the parent directory containing the folders
parentDirectory = 'D:\hydroponics_PIV\trial_4_3_2026\flow_B';

% Get a list of all items in the parent directory
items = dir(parentDirectory);
j = 0;
figure;
compiled_mean = {};
compiled_std = {};
compiled_phi = {};

line_colors = winter(5); 

% Iterate through all items
for i = 1:length(items)
    % Check if the item is a folder (excluding '.' and '..')
    if items(i).isdir && ~ismember(items(i).name, {'.', '..'})
        % Construct the path to the current folder
        folderPath = fullfile(parentDirectory, items(i).name);
        porosityFoldersNames = dir(parentDirectory + "\*_porosity");
        
        % Construct the path to the velocity_diff.mat file
        filePath = fullfile(folderPath, 'flux_variables.mat');
        
        % Check if the file exists
        if isfile(filePath)
            token = regexp(folderPath,'(\d+)_porosity','tokens');
            porosity = str2double(token{1}{1});
            solid_frac = abs(100-porosity); 
            % Load the .mat file
                data = load(filePath);
                j =  j + 1; 
                % Store the u_diff value in the structure
                % h = errorbar(data.phi, data.mean_flux, data.std_flux, Color=line_colors(j, :), LineWidth = 1.5, HandleVisibility='off'); hold on; 
                plot(data.phi, data.mean_flux./max(data.mean_flux), '-o', Color=line_colors(j, :), LineWidth = 1.5,DisplayName=['solid:', num2str(solid_frac), '%']); hold on; 
                

                % Set transparency level (0:1)
                alpha = 0.25;   
                % Set transparency (undocumented)
                % set([h.Bar, h.Line], 'ColorType', 'truecoloralpha', 'ColorData', [h.Line.ColorData(1:3); 255*alpha])
                % set(h.Cap, 'EdgeColorType', 'truecoloralpha', 'EdgeColorData', [h.Cap.EdgeColorData(1:3); 255*alpha])
                yline(mean(data.total_flux_array)./max(data.mean_flux), '--', Color=line_colors(j, :), LineWidth = 1.5, HandleVisibility="off"); hold on;
                compiled_mean{j, 1} = data.mean_flux;
                compiled_std{j, 1} = data.std_flux;
                compiled_phi{j, 1} = data.phi;
        end
    end
end
grid on; 

phi_example = linspace(1,360,360); 
%ideal case:
ideal_flux = (1-2.*sind(phi_example).^2); 
%uniform case: 
uniform_flux = -cosd(phi_example); 

% yline(0, 'k-', LineWidth = 1.5, HandleVisibility="off"); hold on;
plot(phi_example, ideal_flux, 'k-.', 'LineWidth', 1.5, 'HandleVisibility','on', 'DisplayName','Ideal flow: (1-2*sin(\phi)^2'); hold on; 
plot(phi_example, uniform_flux, 'k--', 'LineWidth', 1.5, 'HandleVisibility','on', 'DisplayName', 'Uniform flow: -cos(\phi)'); hold on; 
xlabel('Degrees over circle $(\circ)$', Interpreter='latex')
ylabel('$\frac{J_{0}}{J_{max}}$', 'Interpreter','latex')
xlim([0 360])
ylim([-1 1])
legend();
% legend('Trial 1', 'Trial 2', 'Trial 3');
fontsize(16, "points") % Increase the font size to 16 points
saveas(gcf, 'mean_flux_trials.fig')
saveas(gcf, 'mean_flux_trials.png')


% Specify the filename for the .csv file
mean_filename = 'mean_flux_compiled.xls';
std_filename = 'std_flux_compiled.xls';
phi_filename = 'phi_flux_compiled.xls';

% Save the combined cell array as a .csv file
writecell(compiled_mean, mean_filename);
writecell(compiled_std, std_filename);
writecell(compiled_phi,phi_filename);

%% plot the flux
clc; clear;
foldernames = {'D:\hydroponics_PIV\Previous PIV trials\Trial_2025_4_30\one_bucket\6_layers\';
    'D:\hydroponics_PIV\Previous PIV trials\Trial_2025_4_30\one_bucket\7_layers\';
    'D:\hydroponics_PIV\Previous PIV trials\Trial_2025_4_30\one_bucket\8_layers\'};
mean_filename = 'mean_flux_compiled.xls';
std_filename = 'std_flux_compiled.xls';
phi_filename = 'phi_flux_compiled.xls';

f1 = figure; 
f2 = figure; 
f3 = figure; 
for i=1:length(foldernames)
    mean_dataset = xlsread(strcat(foldernames{i}, mean_filename));
    std_dataset = xlsread(strcat(foldernames{i}, std_filename));
    phi_dataset = xlsread(strcat(foldernames{i}, phi_filename));
    for j=1:3 %five trials
        figure(i)
        scatter(phi_dataset(j, :), mean_dataset(j, :),  'o', 'LineWidth',1.5); hold on; 
        errorbar(phi_dataset(j, :), mean_dataset(j, :), std_dataset(j, :), 'o','LineWidth',1.5); hold on; 
    end
    hold off
    xlim([0 360])
    ylim([-6 12].*10^-5)
    grid on;
    ylabel('Mean Flux'); 
    xlabel('Degrees over bucket surface')
    title('Change in velocity over different bucket porosities')
    saveas(gcf, 'overall_flux_comparison.fig')
end

%% Calculate pos and neg flux

%purpose: go through each of the trial folders and find the flux
%difference and then once it is complied, graph it. 

clc; clear;
% Specify the parent directory containing the folders
parentDirectory = 'D:\hydroponics_PIV\Previous PIV trials\Trial_2025_4_30\one_bucket\6_layers';

% Get a list of all items in the parent directory
items = dir(parentDirectory);
j = 0;
figure;
compiled_pos_flux = {};
compiled_neg_flux = {};

% Iterate through all items
for i = 1:length(items)
    % Check if the item is a folder (excluding '.' and '..')
    if items(i).isdir && ~ismember(items(i).name, {'.', '..'})
        % Construct the path to the current folder
        folderPath = fullfile(parentDirectory, items(i).name);
        
        % Construct the path to the velocity_diff.mat file
        filePath = fullfile(folderPath, 'flux_variables.mat');
        
        % Check if the file exists
        if isfile(filePath)
            % Load the .mat file
                data = load(filePath);
                j =  j + 1; 
                % Store the u_diff value in the structure
                scatter(data.phi, data.total_flux_array); hold on; 
                pos_flux = 0; neg_flux = 0; 
                for n=1:length(data.mean_flux)
                    if data.mean_flux(n) > 0
                        pos_flux = data.mean_flux(n) + pos_flux; 
                    else
                        neg_flux = data.mean_flux(n) + neg_flux; 
                    end
                end
                compiled_pos_flux{j, 1} = pos_flux; 
                compiled_neg_flux{j, 1} = neg_flux; 
        end
    end
end
hold off; 
grid on; 
xlabel('Degrees over circle')
ylabel('Mean flux')
xlim([0 360])
saveas(gcf, 'mean_flux_trials.fig')


% Specify the filename for the .csv file
pos_filename = 'pos_flux_compiled.xls';
neg_filename = 'neg_flux_compiled.xls';

% Save the combined cell array as a .csv file
writecell(compiled_pos_flux, pos_filename);
writecell(compiled_neg_flux, neg_filename);

%% plot the pos and neg flux
clc; clear;
foldernames = {'D:\hydroponics_PIV\Previous PIV trials\Trial_2025_4_30\one_bucket\6_layers\';
    'D:\hydroponics_PIV\Previous PIV trials\Trial_2025_4_30\one_bucket\7_layers\';
    'D:\hydroponics_PIV\Previous PIV trials\Trial_2025_4_30\one_bucket\8_layers\'};
pos_filename = 'pos_flux_compiled.xls';
neg_filename = 'neg_flux_compiled.xls';
porosity = [16; 38; 51];

f1 = figure; 
f2 = figure;
f3 = figure;
for i=1:length(foldernames)
    pos_dataset = xlsread(strcat(foldernames{i}, pos_filename));
    neg_dataset = xlsread(strcat(foldernames{i}, neg_filename));
    total_flux = pos_dataset + neg_dataset; 
    figure(f1)
    scatter(porosity(i)*ones(3, 1), total_flux,  'o', 'LineWidth',1.5); hold on; 
    figure(f2)
    scatter(porosity(i)*ones(3, 1), pos_dataset,  'o', 'LineWidth',1.5); hold on; 
    figure(f3)
    scatter(porosity(i)*ones(3, 1), neg_dataset,  'o', 'LineWidth',1.5); hold on;
end
figure(f1)
hold off
% xlim([0 60])
% ylim([0 7.5].*10^-4)
grid on;
ylabel('Total Flux'); 
xlabel('% Porosity')
title('Total flux difference over different porosity')
saveas(gcf, 'diff_flux_comparison.fig')

figure(f2)
hold off
% xlim([0 60])
% ylim([0 7.5].*10^-4)
grid on;
ylabel('Positive Flux'); 
xlabel('% Porosity')
title('Incoming flux into bucket over different bucket porosity')
saveas(gcf, 'pos_flux_comparison.fig')

figure(f3)
hold off
% xlim([0 60])
% ylim([-5 0].*10^-4)
grid on;
ylabel('Negative Flux'); 
xlabel('% Porosity')
title('Outgoing flux into bucket over different bucket porosity')
saveas(gcf, 'neg_flux_comparison.fig')