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

function subset = get_subset(start_time, data, window)
%GET_SUBSET Extracts a time-windowed subset of data relative to a start time
%
% This function extracts a portion of a dataset based on a time window
% relative to a specified start time (e.g., the time an impulse or step
% input is applied). The output includes a new column 'response_time'
% representing time relative to the start event. All time quantities are
% handled as MATLAB durations.
%
% Syntax: subset = get_subset(start_time, data, window)
%
% Inputs:
%   start_time - Scalar duration indicating the reference start time
%   data       - Table containing time-series data; must include a column
%                named 'Time' or 'time' (durations, sorted ascending)
%   window     - Two-element duration vector [t_start t_end] specifying the
%                relative time window to extract
%
% Outputs:
%   subset     - Table containing only the rows within the specified window;
%                adds a 'response_time' column (duration) representing time
%                relative to START_TIME
%
% Notes:
%   - If the input table lacks 'Time' but has 'time', it is copied to 'Time'.
%   - The input time column must be sorted ascending.
%   - The window vector must be sorted: window(1) < window(2).
%   - Indices are selected by nearest samples to START_TIME + window(1:2)
%     and clamped to table bounds.
%   - The function errors if the resulting subset is empty.
%   - The 'response_time' format is set to 'hh:mm:ss.SSS'.
%
% Example:
%   subset = get_subset(seconds(0), data, [seconds(0) seconds(600)]);


%------------- BEGIN CODE --------------

    % Ensure input windows are sorted
    if ~issorted(window)
        error('Window must be sorted: window(1) < window(2).');
    end

    % Check if column time or Time is defined
    if ~ismember("Time", data.Properties.VariableNames)
        
        if ~ismember("time", data.Properties.VariableNames)
            error("Column 'Time' or 'time' is missing in the dataset.");
        end
        
        data.Time = data.time;
    end

    % Ensure time is sorted
    if ~issorted(data.Time)
        error('Time column must be sorted.');
    end

    % Select window indices
    [~, index_start] = min(abs(data.Time - start_time - window(1)));
    [~, index_end] = min(abs(data.Time - start_time - window(2)));

    % Ensure indices are valid
    index_start = max(1, min(index_start, height(data)));
    index_end = max(1, min(index_end, height(data)));

    % Extract subset
    subset = data(index_start:index_end, :);

    % Ensure subset is not empty
    if isempty(subset)
        error('Subset of data is empty. Check the window selection.');
    end

    % Set time relative to application of impulse input
    subset.response_time = subset.Time - start_time;
    subset.response_time.Format = 'hh:mm:ss.SSS';
end