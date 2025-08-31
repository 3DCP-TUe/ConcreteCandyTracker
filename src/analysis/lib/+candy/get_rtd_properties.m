% SPDX-License-Identifier: GPL-3.0-or-later
% Concrete Candy Tracker
% Project: https://github.com/3DCP-TUe/ConcreteCandyTracker
%
% Copyright (c) 2023-2025 Endhoven University of Technology
%
% Authors:
%   - Arjen Deetman (2023-2025)
%
% For license details, see the LICENSE file in the project root.

function properties = get_rtd_properties(impulse_times, rtds, areas)
% GET_RTD_PROPERTIES Computes statistical properties of Residence Time Distributions (RTDs)
%
%   properties = GET_RTD_PROPERTIES(impulse_times, rtds, areas)
%
%   This function calculates key statistical properties of RTD curves,
%   including mean, variance, standard deviation, and selected percentiles.
%   The results are returned as a table for further analysis or reporting.
%
%   Inputs:
%       impulse_times - Vector of impulse times corresponding to each RTD
%       rtds          - Cell array of RTD tables, each table must include
%                       'time', 'time_response', and 'value' columns
%       areas         - Vector of areas under the RTD curves, used for
%                       normalization reference
%
%   Outputs:
%       properties    - Table of RTD properties with the following columns:
%                           - time: impulse time (string)
%                           - file_name: placeholder for source filename
%                           - area: area under the RTD curve
%                           - mean: mean residence time (duration)
%                           - variance: variance of residence time (duration)
%                           - std: standard deviation (duration)
%                           - p1: 1st percentile (duration)
%                           - p5: 5th percentile (duration)
%                           - p50: 50th percentile (median, duration)
%                           - p95: 95th percentile (duration)
%                           - p99: 99th percentile (duration)
%
%   Notes:
%       - RTDs must be normalized such that the sum over rtd * dt equals 1.
%       - Percentiles are estimated from the cumulative RTD distribution.
%       - Time is handled as MATLAB durations; statistical properties are
%         returned as durations for convenience.
%
%   Example:
%       [rtds, areas] = get_rtd(impulse_times, data, window, window_start, window_end);
%       properties = get_rtd_properties(impulse_times, rtds, areas);

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