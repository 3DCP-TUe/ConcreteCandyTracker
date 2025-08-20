%{
This file is part of Concrete Candy Tracker. Concrete Candy Tracker is 
licensed under the terms of GNU General Public License as published by 
the Free Software Foundation. For more information and the LICENSE file, 
see <https://github.com/3DCP-TUe/ConcreteCandyTracker>.
%}

%{
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

%% Add lib

addpath('lib');

%% Import data

data = readtable('20240506_Tracer_MAI_MULTIMIX.csv');
impulses = duration(["11:42:39.000", "13:42:40.000", "12:59:45.000", "13:20:42.000"]);

%% Get sample rate

sample_rate = height(data) / (seconds(data.Time(end) - data.Time(1)));

%% Remove the outliers

sigma = 6;
k = round(sample_rate); % 1 second
[data, n] = candy.remove_outliers(data, k, sigma);

% Display result
fprintf('Removed %d outliers\n', n)

%% Signal filtering

k = round(sample_rate); % 1 second
data.L_ = movmean(data.L_, k, 'omitnan');
data.a_ = movmean(data.a_, k, 'omitnan');
data.b_ = movmean(data.b_, k, 'omitnan');

%% Estimate tracer concentration

% This is an example assumming a linear relation between a* and the
% concentration. Check this with a calibration curve for your material. 
data.concentration = data.a_;

%% Get and plot residence time distrubution (RTD) from impulse inputs

% Window start and end
window = duration(["-00:01:00", "00:25:00"]);

% Initialize figure
xticks = duration(minutes(-5:5:60));
fig = candy.figure_time_series(xticks, window);
colors = [[0,0,0]; [0,0,0]; [0.5,0.5,0.5]; [0.5,0.5,0.5]];

% Window for baseline correction
window_start = duration(["00:04:00", "00:05:00"]);
window_tail = duration(["00:24:00", "00:25:00"]);

% Store RTD and areas
rtds = cell(length(impulses), 1);     % Store RTD to calculate properties later
areas = zeros(length(impulses), 1);  % Store area for calibration purposes

for i = 1:length(impulses)

    % Get RTD curve
    [temp, area] = candy.get_rtd(impulses(i), data, window, window_start, window_tail);

    % Plot 
    plot(temp.time_response, temp.rtd*100, '.', 'MarkerSize', 0.5, 'Color', colors(i,:))

    % Store RTD and area
    rtds{i} = temp;
    areas(i) = area;
end

% Layout of horizontal axis
xlabel('Time', 'Interpreter', 'latex')
xlim(window)
% Layout of vertical axis
ylabel('E(t) $\times$ $10^{-2}$', 'Interpreter', 'latex')
ylim([-0.1 0.8])

% Write figure
candy.save_figure(fig, 'rtd')

%% Calculate residence time properties from impulse inputs and write values

% Get properties
properties = candy.get_rtd_properties(impulses, rtds, areas);

for i = 1:length(rtds)
    
    % Set file name
    file_name = "rtd_" + i + ".csv";

    % Write table
    writetable(rtds{i}, file_name)

    % Set file name in table with properties
    properties.file_name(i) = file_name;
end

% Display the table
disp(properties)

% Write table
writetable(properties, 'rtd_properties.csv', 'Delimiter' ,',')

%% End
disp('End of script')