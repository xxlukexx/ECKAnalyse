function summariseTasks(data)

    dc = checkDataIn(data);
    
    % get list of all tasks
    tasks = {};
    tp = {};
    pid = {};
    pid_tp = {};
    for d = 1:length(dc.Data)
        tasks = [tasks, dc.Data{d}.ListTasks];
        pid = [pid, dc.Data{d}.ParticipantID];
        tp = [tp, dc.Data{d}.TimePoint];
        pid_tp = [pid_tp, horzcat(tp{end}, ' - ', pid{end})];
    end
    [tasksU, tasks_idx, tasks_subs] = unique(tasks);
    [pidU, pid_idx, pid_subs] = unique(pid);
    [pid_tpU, pid_tp_idx, pid_tp_subs] = unique(pid_tp);  
    
    tab = cell(length(tasksU) + 1, length(pid_tpU)+ 1);
    tab(2:end, 2:end) = repmat(cellstr(' '), [length(tasksU), length(pid_tpU)]);
    tab(1, 1) = cellstr('TASKS');
    tab(2:end, 1) = tasksU';
    tab(1, 2:end) = pid_tpU;
        
    for d = 1:length(dc.Data)
        tasks = dc.Data{d}.ListTasks;
        pidRow = find(strcmpi(pid_tpU,...
            horzcat(dc.Data{d}.TimePoint, ' - ', dc.Data{d}.ParticipantID)));
        for t = 1:length(tasks)
            taskRow = find(strcmpi(tasksU, tasks{t}));
            tab(taskRow + 1, pidRow + 1) = cellstr('X');
        end
    end
    
    disp(tab)
    
end