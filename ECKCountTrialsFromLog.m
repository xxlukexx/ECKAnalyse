function tab = ECKCountTrialsFromLog(lg)

    if isstruct(lg)
        [lg, tasks] = ECKLog2Table(lg);
    end
    
    if ~iscell(lg) || ~all(cellfun(@istable, lg))
        error('Must pass a Task Engine (ECK) log in either struct of cell array of tables format.')
    end
    
    tab = table;
    tab.task = tasks;
    tab.num_trials = cellfun(@height, lg);

end
    