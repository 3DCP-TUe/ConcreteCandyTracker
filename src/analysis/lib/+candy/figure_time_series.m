% SPDX-License-Identifier: GPL-3.0-or-later
% Concrete Candy Tracker
% Project: https://github.com/3DCP-TUe/ConcreteCandyTracker
%
% Copyright (c) 2023-2025 Eindhoven University of Technology
%
% Authors:
%   - Arjen Deetman (2023-2025)
%
% For license details, see the LICENSE file in the project root.

function fig = figure_time_series(xticks, xlimits)
% FIGURE_TIME_SERIES Creates a standardized time series figure layout
%
%   fig = FIGURE_TIME_SERIES(xticks, xlimits)
%
%   This function initializes a figure for time series plotting with a
%   standardized layout, grid, box, font size, and figure dimensions.
%   The x-axis is formatted to display time in HH:MM format, and the axis
%   limits are set according to the input range.
%
%   Inputs:
%       xticks   - Array of datetime values specifying x-axis tick positions
%       xlimits  - Two-element datetime array specifying x-axis limits
%
%   Outputs:
%       fig      - Handle to the created figure
%
%   Example:
%       t = datetime(2025,8,20,0,0,0):minutes(30):datetime(2025,8,20,12,0,0);
%       fig = figure_time_series(t, [t(1), t(end)]);
%
%   Notes:
%       - A temporary dummy plot is created to allow setting x-axis ticks
%         correctly; it is deleted before returning the figure handle.
%       - The figure size and layout are predefined for consistent
%         formatting in publications.

%------------- BEGIN CODE --------------

    % Initialize figure
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
    
    % Layout x-axis
    % Dummy plot is needed since correct ticks (with clock time)
    % cannot be added on an empty axis. 
    dum = plot([xlimits(1)-duration(1,0,0), ...
        xlimits(2)+duration(1,0,0)], [0, 0]);
    set(gca, 'XTick',  xticks, 'XTickLabel', ...
        datestr(xticks, 'HH:MM'))
    xlim(xlimits)
    xlabel('Time', 'interpreter', 'latex')
    delete(dum);
end