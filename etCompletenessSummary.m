function [compSum, propSum] = etCompletenessSummary(data)

    dc = checkDataIn(data);

    % get all IDs
    tmp = dc.Table;
    ids = tmp(:, 2);
    numSessions = length(ids);

    % collect all possible task names
    masterNames = {};
    sesTasks = cell(1, numSessions);
    colIdx = zeros(numSessions, 1);
    for d = 1:numSessions
        
        if ~isempty(fieldnames(dc.Data{d}.Tracker))
        
            % find task name column
            found = find(strcmpi(dc.Data{d}.Tracker.ListVarNames{1}, 'TaskName'));
            if isempty(found)
                compSum = [];
                propSum = [];
                warning('Could not find a "TaskName" column in the task list. Cannot calculate completeness.')
                return
            else
                colIdx(d) = found;
            end

            % get task names for this session
            sesTasks{d} = dc.Data{d}.Tracker.ListValues{1}(:, colIdx(d));

            % append to master list of names
            masterNames = [masterNames, sesTasks{d}{:}];
            
        end
        
    end
    
    % make master names unique
    masterNames = unique(masterNames);
    
    % define matrix for counting off completed tasks
    compCounter = zeros(length(masterNames), numSessions);
    compProp = zeros(length(masterNames), numSessions);
    
    % count complete entries per session
    for d = 1:numSessions
        
        if ~isempty(fieldnames(dc.Data{d}.Tracker))
        
            % get tracker data for this session
            curSes = dc.Data{d}.Tracker;

            % determine nuber of complete samples
            order = curSes.ListOrdering{1};
            totalSamples = curSes.ListTotalSamples(1);
            remSamples = curSes.ListRemainingSamples(1);
            if remSamples < 1, remSamples = 0; end
            lastSample = totalSamples - remSamples;

            % list completed tasks
            compTasks = curSes.ListValues{1}(order(1:lastSample), colIdx(d));
            expTasks = curSes.ListValues{1}(:, colIdx(d));

            % count frequencies of completed tasks
            compCount = tabulate(compTasks);
            expCount = tabulate(expTasks);

            % look up indexes of completed tasks in master names list, convert
            % to matrix 
            masterNameIdx = cell2mat(cellfun(@(x) find(strcmpi(x, masterNames)),...
                compCount(:, 1), 'Uniform', 0));
            expNameIdx = cell2mat(cellfun(@(x) find(strcmpi(x, expCount(:, 1))),...
                compCount(:, 1), 'Uniform', 0));

            % add proportions column
            compCount(:, 3) = expCount(expNameIdx, 2);
            compCount = [compCount, num2cell(cell2mat(compCount(:, 2))...
                ./ cell2mat(expCount(expNameIdx, 2)))];

            % store counts of completed tasks in counter
            if ~isempty(masterNameIdx)
                compCounter(masterNameIdx, d) = cell2mat(compCount(:, 2));
                compProp(masterNameIdx, d) = cell2mat(compCount(:, 4));
            end        
            
        end

    end
    
    rowHdr = [' '; masterNames'];
    compColHdr = [ids'; num2cell(compCounter)];
    propColHdr = [ids'; num2cell(compProp)];
    compSum = [rowHdr, compColHdr];
    propSum = [rowHdr, propColHdr];
    
end