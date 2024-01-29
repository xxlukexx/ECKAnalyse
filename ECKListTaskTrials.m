function [trials, valid] = ECKListTaskTrials(data, task)

    dc = checkDataIn(data);
    
    [hdr, dta] = etCollateTask(dc, task);

    % look up valid trial column if we know there is one
    valid = {};
    switch task
        case 'gap_trial'
            colValid = find(strcmpi(hdr, 'validtrial'));
            if ~isempty(colValid)
                valid = cell2mat(dta(:, colValid))';
            end
    end
    
    if isempty(dta)
        trials = {};
    else
        trialNums = 1:size(dta, 1);
        trials = arrayfun(@(x) ['Trial ', LeadingString('000', x)], trialNums,...
            'uniform', 0);
    end

end