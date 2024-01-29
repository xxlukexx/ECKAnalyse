function [type] = sessionType(sessionPath)

    eegTasks = {...
        'restingstate_trial',...
        'mmn_trial',...
        'faces_trial',...
        'restingvideos_trial',...
        };
    
    if ~isSessionFolder(sessionPath) && ~hasGazeFolder(sessionPath)
        error('Not a session folder.')
    end
    
    type = 'UNKOWN';
    
    if hasGazeData(sessionPath)
        % if it has gaze data, it is an eye tracking dataset
        type = 'ET';
    else
        % attempt to load trial data
        dataFile = findFilename('tempData', sessionPath);
        if ~isempty(dataFile)
            % extract task names
            tmp = load(dataFile);
            if isfield(tmp.tempData, 'FunName')
                taskNames = tmp.tempData.FunName;
                % compare task names against master list of eeg tasks
                if any(cellfun(@any, cellfun(@(x) strcmpi(x, eegTasks),...
                    taskNames, 'Uniform', 0)))
                    type = 'EEG';
                end
            end
        end
    end
    
end