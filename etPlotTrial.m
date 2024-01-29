function etPlotTrial(mb)

    figure
    
    subplot(5, 1, 1:3)
    plot(mb(:, 7), mb(:, 8))
    xlim([0, 1]);
    ylim([0, 1]);
    
    subplot(5, 1, 4)
    plot(mb(:, 7));
    ylim([0, 1]);
    
    subplot(5, 1, 5);
    plot(mb(:, 8));
    ylim([0, 1])

end