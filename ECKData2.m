classdef ECKData2 < handle
    
    properties
        
        CacheFolder

    end
    
    properties (Dependent)

        Loaded  
        Cached

        Type='UNKNOWN' 
        ParticipantID
        TimePoint
        Battery
        SessionPath=''
        Paths=struct
        CounterBalance
        Site=''
        Tracker=struct;
        Log=struct;
        MainBuffer=zeros(1, 26);
        TimeBuffer=zeros(1, 2);
        EventBuffer={0, 0, {}};
        Segments = [];
        ExtraData=struct;
        
    end
    
    properties (GetAccess=public, SetAccess=private)
        GazeLoaded=false
        GUID
    end
       
    properties (Dependent, SetAccess=private)
        NumSegments = 0
    end
    
    properties (Access=private)
        
        cached = false
        cacheFile
        data
        loaded = false;
        
    end
    
    methods
        
        function P = ECKData2
            
            P.GUID = char(java.rmi.server.UID);
            
            P.data.Type = 'UNKNOWN';
            P.data.ParticipantID = '';
            P.data.TimePoint = '';
            P.data.Battery = '';
            P.data.SessionPath = '';
            P.data.Paths = struct;
            P.data.CounterBalance = [];
            P.data.Site = '';
            P.data.Tracker = struct;
            P.data.Log = struct;
            P.data.MainBuffer = zeros(1, 26);
            P.data.TimeBuffer = zeros(1, 2);
            P.data.EventBuffer = {0, 0, {}};
            P.data.Segments = [];
            P.data.ExtraData = struct;
            
            P.CacheFolder = [pwd, filesep, '_datastreamtemp'];
                        
        end
        
        function [P, success, reason] = Load(P, sessionPath, loadGaze)
            
            if ~exist('loadGaze', 'var') || isempty(loadGaze)
                loadGaze = true;
            end
            
            success = true;
            reason = '';
            
            if ~exist(sessionPath, 'dir')
                error('Path not found.')
            end
            
            if ~isSessionFolder(sessionPath) && ~hasGazeFolder(sessionPath)
                error('Not a session folder.')
            end
            
            if ~any(strcmpi(sessionType(sessionPath), {'EEG', 'ET'}))
                reason = 'Unkown data Type (not EEG or eye tracking).';
                warning(reason)
                success = false;
            end
            
            % find Log data and Tracker filesnames
            logFile = findFilename('tempData', sessionPath);
            trackerFile = findFilename('tracker', sessionPath);
            
            % load Tracker info, populate demographics then store in
            % Tracker property
            slashes = strfind(sessionPath, '/');
            if ~isempty(trackerFile), 
                tmp = load(trackerFile); 
                P.Paths.Tracker = trackerFile;
            else
                tmp.trackInfo = struct;
                P.Paths.Tracker = [];
            end
            
            if isfield(tmp.trackInfo, 'ParticipantID') &&...
                    ~isempty(tmp.trackInfo.ParticipantID)
                P.ParticipantID = tmp.trackInfo.ParticipantID; 
            else
                P.ParticipantID = sessionPath(slashes(end - 1) + 1:slashes(end) - 1);
            end

            if isfield(tmp.trackInfo, 'TimePoint')
                P.TimePoint = tmp.trackInfo.TimePoint;
            else
                P.TimePoint =...
                    sessionPath(slashes(end - 3) + 1:slashes(end - 2) - 1);
            end
                        
            if isfield(tmp.trackInfo, 'CounterBalance')
                P.CounterBalance = tmp.trackInfo.CounterBalance;
            else
                P.CounterBalance = [];
            end
                 
            if isfield(tmp.trackInfo, 'Site')
                P.Site = tmp.trackInfo.Site;
            else
                P.Site = '';
            end
            
            P.Tracker = tmp.trackInfo;
            P.Battery =...
                sessionPath(slashes(end - 2) + 1:slashes(end - 1) - 1);
            
            % load Log data
            if ~isempty(logFile)
                tmp = load(logFile);
                if isfield(tmp, 'tempData')
                    P.Log = tmp.tempData;
                elseif isfield(tmp, 'Log')
                    P.Log = tmp.Log;
                end
                P.Paths.Log = logFile;
            else
                P.Log = struct;
                P.Paths.Log = [];
            end
            
            % store session path
            P.SessionPath = sessionPath;
            
            % load gaze (if possibly)
            if strcmpi(sessionType(sessionPath), 'ET') && loadGaze
               success = P.LoadGaze;
            end
            
            P.Type = sessionType(sessionPath);
            
            if success, P.Loaded = true; end
            
        end
               
        function [P, success, reason] = SaveSession(P, outputPath)
            
            if ~exist('outputPath', 'var') || isempty(outputPath) ||...
                    ~exist(outputPath, 'dir')
                success = false;
                reason = 'Output path does not exist.';
                return
            end
            
            % create battery and timepoint folders if necessary
            bat = '<UNKOWN>';
            if ischar(P.Battery)
                bat = P.Battery;
            elseif isnumeric(P.Battery)
                bat = num2str(P.Battery);
            end
            
            tp = '<UNKOWN>';
            if ischar(P.TimePoint)
                tp = P.TimePoint;
            elseif isnumeric(P.TimePoint)
                tp = num2str(P.TimePoint);
            end
            
            pid = '<UNKOWN>';
            if ischar(P.ParticipantID)
                pid = P.ParticipantID;
            elseif isnumeric(P.ParticipantID)
                pid = num2str(P.ParticipantID);
            end
            
            pParts = pathParts(P.SessionPath);
            batPath = [outputPath, filesep, bat];
            tpPath = [batPath, filesep, tp];
            idPath = [tpPath, filesep, pid];
            sesPath = [idPath, filesep, pParts{end}];
             
            if ~exist(sesPath)
                [suc, err] = mkdir(sesPath);
                if ~suc
                    reason = sprintf(...
                        'Error creating output folder. Error was: %s', err);
                    success = false;
                    return
                end
            end
            
            % copy existing folder
            if ~strcmp(P.SessionPath, sesPath)
                [suc, err] = copyfile(P.SessionPath, sesPath);
                if ~suc
                    reason = sprintf('Error copying data. Error was:\n\n%s', err);
                    success = false;
                    return
                end
            end
            
            trackerPath = [sesPath, filesep, 'tracker.mat'];
            logPath = [sesPath, filesep, 'tempData.mat'];
            gazePath = [sesPath, filesep, 'gaze'];
            mbFile = findFilename('mainBuffer', gazePath);
            tbFile = findFilename('timeBuffer', gazePath);
            ebFile = findFilename('eventBuffer', gazePath);
            csvGazeFile = findFilename('session_gaze_data', gazePath);
            csvEventFile = findFilename('session_events', gazePath);
            
            % delete existing files
            if exist(trackerPath, 'file'), delete(trackerPath); end
            if exist(logPath, 'file'), delete(logPath); end
            if exist(mbFile, 'file'), delete(mbFile); end
            if exist(tbFile, 'file'), delete(tbFile); end
            if exist(ebFile, 'file'), delete(ebFile); end
            if exist(csvGazeFile, 'file'), delete(csvGazeFile); end
            if exist(csvEventFile, 'file'), delete(csvEventFile); end
            
            % save tracker  and log
            trackInfo = P.Tracker;
            save(trackerPath, 'trackInfo');
            tempData = P.Log;
            save(logPath, 'tempData');
            
            % save gaze buffers
            if ~isempty(P.MainBuffer)
                mainBuffer = P.MainBuffer;
                save(mbFile, 'mainBuffer');
            end
            if ~isempty(P.TimeBuffer)
                timeBuffer = P.TimeBuffer;
                save(tbFile, 'timeBuffer');
            end
            if ~isempty(P.EventBuffer)
                eventBuffer = P.EventBuffer;
                save(ebFile, 'eventBuffer');
            end
            
            % save CSVs
            ECKSaveLog(tpPath, tempData)
            ECKSaveETGazeTime(csvGazeFile, P.MainBuffer, P.TimeBuffer);
            ECKSaveETEvents(csvEventFile, P.EventBuffer);
            
        end
        
        function [success, reason] = OverwriteBuffers(P, dontSaveCSVs)
            
            if ~exist('dontSaveCSVs', 'var') || isempty(dontSaveCSVs)
                dontSaveCSVs = false;
            end
            
            if ~P.GazeLoaded
                success = false;
                reason = 'Gaze not loaded';
            end
            
            % save buffers
            try
                save(P.Paths.MainBuffer, P.MainBuffer);
            catch ERR
                success = false;
                reason = ERR.message;
            end
            
            try
                save(P.Paths.TimeBuffer, P.TimeBuffer);
            catch ERR
                success = false;
                reason = ERR.message;
            end
            
            try
                save(P.Paths.EventBuffer, P.EventBuffer);
            catch ERR
                success = false;
                reason = ERR.message;
            end
            
            % save CSVs
            if ~dontSaveCSVs
                
                % get path of gaze folder
                [gazePath, ~, ~] = fileparts(P.Paths.MainBuffer);

                % get paths of csv files and delete
                if ~isempty(P.Paths.CSVGaze)
                    delete(P.Paths.CSVGaze);
                else
                    P.Paths.CSVGaze =...
                        fullfile(P.Paths.Gaze, 'session_gaze_data.csv');
                end
                
                if ~isempty(P.Paths.CSVEvents)
                    delete(P.Paths.CSVEvents);
                else
                    P.Paths.CSVEvents = ...
                        fullfile(P.Paths.Gaze, 'session_events.csv');
                end
                
                ECKSaveETGazeTime(P.Paths.CSVGaze, P.MainBuffer, P.TimeBuffer);
                ECKSaveETEvents(P.Paths.CSVEvents, P.EventBuffer);
                
            end
            
        end
        
        function [success, reason] = ExportToGrafix(P, exportPath)
            
            % check output var
            if ~exist('exportPath', 'var') 
                error('Must specify a path to export to.')
            end
            
            exportPath = fullfile(exportPath, P.ParticipantID);
            
            % check output path, try to create if needed
            if ~exist(exportPath, 'dir')
                mkdir(exportPath)
            end
            
            % reformat to grafix format
            graFIX = etPh3ToGrafix(P.MainBuffer, P.TimeBuffer);

            % save
            filePath = fullfile(exportPath, [P.ParticipantID, '_rough.csv']);
            
            try
                
                % write file
                dlmwrite(...
                    filePath, graFIX, 'delimiter', ',', 'precision', '%.6f');
                
                % verify
                if ~exist(filePath, 'file')
                    success = false;
                    reason = 'Saved without error but file could not be verified';
                else
                    success = true;
                    reason = '';
                end
                    
            catch ERR
                success = false;
                reason = ERR.message;
            end
            
        end
        
        function [success, reason] = LoadGaze(P)
       
            reason = '';
            success = true;
            
            gazePath = [P.SessionPath, filesep, 'gaze'];
            if ~exist(gazePath, 'dir')
                success = false;
                reason = sprintf('Gaze path does not exist\n\t%s\n',...
                    gazePath);
                return
            else
                P.Paths.Gaze = gazePath;
            end
                
            % find buffer filenames
            mbFile = findFilename('mainBuffer', gazePath);
            tbFile = findFilename('timeBuffer', gazePath);
            ebFile = findFilename('eventBuffer', gazePath);
            
            % check filenames were found
            if isempty(mbFile)
                success = false;
                reason = sprintf('Main buffer not found\n\t%s\n',...
                    mbFile);
                return
            end
            
            if isempty(tbFile)
                success = false;
                reason = sprintf('Time buffer not found\n\t%s\n',...
                    tbFile);
                return
            end
            
            if isempty(ebFile)
                success = false;
                reason = sprintf('Event buffer not found\n\t%s\n',...
                    ebFile);
                return
            end            
            
            % get file parts
            [~, mbFileName, mbFileExt] = fileparts(mbFile);
            [~, tbFileName, tbFileExt] = fileparts(tbFile);
            [~, ebFileName, ebFileExt] = fileparts(ebFile);

            % load buffers
            try
                tmp = load(mbFile);
                P.MainBuffer = tmp.mainBuffer;
                P.Paths.MainBuffer = mbFile;
            catch ERR
                if strcmpi(ERR.identifier, 'MATLAB:load:cantReadFile')
                    reason = sprintf(...
                        'Error loading main buffer - .mat file may be corrupt.\n\t%s',...
                        [mbFileName, mbFileExt]);
                    success = false;
                end
            end

            try
                tmp = load(tbFile);
                P.TimeBuffer = tmp.timeBuffer;
                P.Paths.TimeBuffer = tbFile;
            catch ERR
                if strcmpi(ERR.identifier, 'MATLAB:load:cantReadFile')
                    reason = sprintf(...
                        'Error loading time buffer - .mat file may be corrupt.\n\t%s',...
                        [tbFileName, tbFileExt]);
                    success = false;
                end
            end

            try
                tmp = load(ebFile);
                P.EventBuffer = tmp.eventBuffer;
                P.Paths.EventBuffer = ebFile;
            catch ERR
                if strcmpi(ERR.identifier, 'MATLAB:load:cantReadFile')
                    reason = sprintf(...
                        'Error loading event buffer - .mat file may be corrupt.\n\t%s',...
                        [ebFileName, ebFileExt]);
                    success = false;
                end
            end
                        
            % find csv files (we won't load them, but will store their
            % paths)                
            P.Paths.CSVGaze = findFilename('session_gaze_data', gazePath);
            P.Paths.CSVEvents = findFilename('session_events', gazePath);
            
            P.GazeLoaded = success;
            
        end
        
        function [table] = Table(P)
            
            if ~P.Loaded
                table = [];
            else
                table = {...
                    P.ParticipantID,...
                    P.Battery,...
                    P.TimePoint,...
                    P.SessionPath,...
                    size(P.Log.FunName),...
                    P.Tracker,...
                    P.Log
                    };
                
                if strcmpi(P.Type, 'ET')
                    table = [table,...
                        {P.MainBuffer},...
                        {P.TimeBuffer},...
                        {P.EventBuffer}];
                end
            end
            
        end
        
        function [dataQuality] = Quality(P)
             dataQuality = etDataQualityMetric2(P);
        end
        
        function [taskNames] = ListTasks(P)
            taskNames = P.Log.FunName;
        end
        
        function UpdateLoaded(P)
            P.Loaded = ~isempty(P.MainBuffer) && ~isempty(P.TimeBuffer);
        end
        
        function UpdateCacheFilename(P)
           
            P.cacheFile = [P.CacheFolder, filesep, P.GUID, '.mat'];
            
        end
    
        % get/set methods
        
        function [newVal] = get.data(P)
            if ~P.cached
                newVal = P.data;
            else
                load(P.cacheFile)
                newVal = tmp;
                clear tmp
            end
        end
        
        function P = set.data(P, newVal)
            if ~P.cached
                P.data = newVal;
            else
                tmp = newVal;
                save(P.cacheFile, 'tmp', '-v6')
                clear tmp
                clear newVal
            end
        end
        
        function [newVal] = get.Cached(P)
            newVal = P.cached;
        end
        
        function P = set.Cached(P, newVal)
            if newVal ~= P.Cached
                if newVal 
                    tmp = P.data;
                    save(P.cacheFile, 'tmp', '-v6')
                    clear tmp
                    P.data = struct;
                else
                    P.cached = false;
                    load(P.cacheFile);
                    P.data = tmp;
                    clear tmp;
                end

                P.cached = newVal;
            end
        end
        
        function P = set.GUID(P, newVal)
            
            P.GUID = newVal;
            P.UpdateCacheFilename;
        
        end
        
        function P = set.CacheFolder(P, newVal)
            
            P.CacheFolder = newVal;
            P.UpdateCacheFilename;
            
        end
                
        
        % get
        
        function [newVal] = get.Type(P) 
            newVal = P.data.Type;
        end
        
        function [newVal] = get.ParticipantID(P) 
            newVal = P.data.ParticipantID;
        end
        
        function [newVal] = get.TimePoint(P) 
            newVal = P.data.TimePoint;
        end
        
        function [newVal] = get.Battery(P) 
            newVal = P.data.Battery;
        end
        
        function [newVal] = get.SessionPath(P) 
            newVal = P.data.SessionPath;
        end
        
        function [newVal] = get.Paths(P) 
            newVal = P.data.Paths;
        end
        
        function [newVal] = get.CounterBalance(P) 
            newVal = P.data.CounterBalance;
        end
        
        function [newVal] = get.Site(P) 
            newVal = P.data.Site;
        end
        
        function [newVal] = get.Tracker(P) 
            newVal = P.data.Tracker;
        end
        
        function [newVal] = get.Log(P) 
            newVal = P.data.Log;
        end
        
        function [newVal] = get.MainBuffer(P) 
            newVal = P.data.MainBuffer;
        end
        
        function [newVal] = get.TimeBuffer(P) 
            newVal = P.data.TimeBuffer;
        end        
        
        function [newVal] = get.EventBuffer(P) 
            newVal = P.data.EventBuffer;
        end
        
        function [newVal] = get.Segments(P) 
            newVal = P.data.Segments;
        end
        
        function [newVal] = get.ExtraData(P) 
            newVal = P.data.ExtraData;
        end  
        
        function [newVal] = get.NumSegments(P)
            
            if isempty(P.Segments)
                newVal = 0;
            else
                newVal = length(P.Segments);
            end
            
        end
        
        function [newVal] = get.Loaded(P)
            newVal = P.loaded;
        end
        
        % set
        
        function P = set.Type(P, newVal) 
            P.data.Type = newVal;
        end
        
        function P = set.ParticipantID(P, newVal) 
            P.data.ParticipantID = newVal;
        end
        
        function P = set.TimePoint(P, newVal) 
            P.data.TimePoint = newVal;
        end
        
        function P = set.Battery(P, newVal) 
            P.data.Battery = newVal;
        end
        
        function P = set.SessionPath(P, newVal) 
            P.data.SessionPath = newVal;
        end
        
        function P = set.Paths(P, newVal) 
            P.data.Paths = newVal;
        end
        
        function P = set.CounterBalance(P, newVal) 
            P.data.CounterBalance = newVal;
        end
        
        function P = set.Site(P, newVal) 
            P.data.Site = newVal;
        end
        
        function P = set.Tracker(P, newVal) 
            P.data.Tracker = newVal;
        end
        
        function P = set.Log(P, newVal) 
            P.data.Log = newVal;
        end
        
        function P = set.MainBuffer(P, newVal) 
            P.data.MainBuffer = newVal;
        end
        
        function P = set.TimeBuffer(P, newVal) 
            P.data.TimeBuffer = newVal;
        end        
        
        function P = set.EventBuffer(P, newVal) 
            P.data.EventBuffer = newVal;
        end
        
        function P = set.Segments(P, newVal) 
            P.data.Segments = newVal;
        end
        
        function P = set.ExtraData(P, newVal) 
            P.data.ExtraData = newVal;
        end  
        
        function P = set.Loaded(P, newVal)
            P.loaded = newVal;
        end

        
    end
    
end