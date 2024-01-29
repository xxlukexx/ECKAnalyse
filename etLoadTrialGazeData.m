function [dc] = etLoadTrialGazeData(data)

    taskTimes = etGetTaskTimes;
            
    dc = checkDataIn(data);
    
    % loop through all data
    for d = 1:dc.NumData

        % store log and list of tasks held within
        curLog = dc.Data{d}.Log;
        
        % check log has valid fields
        if isfield(curLog, 'FunName') && isfield(curLog, 'Data') &&...
                isfield(curLog, 'Headings')
            
            taskList = curLog.FunName(:);

            % look for task times
            for curTask = 1:size(taskList, 1)

                % search task timings list for current log task
                found = find(strcmpi(taskTimes(:, 1), taskList{curTask}));
                dataFound = ~isempty(found);

                % if found...
                if dataFound

                    % find the column label for the start and end time (listed
                    % above in taskTimes)
                    startLabel = taskTimes{found, 2};
                    endLabel = taskTimes{found, 3};

                    % find start times for each sample
                    rawTimes = ECKLogExtract(curLog, taskList{curTask}, startLabel);
                    
                    if ~isempty(rawTimes)
                        
                        timeIdx = cellfun(@(x) strcmpi(x, 'N/A'), rawTimes);
                        startTimes = cell2mat(rawTimes(~timeIdx));

                        % if end label is given as a number rather than a string,
                        % it is not a label to be looked up in the log file, but a
                        % number of seconds to be added to the start time
                        if ischar(endLabel)

                            try
                                endTimes = cell2mat(...
                                    ECKLogExtract(curLog, taskList{curTask}, endLabel));
                            catch ERR
                                if strcmpi(ERR.identifier, 'MATLAB:cell2mat:MixedDataTypes')
                                    endTimes = cell2mat(cellfun(@double,...
                                        ECKLogExtract(curLog, taskList{curTask}, endLabel),...
                                        'UniformOutput', false));  
                                elseif ~isempty(strfind(ERR.message,...
                                        '(and perhaps others) not found in log file.'))
                                    dataFound = false;
                                else
                                    rethrow(ERR)
                                end
                            end

                        else
                            endTimes = num2cell(startTimes + (endLabel * 1000000));
                        end
                        
                    else

                        dataFound = false;

                    end

                end

                if dataFound

                    if iscell(endTimes) 
                        if any(arrayfun(@ischar, endTimes))
                            endTimes = num2cell(cellfun(@str2num, endTimes));
                        end
                        endTimes = cell2mat(endTimes);
                    end

                    % preallocate space to store samples and gaze data
                    startSamples = zeros(size(startTimes, 1), 1);
                    endSamples = zeros(size(startTimes, 1), 1);
                    gazeChunks = cell(size(startTimes, 1),1);
                    timeChunks = cell(size(startTimes, 1), 1);
                    eventChunks = cell(size(startTimes, 1), 1);

                    if any(ischar(startTimes)), startTimes = str2num(startTimes); end

                    % loop through and get data for each trials
                    for curTime = 1:size(startTimes, 1)

                        [...
                            gazeChunks(curTime),...
                            timeChunks(curTime),...
                            eventChunks(curTime)]...
                        = etGetGazeByTime(...
                            dc.Data{d}.MainBuffer,...
                            dc.Data{d}.TimeBuffer,...
                            dc.Data{d}.EventBuffer,...
                            startTimes(curTime),...
                            endTimes(curTime));
                    end

                    dc.Data{d}.Log.Gaze{curTask} = gazeChunks;
                    dc.Data{d}.Log.Time{curTask} = timeChunks;
                    dc.Data{d}.Log.Events{curTask} = eventChunks;
                    
                    % get trial data quality
                    numTrials = length(dc.Data{d}.Log.Gaze{curTask});
                    for t = 1:numTrials
                        
                        % get full data quality
                        [dc.Data{d}.Log.Quality{curTask}{t}, summary] =...
                            etDataQualityMetric3(...
                            dc.Data{d}.Log.Gaze{curTask}{t},...
                            dc.Data{d}.Log.Time{curTask}{t},...
                            dc.Data{d}.Log.Events{curTask}{t});
                        
                        % extract prop valid data
                        if ~isempty(dc.Data{d}.Log.Quality{curTask}{t})
                            col = strcmpi(summary.Header, 'No eyes (prop)');
                            if any(col)
                                val = 1 - summary.Data{col};
                            else
                                val = []; 
                            end
                            dc.Data{d}.Log.ValidSamples{curTask}(t) = val;
                        else 
                            dc.Data{d}.Log.ValidSamples{curTask}(t) = nan;
                        end
                        
                    end

                end

            end
        
        end
        
    end

end