%{
This file is part of Concrete Candy Tracker. Concrete Candy Tracker is licensed under the 
terms of GNU General Public License as published by the Free Software Foundation. For more 
information and the LICENSE file, see <https://github.com/3DCP-TUe/ConcreteCandyTracker>.
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

%% Impulse times
impulses = ["11:42:39.000", "13:42:40.000", "12:59:45.000", "13:20:42.000"];
colors = ["k", "k", "b", "b"];

%% Get time in minutes and seconds
% Candy
candy.('seconds') = seconds(candy.('Time')) - seconds(candy.('Time')(1));
candy.('minutes') = minutes(candy.('Time')) - minutes(candy.('Time')(1));
% Impulses
durations = duration(impulses, 'InputFormat', 'hh:mm:ss.SSS');
impulsesSeconds = seconds(durations) - seconds(candy.('Time')(1));

%% Remove the outliers
% Settings
k = 15; % Window size at each side of the sample
sampleRate = height(candy) / (max(candy.('seconds')) - min(candy.('seconds')));
nSigma = 6; 
% Find the outliers
outliers = zeros(height(candy), 1);
for column = ["L_", "a_", "b_", "R", "G", "B"]
    [~, outlier, ~, ~] = hampel(candy.(column), k, nSigma);
    outliers = outliers | outlier; % Logical OR to accumulate outliers
end
% Remove the outliers
candy(outliers, :) = [];
% Display result
fprintf('Removed %d outliers\n', sum(outliers))

%% Signal filtering
k = 40;
candy.('L_') = movmean(candy.('L_'), k);
candy.('a_') = movmean(candy.('a_'), k);
candy.('b_') = movmean(candy.('b_'), k);

%% Calculate delta t
candy.('dt') = candy.('seconds') - circshift(candy.('seconds'), 1);
candy.('dt')(1) = 0;

%% Estimate tracer concentration
candy.('concentration') = candy.('a_');

%% Get and plot residence time distrubution (RTD) from impulse inputs
fig = figure;
fig.Units = 'centimeters';
fig.Position = [1 14 24 8];
hold on
grid on
box on
% Window for subSet in seconds
before = 1*60;
after = 25*60;
% Values for base line correction in seconds
t1a = 4*60;     % Start plateau one
t1b = 5*60;     % End plateau one
t2a = 24*60;    % Start plateau two
t2b = 25*60;    % End plateau two
% Store RTD
rtd = cell(length(impulsesSeconds), 1);
for i = 1:length(impulsesSeconds)
    % Select window
    t0 = impulsesSeconds(i) - before;
    t1 = impulsesSeconds(i) + after;
    [~, indexStart] = min(abs(candy.('seconds')-t0));
    [~, indexEnd] = min(abs(candy.('seconds')-t1));
    % Get sub set
    subSet = candy(indexStart:indexEnd, :);
    % Time is zero when impulse was applied
    subSet.('seconds') = subSet.('seconds') - impulsesSeconds(i);
    subSet.('minutes') = subSet.('minutes') - impulsesSeconds(i)/60;
    % Base line correction
    [~, index0] = min(abs(subSet.('seconds')-t1a)); % Index start
    [~, index1] = min(abs(subSet.('seconds')-t1b)); % Index end
    [~, index2] = min(abs(subSet.('seconds')-t2a)); % Index start
    [~, index3] = min(abs(subSet.('seconds')-t2b)); % Index end
    mean1 = mean(subSet(index0:index1, subSet.Properties.VariableNames).('concentration'));
    mean2 = mean(subSet(index2:index3, subSet.Properties.VariableNames).('concentration'));
    mean3 = (mean1 + mean2) / 2;
    subSet.('concentration') = subSet.('concentration') - mean3;
    % Normalize
    dt = subSet(index0:index3, :).('dt');
    concentration = subSet(index0:index3, :).('concentration');
    area = sum(dt.*concentration);
    subSet.('concentration') = subSet.('concentration') / area;
    % Plot 
    plot(subSet.('minutes'), subSet.('concentration')*100, '-', 'MarkerSize', 0.25, 'Color', colors(i))
    % Store RTD
    rtd{i} = subSet;
end
% Layout of horizontal axis
xlabel('Time [minutes]')
xlim([-before/60 after/60])
% Layout of vertical axis
ylabel('E(t) x 10^{-2}')
ylim([-0.1 0.8])
% Write figure
saveFigure(fig, 'rtd')

%% Calculate residence time properties from impulse inputs
% Initialize table with properties
types = ["string", repmat("double", 1, 8)];
names = ["Time", "Mean", "Variance", "Standard Deviation", "P1", "P5", "P50", "P95", "P99"];
properties = table('Size', [length(impulses) 9], 'VariableTypes', types, 'VariableNames', names);
% Calculate properties
for i = 1:length(rtd)
    % Get subset
    data = rtd{i};
    [~, indexStart] = min(abs(data.('seconds')));
    data = data(indexStart:end, :);
    % Mean and variance
    ave = sum(data.('seconds').*data.('concentration').*data.('dt'));
    var = sum(data.('seconds').^2.*data.('concentration').*data.('dt'))-ave^2;
    % Percentiles
    data.('cumulative') = cumsum(data.('concentration').*data.('dt'));
    percentiles = [0.01, 0.05, 0.50, 0.95, 0.99];
    pValues = zeros(size(percentiles));
    for j = 1:length(percentiles)
        [~, index] = min(abs(data.('cumulative') - percentiles(j)));
        pValues(j) = data.('seconds')(index);
    end
    % Add values to table
    properties(i,:) = array2table([impulses(i), ave, var, sqrt(var), pValues]); 
end
% Display the table
disp(properties)
% Write table
writetable(properties, 'rtd_properties.csv', 'Delimiter' ,',')

%% End
disp('End of script')

%% Functions
% Write figure
function [] = saveFigure(fig, name) 
    fig.Units = 'inches';
    width = fig.Position(3);
    height = fig.Position(4);
    set(gcf, 'PaperPosition', [0 0 width height]);
    set(gcf, 'PaperSize', [width height]); 
    saveas(fig, name, 'pdf')
end