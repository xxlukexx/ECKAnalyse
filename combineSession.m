function combineSession(table, md)

    numData = size(table, 1);
    wb = waitbar(.1, sprintf('Combining %d sessions...', numData));
    
    % ensure that metadata is sorted by date, so that we combine in the
    % correct order
    paths_ses = md(:, 4);
    parts = cellfun(@(x) strsplit(x, filesep), paths_ses, 'UniformOutput', false);
    dt = cellfun(@(x) x{end}, parts, 'UniformOutput', false);
    dt_num = cellfun(@(x) datenum(x, 'dd_mmm_yyyy HH.MM.SS'), dt);
    [~, so] = sort(dt_num);
    md = md(so, :);
    
    % if this is eye tracking data, load gaze data
    isET = any(strcmpi(cellfun(@sessionType, table(:, 3),...
        'Uniform', 0), 'ET'));
    
    if isET
        waitbar(.2, wb, 'Loading gaze data')
        md = etLoadGazeData(md, true);
    end
    
    % get participant folders
    folders = table(:, 3);
    parts = cellfun(@(x) strsplit(x, filesep), folders, 'uniform', 0);
    numParts = cellfun(@length, parts);
    
    % check that folder lengths match
    if ~all(numParts == numParts(1))
        errordlg('Cannot extract participant folder, paths do not match.')
        error('Cannot extract participant folder, paths do not match.')
    end
    
    % get participant folder
    participantFolder = [filesep, fullfile(parts{1}{1:end - 1})];
    
    % get PID & TP
    PID = md{1, 1};
    TP = md{1, 2};
    
    % combine
    waitbar(.3, wb, sprintf('Combining %d sessions', numData));
    mdc = etCombineSessions(md);
    
    % backup
    waitbar(.4, wb, 'Backing up existing session folders');
    prePath = [participantFolder, filesep, '_precombine'];
    mkdir(prePath);
    zip([prePath, filesep, PID, '_session_folders.zip'], table(:, 3));
    
    % delete
    waitbar(.6, wb, 'Deleting old session folders');
    try
        cellfun(@(x) rmdir(x, 's'), table(:, 3));
    catch ERR
        warning(ERR.message)
    end

    % write
    waitbar(.7, wb, 'Writing new session folder');
    outPath = table{1, 3};
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
        save([gazePath, filesep, 'mainBuffer', postFix, '.mat'], 'mainBuffer', '-v6')
        save([gazePath, filesep, 'timeBuffer', postFix, '.mat'], 'timeBuffer', '-v6')
        save([gazePath, filesep, 'eventBuffer', postFix, '.mat'], 'eventBuffer', '-v6')
%         ECKSaveETGazeTime([gazePath, filesep, 'session gaze data_',...
%             postFix, '.csv'], mainBuffer, timeBuffer);
%         ECKSaveETEvents([gazePath, filesep, 'session events_',...
%             postFix, '.csv'], eventBuffer);
        warning('Saving of CSVs disabled for speed.')
        clear mainBuffer timeBuffer eventBuffer
    end
    ECKSaveLog(outPath, Log);

    close(wb)
    
end