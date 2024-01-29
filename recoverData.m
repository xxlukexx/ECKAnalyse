function recoverData(sessionPath)

    %% STARTUP
    
    ECKTitle('Recover data');
    
    if ~exist('sessionPath', 'var') || isempty(sessionPath)
        sessionPath = uigetdir(pwd, 'Select session folder');
    end
        
    % check session path exists
    if ~exist(sessionPath)
        error('Session path does not exist: %s', sessionPath)
    end
    
    fprintf('\n<strong>Session path:</strong> %s\n', sessionPath);
    
    
    %% TRACKER DATA
    
     % look for tracker.mat (contains participant ID and trial order data)
     fprintf('\n<strong>1. Looking for tracker data...</strong>\n');
     
     PID = '';
     TP = '';
     CB = '';
     SITE = '';
     
     trackPath = [sessionPath, filesep, 'tracker.mat'];
     if ~exist(trackPath, 'file')
         fprintf('Temp file containing tracker data not found.\n')
     else
         fprintf('Temp file containing tracker data found.\n')

         % attempt to load temp data
         try
             load(trackPath)
             fprintf('Tracker data loaded.\n')
         catch ERR
             rethrow ERR
         end

         if isfield(trackInfo, 'ParticipantID')
             PID = trackInfo.ParticipantID;
         else 
             PID = '<UNKOWN>';
         end

         if isfield(trackInfo, 'TimePoint')
             TP = trackInfo.TimePoint;
         else
             TP = '<UNKNOWN>';
         end

         if isfield(trackInfo, 'CounterBalance')
             CB = trackInfo.CounterBalance;
         else
             CB = '<UNKOWN>';
         end

         if isfield(trackInfo, 'Site')
             SITE = trackInfo.Site;
         else
             SITE = '<UNKOWN>';
         end

        % display demographic info
        fprintf('\t<strong>Participant ID: </strong>%s\n', PID)
        fprintf('\t<strong>Time point: </strong>%d\n', TP)
        fprintf('\t<strong>Counterbalance condition: </strong>%d\n', CB)
        fprintf('\t<strong>Site: </strong>%s\n\n', SITE)

    end
    
    %% TRIAL LOG DATA
    % look for tempData.mat (contains trial log data)
    fprintf('\n<strong>2. Looking for trial log data...</strong>\n');

    logPath = [sessionPath, filesep, 'tempData.mat'];
    if ~exist(logPath, 'file')
        fprintf('Temp file containing trial log data not found.\n')
    else
        fprintf('Temp file containing trial log data found.\n')
        
        % attempt to load temp data
        try
            load(logPath)
            fprintf('Temp file loaded.\n')
        catch ERR
            rethrow ERR
        end
        
        % save csv files
        fprintf('Writing trial log data text files to session folder...\n')
        ECKSaveLog(sessionPath, tempData);
         
    end
    
    % look for eye tracking gaze data
    fprintf('\n<strong>3. Looking for eye tracker gaze data...</strong>\n');
    gazePath = [sessionPath, filesep, 'gaze'];
    
    etSuccess = true;
    
    if ~exist(gazePath)
        fprintf('No eye tracking gaze data found.\n')
        etSuccess = false;
    else
        fprintf('Eye tracking gaze folder found.\n')
        
        % look for gaze data files
        mbFile = findFilename('mainBuffer', gazePath);
        tbFile = findFilename('timeBuffer', gazePath);
        ebFile = findFilename('eventBuffer', gazePath);

        % check 
        if isempty(mbFile)
            etSuccess = false;
            fprintf('\tMISSING: mainBuffer (gaze data).\n')
        else
            fprintf('\tFOUND: mainBuffer (gaze data).\n')
        end
        
        if isempty(tbFile)
            etSuccess = false;
            fprintf('\tMISSING: timeBuffer (timestamp data).\n')
        else
            fprintf('\tFOUND: timeBuffer (timestamp data).\n')
        end
        
        if isempty(ebFile)
            etSuccess = false;
            fprintf('\tMISSING: eventBuffer (event data).\n')
        else
            fprintf('\tFOUND: eventBuffer (event data).\n')
        end
        
        % try to load
        if etSuccess
            clear mainBuffer timeBuffer eventBuffer
            load(mbFile);
            load(tbFile);
            load(ebFile);
        end

        % write csv files
%         fprintf('Writing gaze, timestamp and event data text files to gaze folder (may be slow)...\n')
%         if ~isempty(mbFile) && ~isempty(tbFile)
%             ECKSaveETGazeTime([gazePath, filesep, 'session gaze data_', PID,...
%                 '_', num2str(TP), '.csv'], mainBuffer, timeBuffer)
%         end
%         
%         if ~isempty(ebFile)
%             ECKSaveETEvents([gazePath, filesep, 'session events_', PID, '_',...
%                 num2str(TP), '.csv'], eventBuffer);
%         end
    end
    
    fprintf('\n\n\n<strong>Finished.</strong>\n');

end