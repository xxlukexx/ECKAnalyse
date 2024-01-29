function [success, outcome, data] =...
    etAlignSegmentsWithLog(data, matchTimestamps)

    if ~exist('matchTimestamps', 'var') || isempty(matchTimestamps)
        matchTimestamps = false;
    end
    
    % check data
    dc = checkDataIn(data);
    
    % default oucome vars
    success = false(dc.NumData, 1);
    outcome = cellstr(repmat('UNKNOWN ERROR', [dc.NumData, 1]));

    wb = waitbar(0, '');
    % loop through datasets
    for d = 1:dc.NumData
        
        wb = waitbar(d / dc.NumData, wb);
        
        % get log data for this dataset
        lg = dc.Data{d}.Log;
        try
            lg = ECKRemoveDuplicateLogRows(lg);
        catch ERR
        end
        
        % get task names for each segmentation job
        nJobs = length(dc.Data{d}.Segments);
        
        % check that there are some segmentation jobs
        if nJobs == 0
            success(d) = false;
            outcome{d} = 'No segmentation jobs found.';
            continue
        end
            
        % loop through jobs
        for j = 1:nJobs

            jobLabel = dc.Data{d}.Segments(j).JobLabel;
            if isfield(dc.Data{d}.Segments(j), 'Task')
                jobTask = dc.Data{d}.Segments(j).Task;
            else 
                jobTask = 'NONE';
            end
            nSegs = length(dc.Data{d}.Segments(j).Segment);

            % look for matching log entry
            logFound = instr(lg.FunName, jobLabel) |...
                instr(lg.FunName, jobTask);
            % check results
            if all(isempty(logFound))                    
                % none found
                success(d) = false;
                outcome{d} = 'No log matched segment task name or job label.';
                continue
            elseif sum(logFound) > 1
                % more than one possibility
                success(d) = false;
                outcome{d} = 'Multiple logs segment matched task name or job label.';
                continue
            end

            % get headings and data from log
            hdr = lg.Headings{logFound};
            dta = lg.Data{logFound};
            nLog = size(dta, 1);
            
            % get segments
            seg = dc.Data{d}.Segments(j).Segment;
            numSegs = length(seg);            

            % if we are not matching timestamps, then simply line
            % up each row of the log with each segment. If there
            % are mismatching numbers of rows/segments then this
            % operation fails. if we are matching timestamps,
            % search through each row/segment, look for uint64 data
            % with a column header containing 'remote' and make
            % sure that all of these times for a particular row of
            % log data are within the first and last timestamp of a
            % segment
            if ~matchTimestamps

                % check size of log vs segments
                if nLog == nSegs
                    
                    for s = 1:numSegs
                        
                        tmp.FunName = lg.FunName;
                        tmp.Headings = lg.Headings;
                        tmp.Data = {lg.Data{1}(s, :)};
                        dc.Data{d}.Segments(j).Segment(s).Log =...
                            ECKLog2Table(tmp);
                        
                    end

                    success(d) = true;
                    outcome{d} = 'OK';

                else

                    success(d) = false;
                    outcome{d} = ...
                        'Number of segments did not match number of log entries.';

                end

            else


                
%                 % look for int
%                 colIsInt64 = all(cellfun(@(x) isa(x, 'int64'), dta), 1);

                % get on/offset LOCAL timestamps from all segs 
                evOnsetTimes = arrayfun(@(x) x.EventBuffer{1, 1}, seg);
                evOffsetTimes = arrayfun(@(x) x.EventBuffer{end, 1}, seg);
                evTimes = [evOnsetTimes', evOffsetTimes'];
%                 evTimes = arrayfun(@(x) cell2mat(...
%                     x.EventBuffer(:, 1)), seg, 'uniform', false);

                % search for column headers with 'remote' in them
                localFound = strfind(upper(hdr), 'LOCAL');
                cols = ~cellfun(@isempty, localFound);

                % get timestamp data for each of these columns,
                % convert to double
                try
                    logTimes = dta(:, cols);
                    logTimes = cellfun(@double, logTimes, 'uniform', false);

                    % replace empties with nan, convert to numeric
                    logTimeEmpty = cellfun(@isempty, logTimes);
                    if any(logTimeEmpty(:))
                        logTimes(logTimeEmpty) =...
                            num2cell(nan(sum(logTimeEmpty(:)), 1));
                    end
                    logTimes = cell2mat(logTimes);

                    % remove zeros and nans
                    logTimes(logTimes == 0) = nan;
                catch ERR_logTimes
                    error('Error looking up log times - debug')
                end
                
                % drop any columns with NaNs in them
                colHasNan = any(isnan(logTimes), 1);
                logTimes(:, colHasNan) = [];
                if isempty(logTimes)
                    error('All candidate log columns had NaNs in them and were removed.')
                end
                
                % get range of log times - all times within this range that
                % are also between the et event on/offset must have
                % happened during that segment
                logTimeRange = [min(logTimes, [], 2), max(logTimes, [], 2)];
                
                % check against et times
                segLogIdx = nan(numSegs, 1);
                for s = 1:numSegs
                    
                    % get on/offset times for this segment
                    evOn = evTimes(s, 1);
                    evOff = evTimes(s, 2);
                    % compare to all log times
%                     logMatch = logTimeRange(:, 1) >= evOn &...
%                         logTimeRange(:, 2) <= evOff;
                    logMatch = evOn >= logTimeRange(:, 1)&...
                        evOff <= logTimeRange(:, 2);
                    % check return
                    if any(logMatch)
                        if sum(logMatch) > 1
                            % more than one match
                            warning('More than one log time range matched the segment.')
                        end
                        % record log index
                        segLogIdx(s) = find(logMatch, 1);
                        % store in DC
                        foundLogItem = lg.Data{logFound}(logMatch, :);
                        varNames = fixTableVariableNames(...
                            lg.Headings{logFound});
                        foundLogItemTable = cell2table(foundLogItem,...
                            'variablenames', varNames);
                        data.Data{d}.Segments(j).Segment(s).Log =...
                            foundLogItemTable;
                    else
                        warning('No log times matched segment %d.', s)
                    end
                    
                end
                
                % check that full results were returned
                if any(isnan(segLogIdx))
                    warning('Some segments could not be matched.')
                end
                
                
                
%                 isWithin = logTimeRange(:, 1) >= evTimes(:, 1) &...
%                     logTimeRange(:, 2) <= evTimes(:, 2);
%                 
%                 
% 
%                 % loop through segments, search for matching times
%                 logIdx = zeros(numSegs, 1);
%                 lg.Segments{logFound} = cell(numSegs, 1);
%                 for s = 1:numSegs
% 
%                     % get first and lastlocal event times for this
%                     % segment
%                     times = evTimes{s}([1, end]);
% 
%                     % search each row of the log file local times
%                     % for any values that are between the first and
%                     % last event of the segment
%                     logIdx(s) = find(any(logTimes >= times(1) &...
%                         logTimes <= times(2), 1));
% 
% %                             % inset log headings and found log row
% %                             seg(s).Log.FunName = lg.FunName(logFound);
% %                             seg(s).Log.Headings = hdr;
% %                             seg(s).Log.Data = dta(found(s), :);
% %                             seg(s).Log.Table = [...
% %                                 seg(s).Log.Headings;...
% %                                 seg(s).Log.Data];
% 
%                 end
% 
%                 % insert matched segments into log
%                 lg.Segments{logFound} = seg(logIdx);

                success(d) = true;
                outcome{d} = 'OK';

            end

%             dc.Data{d}.Log = lg;

        end

    end

    delete(wb)

end