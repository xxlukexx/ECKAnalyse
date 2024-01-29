function etVisualiseDataQuality(data, hParent, tab)
    
    % check whether a parent figure/handle has been passed. If so, we'll
    % draw to that, otherwise we'll open a figure for drawing to
    if ~exist('hParent', 'var') || isempty(hParent)
        fig = figure('name', 'Data Quality', 'MenuBar', 'none',...
            'NumberTitle', 'off', 'Toolbar', 'none');
    else
        fig = hParent;
    end
    
    % load/check data
    dc = checkDataIn(data);
    
    if ~exist('tab', 'var')
        
        % calculate data quality
        [hdr, dta, z] = dc.QualitySummary;

        % put into table (sanitise variable names first)
        hdr = strrep(hdr, ' ', '_');
        hdr = strrep(hdr, '(', '');
        hdr = strrep(hdr, ')', '');
        hdr = strrep(hdr, ':', '_');
        hdr = strrep(hdr, '>', 'over');
        hdr = strrep(hdr, '<', 'under');
        tab = cell2table(dta, 'VariableNames', hdr);
        
    end
    
    sp(1) = subplot(2, 3, 1, 'parent', fig);
    drawDuration(tab, sp(1))
    sp(2) = subplot(2, 3, 2, 'parent', fig);
    drawPropLost(tab, sp(2))
    sp(3) = subplot(2, 3, 3, 'parent', fig);
    drawHeadboxVsPropLost(tab, sp(3))    
    sp(4) = subplot(2, 3, 4, 'parent', fig);
    drawFlicker(tab, sp(4))
    sp(5) = subplot(2, 3, 5, 'parent', fig);
    drawRMS(tab, sp(5))
    sp(6) = subplot(2, 3, 6, 'parent', fig);
    drawPostHoc(tab, sp(6))

end

function drawDuration(tab, fig)

    % convert secs to mins
    mins = tab.Duration_secs / 60;
    
    % remove extreme outliers
    mins = removeOutliers(mins, 7);
    
    % compute distribution
    histAll = histogram(mins, 30);
    title('Session Duration')
    xlabel('Duration (s)')
    ylabel('Frequency')
    
    % detect outliers = ±1SD
    [low, high] = detectOutliers(mins, 1);
    
end

function drawPropLost(tab, fig)

    % histogram 
    histAll = histogram(tab.Proportion_No_Eyes, 30);
    title('Missing data')
    xlabel('Prop samples missing')
    ylabel('Frequency')
    
end

function drawHeadboxVsPropLost(tab, fig)

    scatter(tab.Distance_From_Centre_Of_Headbox_SD,...
        tab.Proportion_No_Eyes, 'parent', fig)
    xlabel('SD of distance to centre of head box')
    ylabel('Prop samples missing')
    cf = corrcoef(tab.Distance_From_Centre_Of_Headbox_SD,...
        tab.Proportion_No_Eyes);
    cf = cf(1, 2);
    title(sprintf('Head pos vs. missing data | r = %.2f', cf));
    
end

function drawFlicker(tab, fig)

    histogram(tab.Flicker_Ratio, 30);
    title('Flicker')
    xlabel('Flicker Ratio')
    ylabel('Frequency')
    
end

function drawRMS(tab, fig)

    histogram(tab.Fixation_RMS, 30)
    title('Spatial Error')
    xlabel('Flicker Ratio')
    ylabel('Frequency')
    
end

function drawPostHoc(tab, fig)

    x = tab.Posthoc_Calib_Drift_X;
    y = tab.Posthoc_Calib_Drift_Y;
    phc = mean([x, y], 2);
    histogram(phc, 30);
    title('Drift')
    xlabel('Post-hoc calibration drift')
    ylabel('Frequency')
    
end
