function exportTikzFigure(figHandle, filenameWithoutExtension)
    if nargin < 2
        error('Usage: exportTikzFigure(figHandle, filenameWithoutExtension)');
    end
    addpath(genpath('matlab2tikz'));
    % Create output directory
    outputFolder = fullfile(pwd, 'figures');
    if ~exist(outputFolder, 'dir')
        mkdir(outputFolder);
    end

    % Set white background for figure and axes
    set(figHandle, 'Color', 'w');
    ax = findall(figHandle, 'type', 'axes');
    set(ax, 'Color', 'w');

    % Build full filename
    filename = fullfile(outputFolder, [filenameWithoutExtension, '.tikz']);

    % Export to TikZ
    matlab2tikz(filename, ...
        'figurehandle', figHandle, ...
        'width', '\textwidth', ...
        'height', '0.5\textwidth', ...
        'showInfo', false, ...
        'interpretTickLabelsAsTex', false, ...
        'extraAxisOptions', { ...
            'title style={font=\small}', ...
            'label style={font=\small}', ...
            'tick label style={font=\small}', ...
            'legend style={at={(0.05,0.8)}, anchor=west}'%, ...
            %'axis background/.style={fill=white}' ...
        });

    fprintf('TikZ figure saved to: %s\n', filename);
end
% Create a simple figure
%{
x = 1:10;
y1 = x.^2;
y2 = log(x);

fig = figure;
plot(x, y1, '-o', 'DisplayName', 'x^2');
hold on;
plot(x, y2, '-s', 'DisplayName', 'log(x)');
xlabel('x');
ylabel('y');
legend('show');
title('Example Plot');

% Export the figure using your function
exportTikzFigure(fig, 'example_plot');
%}
