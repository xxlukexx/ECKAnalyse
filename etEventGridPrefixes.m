function [uLab, labIdx] = etEventGridPrefixes(ev)
    
    lab = cell(size(ev));
    
    % get indices of underscores for each event
    labIdx = cellfun(@(x) strfind(x, '_'), ev, 'uniform', 0);
    
    % add any without underscores to the label list
    noUnderScores = cellfun(@isempty, labIdx);
    lab(noUnderScores) = ev(noUnderScores);
    
    % get first part of label
    for e = 1:length(ev)
        if ~noUnderScores(e)
            lab{e} = ev{e}(1:labIdx{e} - 1);
        end
    end
    
    % make unique
    [uLab, ~, labIdx] = unique(lab);
    
end