function combineSession2(sessionPaths)

    numData = size(sessionPaths, 1);
    wb = waitbar(.1, sprintf('Combining %d sessions...', numData));
    
    % if this is eye tracking data, load gaze data
    isET = all(strcmpi(cellfun(@sessionType, sessionPaths,...
        'Uniform', 0), 'ET'));
    
    % create DC, then loop through and load each session
    dc = ECKDataContainer;
    numSes = size(sessionPaths, 1);
    for s = 1:numSes
        tmp = ECKData;
        tmp.Load(sessionPaths{s});
        dc.AddData(tmp)
        md = dc.LegacyMetadata;
    end
    
    % get participant folders
    folders = sessionPaths;
    parts = cellfun(@(x) strsplit(x, filesep), folders, 'uniform', 0);
    numParts = cellfun(@length, parts);
    
    % check that folder lengths match
    if ~all(numParts == numParts(1))
        errordlg('Cannot extract participant folder, paths do not match.')
        error('Cannot extract participant folder, paths do not match.')
    end
    
    participantFolder = '';
    for p = 1:numParts - 1
        participantFolder = [participantFolder, parts{1}{p}, filesep];
    end
    participantFolder = [filesep, participantFolder(1:end - 1)];
    
    % get PID & TP
    PID = md{1, 1};
    TP = md{1, 3};
    
    % combine
    waitbar(.3, wb, sprintf('Combining %d sessions', numData));
    mdc = etCombineSessions(md);
    
    % backup
    waitbar(.4, wb, 'Backing up existing session folders');
    prePath = [participantFolder, filesep, '_precombine'];
    mkdir(prePath);
    zip([prePath, filesep, PID, '_session_folders.zip'], folders);
    
    % delete
    waitbar(.6, wb, 'Deleting old session folders');
    try
        cellfun(@(x) rmdir(x, 's'), folders);
    catch ERR
        warning(ERR.message)
    end

    % write
    waitbar(.7, wb, 'Writing new session folder');
    outPath = folders{1};
    mkdir(outPath);
    trackInfo = mdc{1, 6};
    Log = mdc{1, 7};
    save([outPath, filesep, 'tracker.mat'], 'trackInfo');
    save([outPath, filesep, 'tempData.mat'], 'Log');
    
    % write ET
    if isET
        waitbar(.9, wb, 'Writing gaze data (may be slow)');
        gazePath = [outPath, filesep, 'gaze'];
        postFix = ['_', PID, '_', TP];     
        mkdir(gazePath)
        mainBuffer = mdc{1, 8};
        timeBuffer = mdc{1, 9};
        eventBuffer = mdc{1, 10};
        save([gazePath, filesep, 'mainBuffer', postFix, '.mat'], 'mainBuffer')
        save([gazePath, filesep, 'timeBuffer', postFix, '.mat'], 'timeBuffer')
        save([gazePath, filesep, 'eventBuffer', postFix, '.mat'], 'eventBuffer')
        ECKSaveETGazeTime([gazePath, filesep, 'session gaze data_',...
            postFix, '.csv'], mainBuffer, timeBuffer);
        ECKSaveETEvents([gazePath, filesep, 'session events_',...
            postFix, '.csv'], eventBuffer);
        clear mainBuffer timeBuffer eventBuffer
    end
    ECKSaveLog(outPath, Log);

    close(wb)
    
end