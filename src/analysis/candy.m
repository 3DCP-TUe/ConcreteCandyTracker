%{
This file is part of Concrete Candy Tracker. Concrete Candy Tracker is 
licensed under the terms of GNU General Public License as published by 
the Free Software Foundation. For more information and the LICENSE file, 
see <https://github.com/3DCP-TUe/ConcreteCandyTracker>.
%}

classdef candy

    methods(Static)

        % -----------------------------------------------------------------

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
        
        % -----------------------------------------------------------------

        function [rtd, area] = get_rtd(impulse_time, data, window, window_start, window_end)
        
            % Check if column concentration is defined
            if ~ismember("concentration", data.Properties.VariableNames)
                error("Column 'concentration' is missing in the dataset.");
            end

            % Ensure time is sorted
            if ~issorted(data.Time)
                error('Time column must be sorted.');
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
        
            % Select window indices
            [~, index_start] = min(abs(data.Time - impulse_time - window(1)));
            [~, index_end] = min(abs(data.Time - impulse_time - window(2)));
        
            % Ensure indices are valid
            index_start = max(1, min(index_start, height(data)));
            index_end = max(1, min(index_end, height(data)));
        
            % Extract subset
            subset = data(index_start:index_end, :);
        
            % Ensure subset is not empty
            if isempty(subset)
                error('Subset of data is empty. Check the window selection.');
            end
        
            % Compute time differences
            subset.dt = [0; diff(seconds(subset.Time))];

            % Set time relative to application of impulse input
            subset.response_time = subset.Time - impulse_time;
            subset.response_time.Format = 'hh:mm:ss.SSS';
        
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
       
            % Construct result table
            rtd = table(subset.Time, subset.response_time, subset.rtd, ...
                subset.R, subset.G, subset.B, ...
                subset.X, subset.Y, subset.Z, ...
                subset.L_, subset.a_, subset.b_, ...
                'VariableNames', {'time', 'time_response', 'rtd', ...
                'R', 'G', 'B', 'X', 'Y', 'Z', 'L', 'a', 'b'});
        end
        
        % -----------------------------------------------------------------

        function response = get_normalized_step_up_response(step_up_time, data, window, window_start, window_end)
        
            % Check if column concentration is defined
            if ~ismember("concentration", data.Properties.VariableNames)
                error("Column 'concentration' is missing in the dataset.");
            end

            % Ensure time is sorted
            if ~issorted(data.Time)
                error('Time column must be sorted.');
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
        
            % Select window indices
            [~, index_start] = min(abs(data.Time - step_up_time - window(1)));
            [~, index_end] = min(abs(data.Time - step_up_time - window(2)));
        
            % Ensure indices are valid
            index_start = max(1, min(index_start, height(data)));
            index_end = max(1, min(index_end, height(data)));
        
            % Extract subset
            subset = data(index_start:index_end, :);
        
            % Ensure subset is not empty
            if isempty(subset)
                error('Subset of data is empty. Check the window selection.');
            end
        
            % Compute time differences
            subset.dt = [0; diff(seconds(subset.Time))];

            % Set time relative to application of impulse input
            subset.response_time = subset.Time - step_up_time;
            subset.response_time.Format = 'hh:mm:ss.SSS';
        
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

            % Construct result table
            response = table(subset.Time, subset.response_time, subset.concentration, ...
                subset.R, subset.G, subset.B, ...
                subset.X, subset.Y, subset.Z, ...
                subset.L_, subset.a_, subset.b_, ...
                'VariableNames', {'time', 'time_response', 'value', ...
                'R', 'G', 'B', 'X', 'Y', 'Z', 'L', 'a', 'b'});
        end

        % -----------------------------------------------------------------

        function response = get_normalized_step_down_response(step_down_time, data, window, window_start, window_end)
        
            % Check if column concentration is defined
            if ~ismember("concentration", data.Properties.VariableNames)
                error("Column 'concentration' is missing in the dataset.");
            end

            % Ensure time is sorted
            if ~issorted(data.Time)
                error('Time column must be sorted.');
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
        
            % Select window indices
            [~, index_start] = min(abs(data.Time - step_down_time - window(1)));
            [~, index_end] = min(abs(data.Time - step_down_time - window(2)));
        
            % Ensure indices are valid
            index_start = max(1, min(index_start, height(data)));
            index_end = max(1, min(index_end, height(data)));
        
            % Extract subset
            subset = data(index_start:index_end, :);
        
            % Ensure subset is not empty
            if isempty(subset)
                error('Subset of data is empty. Check the window selection.');
            end
        
            % Compute time differences
            subset.dt = [0; diff(seconds(subset.Time))];

            % Set time relative to application of impulse input
            subset.response_time = subset.Time - step_down_time;
            subset.response_time.Format = 'hh:mm:ss.SSS';
        
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
            mean2 = mean(subset.concentration(index3:index4), 'omitnan');
            subset.concentration = subset.concentration - mean2;

            % Normalize part 2: scale
            mean1 = mean(subset(index1:index2, subset.Properties.VariableNames).concentration, 'omitnan');
            subset.concentration = subset.concentration / mean1;

            % Construct result table
            response = table(subset.Time, subset.response_time, subset.concentration, ...
                subset.R, subset.G, subset.B, ...
                subset.X, subset.Y, subset.Z, ...
                subset.L_, subset.a_, subset.b_, ...
                'VariableNames', {'time', 'time_response', 'value', ...
                'R', 'G', 'B', 'X', 'Y', 'Z', 'L', 'a', 'b'});
        end

        % -----------------------------------------------------------------

        function properties = get_rtd_properties(impulse_times, rtds, areas)
           
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
                ave = duration(0, 0, sum(seconds(subset.time_response) .* subset.rtd .* subset.dt));
                var = duration(0, 0, max(0, sum(seconds(subset.time_response).^2 .* subset.rtd .* subset.dt) - seconds(ave)^2)); % Ensure non-negative
                sigma = duration(0, 0, sqrt(seconds(var)));
            
                % Percentiles
                subset.cumulative = cumsum(subset.rtd .* subset.dt);
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

        % -----------------------------------------------------------------

        function properties = get_step_up_properties(times, responses)
           
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
                ave = duration(0, 0, sum((cmax-(subset.value)).*subset.dt)./cmax);
                var = duration(0, 0, 2*sum(seconds(subset.time_response).*(cmax-(subset.value)).*subset.dt)./cmax-seconds(ave)^2);
                sigma = duration(0, 0, sqrt(seconds(var)));
            
                % Percentiles
                percentiles = [0.01, 0.05, 0.50, 0.95, 0.99];
                percentiles_values = seconds(zeros(size(percentiles)));
                percentiles_values.Format = 'hh:mm:ss.SSS';
                for j = 1:length(percentiles)
                    index = find(subset.value > percentiles(j), 1);
                    percentiles_values(j) = subset.time_response(index);
                end
            
                % Add values to table
                properties(i, :) = table(string(times(i)), "-", ...
                                         ave, var, sigma, percentiles_values(1), percentiles_values(2), ...
                                         percentiles_values(3), percentiles_values(4), percentiles_values(5));
            end
        end

        % -----------------------------------------------------------------

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
                var = duration(0, 0, 2*sum(seconds(subset.time_response).*(cmax-(1-subset.value)).*subset.dt)./cmax-seconds(ave)^2);
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

        % -----------------------------------------------------------------

        % Write figure
        function [] = save_figure(fig, name) 
            width = fig.Position(3);
            height = fig.Position(4);
            set(gcf, 'PaperPosition', [0 0 width height]);
            set(gcf, 'PaperSize', [width height]); 
            saveas(fig, name, 'pdf')
        end
        
        % -----------------------------------------------------------------

        % Figure layout
        function fig = figure_time_series(xticks, xlimits)
            
            % Initialize figure
            fig = figure;
            hold on
            grid on
            box on
            set(gca, 'FontSize', 24);
            set(gca,'YColor',[0,0,0])
            set(gca,'XColor',[0,0,0])
            set(gcf, 'PaperUnits', 'inches');
            set(gcf, 'Units', 'inches');
            fig_width = 3^(3/2)/7*18;
            fig_height = 3^(3/2); 
            set(gcf, 'PaperPosition', [0 0 fig_width fig_height]); 
            set(gcf, 'PaperSize', [fig_width fig_height]); 
            set(gcf, 'Position', [1 1 fig_width, fig_height]);
            
            % Layout x-axis
            % Dummy plot is needed since correct ticks (with clock time)
            % cannot be added on an empty axis. 
            dum = plot([xlimits(1)-duration(1,0,0), ...
                xlimits(2)+duration(1,0,0)], [0, 0]);
            set(gca, 'XTick',  xticks, 'XTickLabel', ...
                datestr(xticks, 'HH:MM'))
            xlim(xlimits)
            xlabel('Time', 'interpreter', 'latex')
            delete(dum);
        end

        % -----------------------------------------------------------------

    end
end