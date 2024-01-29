function ECKExtractLogFromTaskExport(path_export, path_logs)

    % get all task export folders
    d = dir(path_export);
    idx_crap = ~[d.isdir] | ismember({d.name}, {'.', '..'});
    d(idx_crap) = [];
    tasks = {d.name};
    numTasks = length(tasks);
    
    % loop through tasks, load data, and export to path_logs folder
    for t = 1:numTasks
        
        dc = ECKDataContainer;
        dc.LoadExportFolder(fullfile(path_export, tasks{t}, 'mat'));
        taskName = tasks{t};
        if ~instr(taskName, '_trial')
            taskName = sprintf('%s_trial', tasks{t});
        end
        
        file_out = fullfile(path_logs, sprintf('%s.xlsx', tasks{t}));
        try
            ECKTaskDataCSV(dc, sprintf('%s_trial', tasks{t}), file_out);
        catch ERR
            fprintf(2, '%s\n', ERR.message)
        end
    
    end
    
end