function dataOut = etRemoveEvents(dataIn, links, tasks)

    if ~isa(dataIn, 'ECKData')
        error('Must pass an ECKData instance.')
    end
    
    if ~exist('links', 'var') || isempty(links)
        error('Must pass non-empty links data.')
    end
    
    if ~exist('tasks', 'var') || isempty(tasks)
        error('Must pass non-empty tasks data.')
    end
    
    dataOut = ECKDuplicateData(dataIn);
    grd = etEventsToGrid(dataOut.EventBuffer);
    
    % filter out tasks to keep
    [allTasks, ~, allTasksIdx] = unique(links(:, 1));
    keepCell = cellfun(@(x) strcmpi(allTasks, x), tasks, 'uniform', 0);
    keepIdx = sum(cell2mat(keepCell), 2);
    remTasks = allTasks(~keepIdx);
    numTasks = length(tasks);

    % loop through tasks and remove all linked events from the event buffer
    remEbIdx = false(size(grd, 1), 1);
    for t = 1:numTasks
        
        % get linked event names to remove for the current task
        taskLnkIdx = strcmpi(links(:, 1), remTasks{t});
        remEvents = links(taskLnkIdx, 2);
        
        % find events to remove in buffer
        remEbCell = cellfun(@(x) strcmpi(grd(:, 4), x), remEvents, 'uniform', 0)';
        remEbIdx = remEbIdx & sum(cell2mat(remEbCell), 2);
        
    end
end