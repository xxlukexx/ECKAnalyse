function data = ECKFixGazePaths(data)

    % check data in
    if ~isa(data, 'ECKData')
        error('Must pass (single) ECKData object.')
    end
    
    if ischar(data.ParticipantID)
        id = data.ParticipantID;
    elseif isnumeric(data.ParticipantID)
        id = num2str(data.ParticipantID);
    else
        error('Partcipant ID was not char or numeric.')
    end
    
    if ischar(data.TimePoint)
        tp = data.TimePoint;
    elseif isnumeric(data.TimePoint)
        tp = num2str(data.TimePoint);
    else
        error('Timepoint was not char or numeric.')
    end
    
    % check that the data.Paths struct is filled with correct pathnames,
    % otherwise, search for the files and fill it in
    
    % check gaze folder
    if isempty(data.Paths.Gaze)
        data.Paths.Gaze = [data.SessionPath, filesep, 'gaze'];
    end
        
    % check buffers
    if isempty(data.Paths.MainBuffer)
        data.Paths.MainBuffer = findFilename('mainBuffer',...
            data.Paths.Gaze);
    end
    
    if isempty(data.Paths.TimeBuffer)
        data.Paths.TimeBuffer = findFilename('timeBuffer',...
            data.Paths.Gaze);
    end    
    
    if isempty(data.Paths.EventBuffer)
        data.Paths.EventBuffer = findFilename('eventBuffer',...
            data.Paths.Gaze);
    end    
    
    % check csv files
    if isempty(data.Paths.CSVGaze)
        data.Paths.CSVGaze = findFilename('session gaze data',...
            data.Paths.Gaze);
    end    
    
    if isempty(data.Paths.CSVEvents)
        data.Paths.CSVEvents = findFilename('session events',...
            data.Paths.Gaze);
    end
    
    % zip current files before deleting
    zipFile = [data.Paths.Gaze, filesep, 'prefixedPaths.tar'];
    fileObj = java.io.File(data.Paths.Gaze);
    fileList = fileObj.listFiles;
    files = arrayfun(@char, fileList, 'uniform', 0);
    tar(zipFile, files);

    % delete old files
    if ~isempty(data.Paths.MainBuffer), delete(data.Paths.MainBuffer); end
    if ~isempty(data.Paths.TimeBuffer), delete(data.Paths.TimeBuffer); end
    if ~isempty(data.Paths.EventBuffer), delete(data.Paths.EventBuffer); end
    if ~isempty(data.Paths.CSVGaze), delete(data.Paths.CSVGaze); end
    if ~isempty(data.Paths.CSVEvents), delete(data.Paths.CSVEvents); end
    
    % create new filenames
    data.Paths.MainBuffer =...
        [data.Paths.Gaze, filesep, 'mainBuffer_', id, '_', tp, '.mat'];    
    
    data.Paths.TimeBuffer =...
        [data.Paths.Gaze, filesep, 'timeBuffer_', id, '_', tp, '.mat'];    
  
    data.Paths.EventBuffer =...
        [data.Paths.Gaze, filesep, 'eventBuffer_', id, '_', tp, '.mat'];    

    data.Paths.CSVGaze =...
        [data.Paths.Gaze, filesep, 'session gaze data_', id, '_', tp, '.csv'];     
    
    data.Paths.CSVEvents =...
        [data.Paths.Gaze, filesep, 'session events_', id, '_', tp, '.csv'];     
    
    % write new files
    mainBuffer = data.MainBuffer;
    timeBuffer = data.TimeBuffer;
    eventBuffer = data.EventBuffer;
    
    if ~isempty(data.Paths.MainBuffer), save(data.Paths.MainBuffer, 'mainBuffer'), end
    if ~isempty(data.Paths.TimeBuffer), save(data.Paths.TimeBuffer, 'timeBuffer'), end
    if ~isempty(data.Paths.EventBuffer), save(data.Paths.EventBuffer, 'eventBuffer'), end
    if ~isempty(data.Paths.CSVGaze), ECKSaveETGazeTime(data.Paths.CSVGaze, mainBuffer, timeBuffer, false); end
    if ~isempty(data.Paths.CSVEvents), ECKSaveETEvents(data.Paths.CSVEvents, eventBuffer, false); end
    
end

