%{
This file is part of Concrete Candy Tracker. Concrete Candy Tracker is 
licensed under the terms of GNU General Public License as published by 
the Free Software Foundation. For more information and the LICENSE file, 
see <https://github.com/3DCP-TUe/ConcreteCandyTracker>.
%}

% SAVE_FIGURE Saves a figure as a PDF with exact figure dimensions
%
%   SAVE_FIGURE(fig, name)
%
%   This function saves the given MATLAB figure handle as a PDF file,
%   preserving the figure's width and height.
%
%   Inputs:
%       fig  - Figure handle (e.g., gcf or figure handle)
%       name - String specifying the file name (including .pdf extension)
%
%   Example:
%       f = figure;
%       plot(1:10, rand(1,10));
%       save_figure(f, 'my_plot.pdf');
function [] = save_figure(fig, name) 
    width = fig.Position(3);
    height = fig.Position(4);
    set(gcf, 'PaperPosition', [0 0 width height]);
    set(gcf, 'PaperSize', [width height]); 
    saveas(fig, name, 'pdf')
end