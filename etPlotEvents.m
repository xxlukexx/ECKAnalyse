function etPlotEvents(eb)

    % get x values, convert to secs
    x = (double(cell2mat(eb(:, 2)) - eb{1, 2}) / 1e6)';
    ty = .9;
    % plot
    figure
    cols = lines(length(x));
    for i = 1:length(x)
        line([x(i), x(i)], [0, 1], 'color', cols(i, :),...
            'linewidth', 2)
        hold on
        h = text(x(i), ty, cell2char(eb(i, 3)), 'interpreter', 'none',...
            'EdgeColor', cols(i, :));
        ty = ty - .1;
        if ty < .1, ty = .9; end
    end
    hold off
    
end