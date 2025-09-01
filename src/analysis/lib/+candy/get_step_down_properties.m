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

function properties = get_step_down_properties(times, responses)
%GET_STEP_DOWN_PROPERTIES Computes statistical properties of step-down responses
%
% This function calculates key statistical characteristics of step-down
% response curves, including mean, variance, standard deviation, and selected
% percentiles, and returns them in a table suitable for further analysis or
% reporting. All time quantities are handled as MATLAB durations.
%
% Syntax: properties = get_step_down_properties(times, responses)
%
% Inputs:
%   times     - Vector of durations specifying the step-down time for each
%               response (one element per table in RESPONSES)
%   responses - Cell array of step-down response tables; each table must contain:
%                 - time          : duration timestamps (monotonic)
%                 - time_response : duration relative time (typically starts at/near 0)
%                 - value         : normalized response on a 0–1 scale
%
% Outputs:
%   properties - Table with the following columns:
%                 - time      : step-down time (string)
%                 - file_name : placeholder for source filename ('-')
%                 - mean      : mean response time (duration)
%                 - variance  : variance of response time (duration)
%                 - std       : standard deviation (duration)
%                 - p1        : 1st percentile (duration)
%                 - p5        : 5th percentile (duration)
%                 - p50       : 50th percentile / median (duration)
%                 - p95       : 95th percentile (duration)
%                 - p99       : 99th percentile (duration)
%
% Notes:
%   - Each response is trimmed to start at the sample closest to
%     time_response == 0 before analysis.
%   - The sample-wise integration step dt is computed from 'time' as
%     dt = [0; diff(seconds(time))].
%   - Responses are assumed normalized on [0, 1]; percentiles are reported
%     as the first time where value < (1 - p), e.g., p50 is the half-time
%     where value drops below 0.5.
%   - Variance is constrained to be non-negative prior to square-rooting
%     to compute the standard deviation.
%
% Example:
%   % Build a cell array of normalized step-down response tables (duration-based):
%   t0 = seconds(0);
%   resp1 = get_normalized_step_down_response(t0, data1, [seconds(0) seconds(120)], ...
%                                             [seconds(0) seconds(10)], [seconds(90) seconds(120)]);
%   resp2 = get_normalized_step_down_response(t0, data2, [seconds(0) seconds(120)], ...
%                                             [seconds(0) seconds(10)], [seconds(90) seconds(120)]);
%   responses = {resp1, resp2};
%   times = [t0, t0];
%   properties = get_step_down_properties(times, responses);

%------------- BEGIN CODE --------------

    % Initialize table with properties
    types = ["string", "string", "duration", ...
        "duration", "duration", repmat("duration", 1, 5)];
    names = ["time", "file_name", "mean", "variance", ...
        "std", "p1", "p5", "p50", "p95", "p99"];
    properties = table('Size', [length(responses), 10], ...
        'VariableTypes', types, 'VariableNames', names);
    
    for i = 1:length(responses)
        
        % Get subset
        subset = responses{i};
        [~, index_start] = min(abs(seconds(subset.time_response)));
        subset = subset(index_start:end, :);
        subset.dt = [0; diff(seconds(subset.time))];
        
        % Mean and variance
        cmax = 1;
        ave = duration(0, 0, sum((cmax-(1-subset.value)).*subset.dt)./cmax);
        var = duration(0, 0, max(0, 2*sum(seconds(subset.time_response).*(cmax-(1-subset.value)).*subset.dt)./cmax-seconds(ave)^2));   % Ensure non-negative
        sigma = duration(0, 0, sqrt(seconds(var)));

        % Percentiles
        percentiles = [0.01, 0.05, 0.50, 0.95, 0.99];
        percentiles_values = seconds(zeros(size(percentiles)));
        percentiles_values.Format = 'hh:mm:ss.SSS';
        for j = 1:length(percentiles)
            index = find(subset.value < (1-percentiles(j)), 1);
            percentiles_values(j) = subset.time_response(index);
        end
    
        % Add values to table
        properties(i, :) = table(string(times(i)), "-", ...
                                    ave, var, sigma, percentiles_values(1), percentiles_values(2), ...
                                    percentiles_values(3), percentiles_values(4), percentiles_values(5));
    end
end