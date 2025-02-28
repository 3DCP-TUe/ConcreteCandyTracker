%{
This file is part of Concrete Candy Tracker. Concrete Candy Tracker is 
licensed under the terms of GNU General Public License as published by 
the Free Software Foundation. For more information and the LICENSE file, 
see <https://github.com/3DCP-TUe/ConcreteCandyTracker>.

Example script to extract the residence time distribution and its 
properties from the acquired data. 
%}

%% Clear and close

format shortG;
close all;
clear;
clc;

%% Get file path

path = mfilename('fullpath');
[filepath, name, ext] = fileparts(path);
cd(filepath);

%% Import data

candy = readtable('20240506_Tracer_MAI_MULTIMIX.csv');
impulses = ["11:42:39.000", "13:42:40.000", "12:59:45.000", "13:20:42.000"];

%% Get time in minutes and seconds

% Candy
candy.seconds = seconds(candy.Time) - seconds(candy.Time(1));
candy.minutes = minutes(candy.Time) - minutes(candy.Time(1));

% Impulses
durations = duration(impulses, 'InputFormat', 'hh:mm:ss.SSS');
impulse_seconds = seconds(durations) - seconds(candy.Time(1));

%% Remove the outliers

% Settings
k = 15; % Window size at each side of the sample
sample_rate = height(candy) / (max(candy.seconds) - min(candy.seconds));
n_sigma = 6; 

% Find the outliers
outliers = zeros(height(candy), 1);
for column = ["L_", "a_", "b_", "R", "G", "B"]
    [~, outlier, ~, ~] = hampel(candy.(column), k, n_sigma);
    outliers = outliers | outlier; % Logical OR to accumulate outliers
end

% Remove the outliers
candy(outliers, :) = [];

% Display result
fprintf('Removed %d outliers\n', sum(outliers))

%% Signal filtering

k = round(sample_rate); % 1 second
candy.L_ = movmean(candy.L_, k, 'omitnan');
candy.a_ = movmean(candy.a_, k, 'omitnan');
candy.b_ = movmean(candy.b_, k, 'omitnan');

%% Calculate delta t

candy.dt = candy.seconds - circshift(candy.seconds, 1);
candy.dt(1) = 0;

%% Estimate tracer concentration

% This is an example, check this with a calibration curve for your material
candy.concentration = candy.a_;

%% Get and plot residence time distrubution (RTD) from impulse inputs

% Initialize figure
fig = default_layout_wide();
colors = [[0,0,0]; [0,0,0]; [0.5,0.5,0.5]; [0.5,0.5,0.5]];


% Plot dummy for legend
dum1 = plot([-1, -1], [-1, -1], '.', 'MarkerSize', 16, 'Color', colors(1,:));
dum2 = plot([-1, -1], [-1, -1], '.', 'MarkerSize', 16, 'Color', colors(2,:));
dum3 = plot([-1, -1], [-1, -1], '.', 'MarkerSize', 16, 'Color', colors(3,:));
dum4 = plot([-1, -1], [-1, -1], '.', 'MarkerSize', 16, 'Color', colors(4,:));

% Window size for subset in seconds
before = 1*60;
after = 25*60;

% Values for base line correction in seconds
t1a = 4*60;     % Start plateau one
t1b = 5*60;     % End plateau one
t2a = 24*60;    % Start plateau two
t2b = 25*60;    % End plateau two

% Store RTD
rtd = cell(length(impulse_seconds), 1);     % Store RTD to calculate properties later
areas = zeros(length(impulse_seconds), 1);  % Store area for calibration purposes

for i = 1:length(impulse_seconds)
    
    % Select window
    t0 = impulse_seconds(i) - before;
    t1 = impulse_seconds(i) + after;
    [~, index_start] = min(abs(candy.seconds-t0));
    [~, index_end] = min(abs(candy.seconds-t1));
    
    % Get subset
    subset = candy(index_start:index_end, :);
    
    % Time is zero when impulse was applied
    subset.seconds = subset.seconds - impulse_seconds(i);
    subset.minutes = subset.minutes - impulse_seconds(i)/60;
    
    % Base line correction
    [~, index0] = min(abs(subset.seconds-0.0)); % Index t=0
    [~, index1] = min(abs(subset.seconds-t1a)); % Index start
    [~, index2] = min(abs(subset.seconds-t1b)); % Index end
    [~, index3] = min(abs(subset.seconds-t2a)); % Index start
    [~, index4] = min(abs(subset.seconds-t2b)); % Index end
    mean1 = mean(subset.concentration(index1:index2), 'omitnan');
    mean2 = mean(subset.concentration(index3:index4), 'omitnan');
    mean3 = (mean1 + mean2) / 2;
    subset.concentration = subset.concentration - mean3;
    
    % Normalize
    dt = subset.dt(index0:index4);
    concentration = subset.concentration(index0:index4);
    area = sum(dt.*concentration);
    subset.rtd = subset.concentration / area;
    
    % Plot 
    plot(subset.minutes, subset.rtd*100, '-', 'MarkerSize', 0.25, 'Color', colors(i,:))
    
    % Store RTD and area
    rtd{i} = subset;
    areas(i) = area;

    % Write table
    time = duration(0, 0, subset.seconds);
    time.Format = 'hh:mm:ss.SSS';
    subset.Time.Format = 'hh:mm:ss.SSS';
    T1 = table(subset.Time, time, subset.concentration,...
        subset.R,  subset.G,  subset.B, ...
        subset.X,  subset.Y,  subset.Z, ...
        subset.L_, subset.a_, subset.b_, ...
        'VariableNames', {'time', 'time_response', 'rtd', ...
        'R', 'G', 'B', ...
        'X', 'Y', 'Z', ...
        'L', 'a', 'b'});
    writetable(T1, "rtd_" + i + ".csv")
end

% Layout of horizontal axis
xlabel('Time [minutes]', 'Interpreter', 'latex')
xlim([-before/60 after/60])
% Layout of vertical axis
ylabel('E(t) $\times$ $10^{-2}$', 'Interpreter', 'latex')
ylim([-0.1 0.8])

% Write figure
save_figure(fig, 'rtd')

%% Calculate residence time properties from impulse inputs

% Initialize table with properties
types = ["string", "string", repmat("double", 1, 9)];
names = ["time", "file_name", "area", "mean", "variance", "std", "p1", "p5", "p50", "p95", "p99"];
properties = table('Size', [length(impulses) 11], 'VariableTypes', types, 'VariableNames', names);

% Calculate properties
for i = 1:length(rtd)
    
    % Get subset
    data = rtd{i};
    [~, index_start] = min(abs(data.seconds));
    data = data(index_start:end, :);
    
    % Mean and variance
    ave = sum(data.seconds.*data.rtd.*data.dt);
    var = sum(data.seconds.^2.*data.rtd.*data.dt)-ave^2;
    
    % Percentiles
    data.cumulative = cumsum(data.rtd.*data.dt);
    percentiles = [0.01, 0.05, 0.50, 0.95, 0.99];
    percentiles_values = zeros(size(percentiles));
    for j = 1:length(percentiles)
        [~, index] = min(abs(data.cumulative - percentiles(j)));
        percentiles_values(j) = data.seconds(index);
    end
    
    % Add values to table
    properties(i,:) = array2table([impulses(i), "rtd_" + i + ".csv", areas(i), ave, var, sqrt(var), percentiles_values]); 
end

% Display the table
disp(properties)

% Write table
writetable(properties, 'rtd_properties.csv', 'Delimiter' ,',')

%% End
disp('End of script')

%% Functions

% Write figure
function [] = save_figure(fig, name) 
    width = fig.Position(3);
    height = fig.Position(4);
    set(gcf, 'PaperPosition', [0 0 width height]);
    set(gcf, 'PaperSize', [width height]); 
    saveas(fig, name, 'pdf')
end

% Figure layout
function fig = default_layout_wide()
    fig = figure;
    hold on
    grid on
    box on
    set(gca, 'FontSize', 24);
    set(gca,'YColor',[0,0,0])
    set(gca,'XColor',[0,0,0])
    set(gcf, 'PaperUnits', 'inches');
    set(gcf, 'Units', 'inches');
    fig_width = 3^(3/2)/7*18;
    fig_height = 3^(3/2); 
    set(gcf, 'PaperPosition', [0 0 fig_width fig_height]); 
    set(gcf, 'PaperSize', [fig_width fig_height]); 
    set(gcf, 'Position', [1 1 fig_width, fig_height]);
end