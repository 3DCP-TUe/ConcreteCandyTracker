%{
This file is part of Concrete Candy Tracker. Concrete Candy Tracker is 
licensed under the terms of GNU General Public License as published by 
the Free Software Foundation. For more information and the LICENSE file, 
see <https://github.com/3DCP-TUe/ConcreteCandyTracker>.
%}

% GET_SUBSET Extracts a time-windowed subset of data relative to a start time
%
%   subset = GET_SUBSET(start_time, data, window)
%
%   This function extracts a portion of a dataset based on a time window
%   relative to a specified start time (e.g., the time an impulse or step
%   input is applied). The output includes a new column 'response_time'
%   representing time relative to the start event.
%
%   Inputs:
%       start_time - Duration or datetime indicating the reference start time
%       data       - Table containing time-series data. Must include a column
%                    named 'Time' or 'time'.
%       window     - Two-element vector [t_start, t_end] specifying the relative
%                    time window (in the same units as data.Time) to extract
%
%   Outputs:
%       subset     - Table containing only the rows within the specified window.
%                    Adds a 'response_time' column representing time relative
%                    to start_time.
%
%   Notes:
%       - The input time column must be sorted in ascending order.
%       - The window vector must be sorted: window(1) < window(2).
%       - The function will throw an error if the resulting subset is empty.
%
%   Example:
%       subset = get_subset(step_up_time, data, [seconds(0) seconds(600)]);
function subset = get_subset(start_time, data, window)
            
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