function tasks = ECKSummariseFolderTasks(path_in)

    files = recdir(path_in);
    idx = cellfun(@(x) ~isempty(strfind(x, 'tempData.mat')), files);
    files(~idx) = [];
    tasks = cell(length(files), 1);
    parfor d = 1:length(files)
        try
            tmp = load(files{d});
            tasks{d} = tmp.tempData.FunName;
        catch ERR
        end
    end
    
    empty = cellfun(@isempty, tasks);
    tasks(empty) = [];
    tasks = unique(horzcat(tasks{:}))';
    
end