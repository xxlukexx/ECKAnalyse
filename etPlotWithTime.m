function etPlotWithTime(mainBuffer)

    x = mainBuffer(:, 7)';
    y = mainBuffer(:, 8)';
    z = zeros(size(x));
    col = parula(size(x, 2));
    
    surface([x;x],[y;y],[z;z],[col;col],...
        'facecol','no',...
        'edgecol','interp',...
        'linew',2);

end