function isSplit = detectSplitSessions(dupIdx)

    isSplit = false(size(dupIdx));
    numData = size(dupIdx, 1);
    
    % are any sessions split?
    if all(dupIdx == [1:numData]')
        return
    end
    
    for d = 1:numData
        isSplit(d) = length(find(dupIdx == dupIdx(d))) > 1;
    end
    
end