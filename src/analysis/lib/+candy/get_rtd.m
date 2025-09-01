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

function [rtd, area] = get_rtd(impulse_time, data, window, window_start, window_end)
%GET_RTD Computes the Residence Time Distribution (RTD) from impulse response
%
% This function calculates the residence time distribution (RTD) from
% experimental impulse-response data. It performs baseline correction,
% normalizes the response by the area under the corrected curve, and
% returns a table suitable for further analysis. All time quantities are
% handled as MATLAB durations.
%
% Syntax: [rtd, area] = get_rtd(impulse_time, data, window, window_start, window_end)
%
% Inputs:
%   impulse_time - Scalar duration specifying the impulse event time
%   data         - Table containing the experimental data; must include
%                  a 'concentration' column and a 'Time' or 'time' column
%                  (time stamps are durations and sorted ascending)
%   window       - Two-element duration vector specifying the time window
%                  around the impulse event to consider
%   window_start - Two-element duration vector specifying the start window
%                  used for baseline correction
%   window_end   - Two-element duration vector specifying the end window
%                  used for baseline correction and normalization
%
% Outputs:
%   rtd          - Table containing the normalized RTD and auxiliary columns:
%                    - time          : original time values (duration)
%                    - time_response : time relative to impulse (duration)
%                    - value         : normalized RTD (unitless)
%                    - R, G, B, X, Y, Z, L, a, b : added if missing, filled with NaN
%   area         - Scalar double representing the area under the corrected
%                  concentration curve used for normalization (units:
%                  concentration·seconds)
%
% Notes:
%   - If the input table lacks 'Time' but has 'time', it is copied to 'Time'.
%   - Input time vectors must be sorted ascending; otherwise an error is thrown.
%   - Baseline correction level is the average of the mean concentration in
%     WINDOW_START and the mean in WINDOW_END (both computed with 'omitnan').
%   - Normalization area is computed over the interval starting at the sample
%     closest to time_response == 0 up to WINDOW_END(2).
%   - If AREA == 0, the RTD (value) is set to zeros to avoid division by zero.
%   - Missing columns (R, G, B, X, Y, Z, L, a, b) are created and filled with NaN.
%   - All windows and IMPULSE_TIME are durations, consistent with the
%     'time_response' axis returned by the extracted subset.
%   - NaNs in the concentration series propagate into AREA and the RTD unless
%     removed by preprocessing; ensure data is cleaned as needed.
%
% Example:
%   data = readtable('experiment.csv');
%   impulse_time = seconds(0);
%   [rtd, area] = get_rtd(impulse_time, data, ...
%       [seconds(0) seconds(60)], [seconds(0) seconds(10)], [seconds(50) seconds(60)]);

    
%------------- BEGIN CODE --------------

    % Check if column concentration is defined
    if ~ismember("concentration", data.Properties.VariableNames)
        error("Column 'concentration' is missing in the dataset.");
    end

    % Ensure input windows are sorted
    if ~issorted(window)
        error('Window must be sorted: window(1) < window(2).');
    end
    if ~issorted(window_start)
        error('Window start must be sorted: window_start(1) < window_start(2).');
    end
    if ~issorted(window_end)
        error('Window tail must be sorted: window_end(1) < window_end(2).');
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

    % Extract subset
    subset = candy.get_subset(impulse_time, data, window);
        
    % Compute time differences
    subset.dt = [0; diff(seconds(subset.Time))];

    % Baseline correction indices
    [~, index0] = min(abs(subset.response_time)); % t = 0
    [~, index1] = min(abs(subset.response_time - window_start(1))); % Start
    [~, index2] = min(abs(subset.response_time - window_start(2))); % End
    [~, index3] = min(abs(subset.response_time - window_end(1))); % Start tail
    [~, index4] = min(abs(subset.response_time - window_end(2))); % End tail

    % Ensure indices are in correct order and within bounds
    index0 = max(1, min(index0, height(subset)));
    index1 = max(1, min(index1, height(subset)));
    index2 = max(1, min(index2, height(subset)));
    index3 = max(1, min(index3, height(subset)));
    index4 = max(1, min(index4, height(subset)));

    % Compute baseline correction
    mean1 = mean(subset.concentration(index1:index2), 'omitnan');
    mean2 = mean(subset.concentration(index3:index4), 'omitnan');
    mean3 = (mean1 + mean2) / 2;
    subset.concentration = subset.concentration - mean3;

    % Normalize
    dt = subset.dt(index0:index4);
    concentration = subset.concentration(index0:index4);
    area = sum(dt .* concentration);

    if area == 0
        subset.rtd = zeros(size(subset.concentration));
    else
        subset.rtd = subset.concentration ./ area;
    end

    % Add missing columns (make it suitable for other applications)
    columns = {'R', 'G', 'B', 'X', 'Y', 'Z', 'L_', 'a_', 'b_'};
    for i = 1:length(columns)
        if ~ismember(columns{i}, subset.Properties.VariableNames)
            subset.(columns{i}) = nan(height(subset), 1);
        end
    end

    % Construct result table
    rtd = table(subset.Time, subset.response_time, subset.rtd, ...
        subset.R, subset.G, subset.B, ...
        subset.X, subset.Y, subset.Z, ...
        subset.L_, subset.a_, subset.b_, ...
        'VariableNames', {'time', 'time_response', 'value', ...
        'R', 'G', 'B', 'X', 'Y', 'Z', 'L', 'a', 'b'});
end