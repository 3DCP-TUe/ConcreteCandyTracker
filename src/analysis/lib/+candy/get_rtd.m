%{
This file is part of Concrete Candy Tracker. Concrete Candy Tracker is 
licensed under the terms of GNU General Public License as published by 
the Free Software Foundation. For more information and the LICENSE file, 
see <https://github.com/3DCP-TUe/ConcreteCandyTracker>.
%}

% GET_RTD Computes the Residence Time Distribution (RTD) from impulse response
%
%   [rtd, area] = GET_RTD(impulse_time, data, window, window_start, window_end)
%
%   This function calculates the residence time distribution (RTD) from
%   experimental impulse response data. It performs baseline correction,
%   normalizes the response to the area under the curve, and returns a table
%   suitable for further analysis.
%
%   Inputs:
%       impulse_time - Scalar or datetime specifying the impulse event time
%       data         - Table containing the experimental data, must include
%                      a 'concentration' column and a 'Time' or 'time' column
%       window       - Two-element vector specifying the time window around
%                      the impulse event to consider
%       window_start - Two-element vector specifying the start window for
%                      baseline correction
%       window_end   - Two-element vector specifying the end window for
%                      baseline correction and normalization
%
%   Outputs:
%       rtd          - Table containing the normalized RTD and auxiliary
%                      columns. Columns:
%                        - time: original time values
%                        - time_response: time relative to impulse
%                        - rtd: normalized residence time distribution
%                        - R, G, B, X, Y, Z, L, a, b: additional columns
%                          filled with NaNs if missing in input
%       area         - Scalar representing the area under the corrected concentration curve
%
%   Example:
%       data = readtable('experiment.csv');
%       impulse_time = datetime(2025,8,20,12,0,0);
%       [rtd, area] = get_rtd(impulse_time, data, [0 60], [0 10], [50 60]);
%
%   Notes:
%       - Input time vectors must be sorted; the function will throw an error otherwise.
%       - Baseline correction is computed as the average of the means in the
%         start and end windows.
%       - The RTD is normalized by the area under the corrected concentration curve.
%       - Missing columns (R, G, B, X, Y, Z, L, a, b) are automatically added as NaN.
function [rtd, area] = get_rtd(impulse_time, data, window, window_start, window_end)
        
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