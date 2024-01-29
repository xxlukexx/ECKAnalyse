function fig = plotAOIMask(inAOI, mask, x, y, rect, stim, filename, time)
      
    if exist('time', 'var') && ~isempty(time)
        x(time + 1:end) = nan;
        y(time + 1:end) = nan;
        inAOI(:, time+1:end) = 0;
    end
    
    numSamps = size(inAOI, 2);
    
    numAOIs = size(inAOI, 1);
    cols = lines(numAOIs);
    fig = figure('units', 'normalized', 'position', [0, 0, .7, .7],...
        'visible', 'off');
    for a = 1:numAOIs
        subplot(numAOIs + 3, 3, a * 3)
        ar = area(inAOI(a, :));
        ar.LineStyle = 'none';
        ar.FaceColor = cols(a, :);
        title(['AOI: ', num2str(a)]);
        if exist('time', 'var')
            line([time, time], [0, 1]);
        end
        xlim([1, numSamps]);
        
        subplot(numAOIs + 3, 3, (numAOIs + 1) * 3)
        hold on
        ar = area(inAOI(a, :));
        ar.LineStyle = 'none';
        ar.FaceColor = cols(a, :);
        title('ALL')
        if exist('time', 'var')
            line([time, time], [0, 1]);
        end
        hold off
    end
    xlim([1, numSamps]);
    
    % plot non-AOI looking and missing
    subplot(numAOIs + 3, 3, (numAOIs + 2) * 3)
    nonAOI = ~any(inAOI, 1) & (~isnan(x)' & ~isnan(y)');
    ar = area(nonAOI);
    ar.LineStyle = 'none';
    ar.FaceColor = 'k';
    title('Non AOI')
    if exist('time', 'var')
        line([time, time], [0, 1]);
    end    
    xlim([1, numSamps]);
    
    subplot(numAOIs + 3, 3, (numAOIs + 3) * 3)
    miss = isnan(x) | isnan(y);
    ar = area(miss);
    ar.LineStyle = 'none';
    ar.FaceColor = 'r';
    title('Missing eyes')
    if exist('time', 'var')
        line([time, time], [0, 1]);
    end
    xlim([1, numSamps]);

    subplot(numAOIs + 1, 3, [1, 2, 4, 5, 7, 8, 10, 11, 13, 14, 16, 17]);
    imagesc(mask);
    colormap('gray')
    hold on
    for a = 1:numAOIs
        sc = scatter(x(inAOI(a, :)), y(inAOI(a, :)), 200,...
            'MarkerEdgeColor', cols(a, :),...
            'MarkerFaceColor', cols(a, :));
    end
    
    sc = scatter(x, y, 20, hot(length(x)));
    ln = plot(x, y, 'Color', [.5, .5, .5]);
    
    if exist('time', 'var')
        scatter(x(time), y(time), 500, 'markeredgecolor', 'm', 'linewidth', 5);
    end
    
    if exist('rect', 'var')
        for r = 1:size(rect, 1)
            rectangle('position', rect(r, [1:2, 5:6]), 'EdgeColor', 'm');
            tx = text(...
                rect(r, 1),...
                rect(r, 2) + (rect(r, 6)),...
                num2str(r), 'Color', 'm', 'FontSize', 16,...
                'EdgeColor', cols(r, :), 'LineWidth', 3);
        end
    end

    if exist('stim', 'var') && ~isempty(stim)
        text(0, 1, stim, 'FontSize', 20, 'Color', 'm');
    end
        
    if exist('filename', 'var') && ~isempty(filename)
%         saveas(gca, filename)
        im = frame2im(getframe(gcf));
        imwrite(im, filename);
    end
    
end