function [suc, oc] = ECKRenameData(data_in, newID)

    % load/check data
    if ischar(data_in)
        data = ECKData;
        data.Load(data_in);
    elseif ~isa(data_in, 'ECKData')
        error('Input must be path to session folder or ECKData.')
    end
    
    % check data is not empty
    if ~data.Loaded
        error('Empty data.')
    end    
    
    % check new ID
    if ~exist('newID', 'var') || isempty(newID) 
        error('Invalid or missing new ID')
    end
    if isnumeric(newID)
        newID = num2str(newID);
    end
    if ~ischar(newID)
        error('New ID must be a char')
    end
    
    fprintf('<strong>Renaming data...</strong>\n')
    
    % rename ID in data and tracker, amend session path
    oldID = data.ParticipantID;
    path_oldSes = data.SessionPath;
    data.ParticipantID = newID;
    fprintf('\tRenamed main ID...\n');
    data.Tracker.ParticipantID = newID;
    fprintf('\tRenamed tracker ID...\n');
    data.SessionPath = strrep(data.SessionPath, oldID, newID);
    path_newSes = data.SessionPath;
    
    % search trial log data for ID and replace
    numTasks = length(data.Log.FunName);
    for t = 1:numTasks
        dta = data.Log.Data{t};
        hdr = data.Log.Headings{t};
        found = find(strcmpi(hdr, 'ParticipantID'));
        if length(found) > 1
            error('ParticipantID column found more than once')
        elseif ~isempty(found)
            numRows = length(dta(:, found));
            newCol = repmat({newID}, numRows, 1);
            data.Log.Data{t}(:, found) = newCol;
            data.Log.Table{t} = [data.Log.Headings{t}; data.Log.Data{t}];
            fprintf('\tRenamed trial log data for task %s (%d rows)...\n',...
                data.Log.FunName{t}, numRows);
        end
    end
    
    fprintf('\tWriting renamed data...\n')

    parts = strsplit(data.SessionPath, filesep);
    path_id = [filesep, fullfile(parts{1:end - 1})]; 
    
    % get timepoint, conver to char if necessary
    tp = data.TimePoint;
    if isnumeric(tp), tp = num2str(tp); end

    % make new id folder, copy previous data
    mkdir(path_id)
    if ~exist(path_newSes), copyfile(path_oldSes, path_newSes); end
    
    % delete data with old name in it
    delete([path_newSes, filesep, '*.mat'])
    delete([path_newSes, filesep, '*.csv'])
    delete([path_newSes, filesep, 'gaze', filesep, '*.*'])
    
    % save trial log data and tracker
    tempData = data.Log;
    save(fullfile(path_newSes, 'tempData.mat'), 'tempData')
    trackInfo = data.Tracker;
    save(fullfile(path_newSes, 'tracker.mat'), 'trackInfo')
    
    % save mainbuffer
    mainBuffer = data.MainBuffer;
    file_mb = fullfile(path_newSes, 'gaze', ['mainBuffer_',...
        newID, '_', tp, '.mat']);
    save(file_mb, 'mainBuffer')
    
    % timebuffer
    timeBuffer = data.TimeBuffer;
    file_tb = fullfile(path_newSes, 'gaze', ['timeBuffer_',...
        newID, '_', tp, '.mat']);
    save(file_tb, 'timeBuffer')
    
    % eventbuffer
    eventBuffer = data.EventBuffer;
    file_eb = fullfile(path_newSes, 'gaze', ['eventBuffer_',...
        newID, '_', tp, '.mat']);
    save(file_eb, 'eventBuffer')
    
    recoverData(path_newSes);

end