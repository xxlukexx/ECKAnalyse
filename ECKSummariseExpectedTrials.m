function s = ECKSummariseExpectedTrials(tracker)

    if ischar(tracker) 
        if ~exist(tracker, 'file')
            error('Tracker not found at: %s', tracker)
        else
            try
                tmp = load(tracker);
            catch ERR
                error('Error loading tracker: %s', tracker)
            end
            if ~isfield(tmp, 'trackInfo')
                error('trackInfo variable not found in: %s', tracker)
            end
            tracker = tmp.trackInfo;
        end
    elseif ~isstruct(tracker)
        error('Must pass tracker struct or char path to tracker file.')
    end     

    % assume that task list is list 1
    list = cell2table(tracker.ListValues{1}, 'VariableNames',...
        fixTableVariableNames(tracker.ListVarNames{1}));

    % convert NumTrials variable to numeric
    if iscell(list.NumTrials)
        
        % remove list rows with invalid num trials (not numeric, or empty)
        idx_invalid = cellfun(@(x) ~isnumeric(x) || isempty(x), list.NumTrials);
        list(idx_invalid, :) = [];        
        
        % convert
        list.NumTrials = cell2mat(list.NumTrials);
        
    end
    
    % get subs for task names
    [task_u, ~, task_s] = unique(list.TaskName);
    
    % count trials per task
    m = accumarray(task_s, list.NumTrials, [], @sum);
    
    s = struct;
    s.ID = tracker.ParticipantID;
    for i = 1:length(task_u)
        var = fixTableVariableNames(task_u{i});
        s.(var) = m(i);
    end
    
%     % format into table
%     tab = array2table(m, 'VariableNames', {'NumTrials'});
%     tab.Task = task_u;
%     tab = movevars(tab, 'Task', 'before', 'NumTrials');

end