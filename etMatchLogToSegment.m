function [hdr, dta] = etMatchLogToSegment(eb, logData, task)
% searches through rows of trial log data, and attempts to find a row with
% timestamps that match the timestamps in an event buffer. Use this when
% you have an event buffer (usually after it has been segmented into a
% trial) and you want to find the matching row of log data (usually to
% integrate information between the two sources of data). 
%
% This function searches through all numeric columns in the log data, and
% attempts to match any numbers found with remote and local timestamps in
% the event buffer

    % get event buffer timestamps
    local = cell2mat(eb(:, 1));
    remote = cell2mat(eb(:, 2));
    
% check and process trial log data. Extract entries relating to the
% specified task, then find columns that are numeric - these may contain
% timestamps and will be searched against the event buffer in the next step
    
    % check task name exists in log
    taskIdx = ismember(task, logData.FunName);
    if ~any(taskIdx)
        error('Task %s not found in trial log data.', task)
    elseif sum(taskIdx) > 1
        error('Multiple log entries found for task %s.', task)
    end
    
    % filter log by task
    data = logData.Data{taskIdx};
    hdr = logData.Headings{taskIdx};
    
    % find numeric columns in trial log data
    isNum = cellfun(@isnumeric, data(1, :));

    % get columns that are vectors (since timestamps would always be in
    % a vector)
    isVec = cellfun(@(x) size(x, 2) == 1, data(1, :));    

    % filter columns for just numeric vectors
    col = data(:, isNum & isVec);
    numCols = size(col, 2);
    numRows = size(col, 1);

% search through all of the candidate columns that may contain timestamps
% from the trial log data, and compare to the event buffer timestamps. 

    % loop through log and compare each item to the local and remote
    % timestamps from the event buffer
    found = false(size(col));
    for c = 1:numCols
        for r = 1:numRows
            if ~isempty(col{r, c})
                found(r, c) = ismember(col{r, c}, local) |...
                    ismember(col{r, c}, remote);
            end
        end
    end
        
%         
%         
%             
%             % if there are any nan, zero or empty in this column, then it
%             % can't contain timestamps, so skip it
%             colNan = cellfun(@isnan, col(:, c));
%             colEmpty = cellfun(@isempty, col(:, c));
%             colZero = cellfun(@(x) x == 0, col(:, c));            
%             
%             if ~any(colNan | colEmpty | colZero)
%                 % get column data
%                 m = cell2mat(col(:, c));
%                 % do contents match any event buffer timestamps?
%                 found(:, c) = ismember(m, local) | ismember(m, remote);
%                 
%             end
%             
%         end
        
        % find rows with any matching timestamps
        rowFound = any(found, 2);
%         if sum(rowFound) > 1
%             error('Multiple rows with matching timestamps.')
        if any(rowFound)
            dta = data(rowFound, :);
        else
            dta = [];
        end
        
end