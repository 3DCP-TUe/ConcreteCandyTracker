%{
This file is part of Concrete Candy Tracker. Concrete Candy Tracker is 
licensed under the terms of GNU General Public License as published by 
the Free Software Foundation. For more information and the LICENSE file, 
see <https://github.com/3DCP-TUe/ConcreteCandyTracker>.
%}

% GET_STEP_DOWN_PROPERTIES Computes statistical properties of step-down responses
%
%   properties = GET_STEP_DOWN_PROPERTIES(times, responses)
%
%   This function calculates key statistical characteristics of step-down
%   response curves, including mean, variance, standard deviation, and selected
%   percentiles. The results are returned as a table for further analysis.
%
%   Inputs:
%       times      - Vector of step-down times corresponding to each response
%       responses  - Cell array of step-down response tables, each table must
%                    include 'time', 'time_response', and 'value' columns
%
%   Outputs:
%       properties - Table of response properties with the following columns:
%                       - time: step-down time (string)
%                       - file_name: placeholder for source filename
%                       - mean: mean response time (duration)
%                       - variance: variance of response time (duration)
%                       - std: standard deviation (duration)
%                       - p1: 1st percentile (duration)
%                       - p5: 5th percentile (duration)
%                       - p50: 50th percentile (median, duration)
%                       - p95: 95th percentile (duration)
%                       - p99: 99th percentile (duration)
%
%   Notes:
%       - The step-down response values should be normalized (0-1 scale).
%       - Percentiles are calculated based on the time when the normalized
%         response reaches the corresponding fraction of the step-down.
%       - Time is handled as MATLAB durations; statistical properties are
%         returned as durations for convenience.
%
%   Example:
%       responses = get_normalized_step_down_response(step_down_time, data, window, window_start, window_end);
%       properties = get_step_down_properties(step_down_times, responses);

function properties = get_step_down_properties(times, responses)
    
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