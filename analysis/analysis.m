%{
This file is part of Concrete Candy Tracker. Concrete Candy Tracker is licensed under the 
terms of GNU General Public License as published by the Free Software Foundation. For more 
information and the LICENSE file, see <https://github.com/3DCP-TUe/ConcreteCandyTracker>.
%}

%% Clear and close
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
%TODO

%% Get time in minutes and seconds
candy.('seconds') = seconds(candy.('Time')) - seconds(candy.('Time')(1));
candy.('minutes') = minutes(candy.('Time')) - minutes(candy.('Time')(1));

%% Remove the outliers
% Settings
k = 15; % Window size at each side of the sample
sampleRate = height(candy) / (max(candy.('seconds')) - min(candy.('seconds')));
nSigma = 6; 
% Find the outliers
outliers = zeros(height(candy), 1);
for column = ["L_", "a_", "b_", "R", "G", "B"]
    [~, outlier, ~, ~] = hampel(candy.(column), k, nSigma);
    outliers = outliers + outlier;
end
% Remove the outliers
indices = find(outliers == 0);
candy = candy(indices, candy.Properties.VariableNames);
nOutliers = sum(outliers ~= 0);
% Display results
fprintf('Removed %d outliers\n', nOutliers)

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
%TODO

%% Calculate residence time properties from impulse inputs
%TODO

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