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

function properties = get_rtd_properties(impulse_times, rtds, areas)
%GET_RTD_PROPERTIES Computes statistical properties of Residence Time Distributions (RTDs)
%
% This function calculates key statistical properties of RTD curves,
% including mean, variance, standard deviation, and selected percentiles,
% and returns them in a table suitable for downstream analysis or reporting.
% RTD inputs are expected to be provided as tables with a duration-based
% time axis and a normalized response.
%
% Syntax: properties = get_rtd_properties(impulse_times, rtds, areas)
%
% Inputs:
%   impulse_times - Vector of durations specifying the impulse time for each RTD
%                   (one element per RTD in RTDS)
%   rtds          - Cell array of RTD tables; each table must contain:
%                     - time          : duration timestamps (monotonic)
%                     - time_response : duration relative time (typically starts at/near 0)
%                     - value         : RTD values (normalized density)
%   areas         - Vector of doubles with the area under each RTD curve
%                   (stored for reference in the output table)
%
% Outputs:
%   properties    - Table with the following columns:
%                     - time      : impulse time (string)
%                     - file_name : placeholder for source filename ('-')
%                     - area      : area under the RTD curve (double)
%                     - mean      : mean residence time (duration)
%                     - variance  : variance of residence time (duration)
%                     - std       : standard deviation (duration)
%                     - p1        : 1st percentile (duration)
%                     - p5        : 5th percentile (duration)
%                     - p50       : 50th percentile / median (duration)
%                     - p95       : 95th percentile (duration)
%                     - p99       : 99th percentile (duration)
%
% Notes:
%   - RTDs must be normalized such that sum(value .* dt) == 1, where
%     dt = diff(time) and 'time' is a duration vector. The function does
%     not perform normalization; it assumes inputs are already normalized.
%   - For integration, the RTD is trimmed to start at the sample closest to
%     time_response == 0.
%   - Mean and variance are computed by discrete integration over
%     time_response using the sample-wise dt derived from 'time'.
%   - Variance is clamped to be non-negative before taking the square root
%     for the standard deviation.
%   - Percentiles are estimated from the cumulative distribution (nearest
%     sample to cumulative probability levels 0.01, 0.05, 0.50, 0.95, 0.99).
%   - The output 'time' column is the string representation of each element
%     in IMPULSE_TIMES; 'file_name' is a placeholder set to '-'.
%
% Example:
%   % Suppose rtds is a 1xN cell array of tables with columns: time (duration),
%   % time_response (duration), value (normalized). Areas are precomputed.
%   areas = [1, 1, 1];
%   impulse_times = [seconds(0), seconds(30), seconds(60)];
%   properties = get_rtd_properties(impulse_times, rtds, areas);


%------------- BEGIN CODE --------------

    % Initialize table with properties
    types = ["string", "string", "double", "duration", ...
        "duration", "duration", repmat("duration", 1, 5)];
    names = ["time", "file_name", "area", "mean", "variance", ...
        "std", "p1", "p5", "p50", "p95", "p99"];
    properties = table('Size', [length(rtds), 11], ...
        'VariableTypes', types, 'VariableNames', names);
    
    % Calculate properties
    for i = 1:length(rtds)
        
        % Get subset
        subset = rtds{i};
        [~, index_start] = min(abs(seconds(subset.time_response)));
        subset = subset(index_start:end, :);
        subset.dt = [0; diff(seconds(subset.time))];
        
        % Mean and variance
        ave = duration(0, 0, sum(seconds(subset.time_response) .* subset.value .* subset.dt));
        var = duration(0, 0, max(0, sum(seconds(subset.time_response).^2 .* subset.value .* subset.dt) - seconds(ave)^2)); % Ensure non-negative
        sigma = duration(0, 0, sqrt(seconds(var)));
    
        % Percentiles
        subset.cumulative = cumsum(subset.value .* subset.dt);
        percentiles = [0.01, 0.05, 0.50, 0.95, 0.99];
        percentiles_values = seconds(zeros(size(percentiles)));
        percentiles_values.Format = 'hh:mm:ss.SSS';
        for j = 1:length(percentiles)
            [~, index] = min(abs(subset.cumulative - percentiles(j)));
            percentiles_values(j) = subset.time_response(index);
        end
    
        % Add values to table
        properties(i, :) = table(string(impulse_times(i)), "-", areas(i), ...
                                    ave, var, sigma, percentiles_values(1), percentiles_values(2), ...
                                    percentiles_values(3), percentiles_values(4), percentiles_values(5));
    end
end