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

function [data, n] = remove_outliers(data, k, sigma)
%REMOVE_OUTLIERS Removes outliers from specified columns using Hampel filter
%
% This function identifies and removes outliers from the input table using
% a Hampel filter applied to the columns 'L_', 'a_', 'b_', 'R', 'G', and 'B'.
% Rows flagged as outliers in any of these columns are removed.
%
% Syntax: [data, n] = remove_outliers(data, k, sigma)
%
% Inputs:
%   data  - Table containing numeric columns: 'L_', 'a_', 'b_', 'R', 'G', 'B'
%   k     - Window size for the Hampel filter (number of neighboring points)
%   sigma - Threshold multiplier for standard deviation to identify outliers
%
% Outputs:
%   data  - Table with outlier rows removed
%   n     - Number of rows removed
%
% Notes:
%   - Outliers are detected independently for each specified column using
%     MATLABs hampel function.
%   - A row is removed if it is flagged as an outlier in any of the columns.
%   - Ensure the specified columns exist in the input table; otherwise, the
%     function will throw an error.
%
% Example:
%   [clean_data, n_removed] = remove_outliers(data, 5, 3);


%------------- BEGIN CODE --------------

    % Initial number of measurements
    n = height(data);

    % Find the outliers
    outliers = zeros(height(data), 1);
    for column = ["L_", "a_", "b_", "R", "G", "B"]
        [~, outlier, ~, ~] = hampel(data.(column), k, sigma);
        outliers = outliers | outlier; % Logical OR to accumulate outliers
    end
    
    % Remove the outliers
    data(outliers, :) = [];

    % Count
    n = n - height(data);
                
end