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

function response = get_normalized_step_up_response(step_up_time, data, window, window_start, window_end)
%GET_NORMALIZED_STEP_UP_RESPONSE Normalizes step-up response data
%
% This function extracts a subset of experimental data around a step-up
% event, corrects for baseline offsets, and normalizes the response. It
% ensures that the concentration values are shifted to a zero baseline and
% scaled according to the average post-step-up response.
%
% Syntax: response = get_normalized_step_up_response(step_up_time, data, window, window_start, window_end)
%
% Inputs:
%   step_up_time - Scalar duration specifying the step-up event time
%   data         - Table containing the experimental data; must include a
%                  'concentration' column and a 'Time' or 'time' column
%   window       - Two-element duration vector specifying the time window
%                  around the step-up event to consider
%   window_start - Two-element duration vector specifying the start window
%                  for baseline normalization
%   window_end   - Two-element duration vector specifying the end window
%                  for scaling normalization
%
% Outputs:
%   response     - Table containing normalized response and auxiliary
%                  columns suitable for downstream analysis. Columns:
%                    - time          : original time values
%                    - time_response : time relative to step-up (duration)
%                    - value         : normalized concentration (unitless)
%                    - R, G, B, X, Y, Z, L, a, b : additional columns
%                      filled with NaNs if missing in input
%
% Notes:
%   - If the input table lacks 'Time' but has 'time', it is copied to 'Time'.
%   - Input time vectors must be sorted ascending; otherwise an error is thrown.
%   - Missing columns (R, G, B, X, Y, Z, L, a, b) are created and filled with NaN.
%   - Baseline (subtraction) is computed over WINDOW_START; scaling (division)
%     is computed over WINDOW_END.
%   - All windows and STEp_UP_TIME are expressed as durations, consistent with
%     the 'time_response' axis returned by the subset.
%
% Example:
%   data = readtable('experiment.csv');
%   step_up_time = seconds(0);
%   response = get_normalized_step_up_response(step_up_time, data, ...
%     [seconds(0) seconds(60)], [seconds(0) seconds(10)], [seconds(50) seconds(60)]);


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
    subset = candy.get_subset(step_up_time, data, window);

    % Compute time differences
    subset.dt = [0; diff(seconds(subset.Time))];

    % Baseline correction indices
    [~, index1] = min(abs(subset.response_time - window_start(1))); % Start
    [~, index2] = min(abs(subset.response_time - window_start(2))); % End
    [~, index3] = min(abs(subset.response_time - window_end(1))); % Start tail
    [~, index4] = min(abs(subset.response_time - window_end(2))); % End tail

    % Ensure indices are in correct order and within bounds
    index1 = max(1, min(index1, height(subset)));
    index2 = max(1, min(index2, height(subset)));
    index3 = max(1, min(index3, height(subset)));
    index4 = max(1, min(index4, height(subset)));

    % Normalize part 1: move to base line (0)
    mean1 = mean(subset.concentration(index1:index2), 'omitnan');
    subset.concentration = subset.concentration - mean1;

    % Normalize part 2: scale
    mean2 = mean(subset(index3:index4, subset.Properties.VariableNames).concentration, 'omitnan');
    subset.concentration = subset.concentration / mean2;
    
    % Add missing columns (make it suitable for other applications)
    columns = {'R', 'G', 'B', 'X', 'Y', 'Z', 'L_', 'a_', 'b_'};
    for i = 1:length(columns)
        if ~ismember(columns{i}, subset.Properties.VariableNames)
            subset.(columns{i}) = nan(height(subset), 1);
        end
    end

    % Construct result table
    response = table(subset.Time, subset.response_time, subset.concentration, ...
        subset.R, subset.G, subset.B, ...
        subset.X, subset.Y, subset.Z, ...
        subset.L_, subset.a_, subset.b_, ...
        'VariableNames', {'time', 'time_response', 'value', ...
        'R', 'G', 'B', 'X', 'Y', 'Z', 'L', 'a', 'b'});
end