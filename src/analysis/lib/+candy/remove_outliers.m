%{
This file is part of Concrete Candy Tracker. Concrete Candy Tracker is 
licensed under the terms of GNU General Public License as published by 
the Free Software Foundation. For more information and the LICENSE file, 
see <https://github.com/3DCP-TUe/ConcreteCandyTracker>.
%}

% REMOVE_OUTLIERS Removes outliers from specified columns using Hampel filter
%
%   [data, n] = REMOVE_OUTLIERS(data, k, sigma)
%
%   This function identifies and removes outliers from the input table
%   using a Hampel filter on the columns 'L_', 'a_', 'b_', 'R', 'G', and 'B'.
%
%   Inputs:
%       data  - Table containing columns 'L_', 'a_', 'b_', 'R', 'G', 'B'
%       k     - Window size for the Hampel filter (number of neighboring points)
%       sigma - Threshold multiplier for standard deviation to identify outliers
%
%   Outputs:
%       data  - Table with outlier rows removed
%       n     - Number of rows removed
%
%   Notes:
%       - Outliers are determined independently for each specified column.
%       - Rows flagged as outliers in any column are removed from the table.
%
%   Example:
%       [clean_data, n_removed] = remove_outliers(data, 5, 3);

% Removes the outliers
function [data, n] = remove_outliers(data, k, sigma)
    
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