function ECKVisualise_gap_summary(data, panel)

%% process trial data

    dc = checkDataIn(data);

    [trialSum, PIDSum] = etGap_Analyse2(dc, true); 
    
    % if no valid trials, call standard visualisation function
    if isempty(trialSum)
        return
    end
    
    colPID = 1;
    colCond = 4;
    colSRT = 14;
    colValid = 5;
    
    % get condition data, convert labels to integers 
    [condLab, ~, cond] = unique(trialSum(2:end, colCond));
    
    % get PID data, convert labels to integers 
    [PIDLab, ~, PID] = unique(trialSum(2:end, colPID));
    
    % get SRT and valid
    SRT = cell2mat(trialSum(2:end, colSRT));
    valid = cell2mat(trialSum(2:end, colValid));
    
    % combine into a matrix 
    dta = [PID, cond, SRT, valid];
    
    % find the rows for each condition
    rowBL = find(strcmpi(condLab, 'BASELINE'));
    rowGP = find(strcmpi(condLab, 'GAP'));
    rowOL = find(strcmpi(condLab, 'OVERLAP'));
    
    if isempty(rowBL) || isempty(rowGP) || isempty(rowOL)
        fprintf('Could not find data from all three conditions. Cannot analyse.\n')
        return
    end
    
    % count total trials in each cond
    totalBL = sum(cond == rowBL & valid);
    totalGP = sum(cond == rowGP & valid);
    totalOL = sum(cond == rowOL & valid);
    
    % summarise valid trials
    
    
    if totalBL > 20 nBins = 20; else nBins = totalBL; end
%     nBins = mean([totalBL, totalGP, totalOL]);

    [histBL, cntBL] = hist(SRT(cond == rowBL & valid), nBins);
    [histGP, cntGP] = hist(SRT(cond == rowGP & valid), nBins);
    [histOL, cntOL] = hist(SRT(cond == rowOL & valid), nBins);
    
    spHist = subplot(1, 1, 1,...
        'position', [0.05 0.07 0.90 0.87],...
        'ycolor', [0.4, 0.4, 0.4],...
        'xcolor', [0, 0, 0],...
        'parent', panel);        
    
    xlabel(spHist, 'SRT');
    ylabel(spHist, 'Num Trials');
    
    hold(spHist)
    col = hsv(3);
    alpha = .2;
    
    bBL = bar(cntBL, histBL,...
        'linestyle', '-',...
        'edgecolor', col(1, :),...
        'facecolor', col(1, :),...
        'parent', spHist);
    chBL = get(bBL, 'children');
    set(chBL, 'facea', alpha);
    set(chBL, 'edgea', alpha);

    bGP = bar(cntGP, histGP,...
        'linestyle', '-',...
        'edgecolor', col(2, :),...
        'facecolor', col(2, :),...
        'parent', spHist);
    chGP = get(bGP, 'children');
    set(chGP, 'facealpha', alpha);
    set(chGP, 'edgea', alpha);

    bOL = bar(cntOL, histOL,...
        'linestyle', '-',...
        'edgecolor', col(3, :),...
        'facecolor', col(3, :),...
        'parent', spHist);
    chOL = get(bOL, 'children');
    set(chOL, 'facea', alpha);
    set(chOL, 'edgea', alpha);

    legend('String', condLab);
    
    pGP = plot(cntGP, histGP,...
        'color', col(2, :),...
        'linewidth', 3,...
        'LineSmoothing', 'on',...
        'parent', spHist);
    
    pBL = plot(cntBL, histBL,...
        'color', col(1, :),...
        'linewidth', 3,...
        'LineSmoothing', 'on',...
        'parent', spHist);
    
    pOL = plot(cntOL, histOL,...
        'color', col(3, :),...
        'linewidth', 3,...
        'LineSmoothing', 'on',...
        'parent', spHist);
end