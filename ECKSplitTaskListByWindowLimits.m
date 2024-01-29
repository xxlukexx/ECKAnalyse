function [onTasks, offTasks] = ECKSplitTaskListByWindowLimits(tasks)

    % extract task names, and find on/offsets of wl
    t = tasks.Table(:, 2);
    on = strcmpi(t, 'windowlimitenable');
    off = strcmpi(t, 'windowlimitdisable');
    
    if ~any(on)
        error('No window limit onsets found.')
    elseif ~any(off)
        error('No window limit offsets found.')
    end
    
    % if first incidence is an offset, note this 
    onAtStart = find(on, 1) > find(off, 1);

    % loop through and split by wl on/off
    onIdx = false(size(t));
    offIdx = false(size(t));
    curState = onAtStart;
    for i = 1:length(t)
               
        % determine if status has changed
        if on(i)
            curState = true;
        elseif off(i)
            curState = false;
        else
            % set flag for this task
            onIdx(i) = curState;
            offIdx(i) = ~curState; 
        end
        
    end
    
    onTasks = unique(t(onIdx));
    offTasks = unique(t(offIdx));

end