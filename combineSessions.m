function combineSessions(participantFolder)

    fprintf('Reading folder...');

    % check folder name, if not supplied, use system UI
    if ~exist('participantFolder', 'var') || isempty(participantFolder)
        if exist('ECKPaths', 'class')
            paths = ECKPaths;
            defPath = paths.output;
        else
            defPath = pwd;
        end
        
        participantFolder = [];
        while ~exist(participantFolder, 'dir')
            participantFolder = uigetdir(defPath,...
                'Select participant folder.');
            if isempty(participantFolder)
                return
            end
        end
    end
    
    % summarise sessions
    table = summariseSession(participantFolder);
    numSes = size(table, 1);
    if numSes < 2
        fprintf(['\n\nOnly one session folder was found. This may be because only\n',...
            'one session folder exists. If more than one folder does exist\n',...
            'this indicates that no data was found in these folders. If\n',...
            'this is the case then verify that these folders contain no\n',...
            'data and delete them.\n\n'])
        fprintf('The folder that did contain data is:\n\n\t%s\n\n', table{1, 3});
        return
    end
    
    % collect responses for which sessions to combine
    resp = true(1, numSes);
    respHappy = false;
    while ~respHappy
        % display summary
        clc
        PID = table{1, 1};
        TP = table{1, 2};
        ECKTitle('Combine sessions')
        fprintf('\n<strong>Participant folder:</strong> \t%s\n', participantFolder);
        fprintf('<strong>Participant ID:</strong> \t%s\n', PID);
        fprintf('<strong>Timepoint / schedule:</strong> \t\t%s\n', TP);
        fprintf('<strong>Num sessions found:</strong> \t%d\n', numSes);
        for s = 1:size(table, 1)
            fprintf('\n<strong>%d. </strong>%s\n\n', s, table{s, 4});
            disp(table{s, 5}(2:end, :));
        end

        fprintf('\nSelect sessions to combine:\n\n');
        fprintf('<strong>Session: \t\t\t</strong>');
        fprintf('<strong>%d\t</strong>', [1:numSes]);
        fprintf('\nCombine? (1 = Y, 0 = N): \t');
        fprintf('%d\t', resp);
        fprintf('\n\n');
        fprintf('Select a session number to toggle, press 0 to combine.\n');
        r = str2num(input(' >', 's'));
        if ~isempty(r) && isnumeric(r)
            if r > 0 && r <= numSes 
                resp(r) = ~resp(r);
            elseif r == 0
                respHappy = true;
            end
        end
    end
    
    % combine
    if any(resp)
        isET = any(strcmpi(cellfun(@sessionType, table(:, 3),...
            'Uniform', 0), 'ET'));
        fprintf('\nCombining %d sessions...\n', sum(resp));
        md = etLoadMetadata(participantFolder, true, false);
        mdc = etCombineSessions(md(resp, :));
        
        fprintf('\tBacking up existing session folders...');
        prePath = [participantFolder, filesep, '_precombine'];
        mkdir(prePath);
        zip([prePath, filesep, PID, '_session_folders.zip'], table(:, 3));
        fprintf('done.\n');
        
        fprintf('\tDeleting old session folders...');
        cellfun(@(x) rmdir(x, 's'), table(:, 3));
        fprintf('done.\n');
        
        fprintf('\tWriting new session folder...\n');
        outPath = table{1, 3};
        mkdir(outPath);
        trackInfo = mdc{1, 6};
        Log = mdc{1, 7};
        save([outPath, filesep, 'tracker.mat'], 'trackInfo');
        save([outPath, filesep, 'tempData.mat'], 'Log');
        if isET
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
    end
        

end