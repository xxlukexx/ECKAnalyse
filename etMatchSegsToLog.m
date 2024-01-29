function [matchedLog, logIdx] = etMatchSegsToLog(data, eventLabel,...
    logLabel, funName, tol)

    if ~exist('tol', 'var')
        tol = 0.05;
    end

    if ~isa(data, 'ECKData')
        error('Data must be ECKData.')
    end
    
    % find segmentation details
    numJobs = data.NumSegments;
    matchedLog = cell(1, numJobs);
    logIdx = cell(1, numJobs);
    
    % get log data
    [logValue, ~, logFunIdx] =...
        ECKLogExtract(data.Log, funName, logLabel);
    logWidth = size(data.Log.Data{logFunIdx}, 2);
    if isempty(logValue)
        error('Log label not found')
    elseif ~iscell(logValue)
        error('Unexpected log data format - DEBUG!')
    end
    numAsChar = cellfun(@ischar, logValue);
    if any(numAsChar)
        logValue = num2cell(cellfun(@str2num, logValue));
    end
    cellContentsAreNumeric = cellfun(@isnumeric, logValue);
    if ~all(cellContentsAreNumeric)
        error('Not all contents of log data are numeric - cannot match to eye tracker timestamps.')
    end
    logValue = double(cell2mat(logValue));
    
    for j = 1:numJobs
        
        matchedLog{j} = {};
        numSegs = length(data.Segments(j).Segment);
        logIdx{j} = nan(numSegs, 1);
                
        for s = 1:numSegs
        
            % extract matching events
            eb = data.Segments(j).Segment(s).EventBuffer;
            eb = etFilterEvents(eb, eventLabel);
            if isempty(eb), continue, end
            
            if size(eb, 1) > 1
                warning('Multiple events returned for eventLabel %s - cannot match.',...
                    eventLabel);
                eb = eb(1, :);
%                 continue
            end
            
            % extract event timestamp, convert to secs
            ts = double(eb{1, 2});
            dist = abs(ts - logValue);
            found = find(dist == min(dist), 1, 'first');  
            if ~isempty(found)
                tmp = data.Log.Data{logFunIdx}(found, :);
            else
                tmp = cell(1, logWidth);
            end
            matchedLog{j} = [matchedLog{j}; tmp];
            logIdx{j}(s) = found;
            
        end
        
        % remove NaNs - for indices that couldn't be matched
        noMatch = isnan(logIdx{j});
        logIdx{j}(noMatch) = [];
    
    end
    


end