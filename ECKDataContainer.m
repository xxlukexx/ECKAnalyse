classdef (ConstructOnLoad) ECKDataContainer < handle
    
    properties
        ExtraData
        ProgressBarEnabled = false
    end
    
    properties (Dependent)
        Data
    end
    
    properties (Dependent, SetAccess=private)
        NumData
    end

    properties (SetAccess=private, GetAccess=public)
        Audit={}
    end
    
    properties (SetAccess=private, GetAccess=private)
    end
       
    properties (Access=private)
        data
        dataFilter
        audit={}
        filterActive
        filterName
        filterValue
        streamTempFolder
        streamGUIDs
    end
    
    properties (Constant)
        AvailableFilters = {...
            'TYPE',...
            'PARTICIPANTID',...
            'ID',...
            'TIMEPOINT',...
            'BATTERY',...
            'SITE',...
            'TASK',...
            };
    end
    
    methods
        
        function [P] = ECKDataContainer(loadPath, loadGaze, autoCache)
            
            if ~exist('loadGaze', 'var') || isempty(loadGaze)
                loadGaze = true;
            end
            
            if ~exist('autoCache', 'var') || isempty(autoCache)
                autoCache = false;
            end
            
            P.ExtraData = struct;

            if exist('loadPath', 'var') && ~isempty(loadPath)
                P.LoadFolder(loadPath, loadGaze, autoCache);
            end
            
            %% initialise filters
            P.filterActive = false(1, length(P.AvailableFilters));
            P.filterName = P.AvailableFilters;
            P.filterValue = cell(1, length(P.AvailableFilters));
            
        end
        
        % data wrangling
        
        function IngestData(P, inPath, outPath)
            
            % read in a folder of raw (session) data from inPath and save 
            % to .mat format in outPath
            
            tic
            
            fprintf('<strong>Ingest data</strong>\n\n')
            fprintf('\tInput path: %s\n', inPath)
            fprintf('\tOutput path: %s\n', outPath)
            
            % check in/output paths
            if ~exist(inPath, 'dir')
                error('Input path does not exist.')
            end
            
            if ~exist(outPath, 'dir')
                [mkdirSuc, mkdirMsg] = mkdir(outPath);
                if ~mkdirSuc
                    error('Output path not found, error whilst trying to create:\n\n\t%s',...
                        mkdirMsg);
                else
                    fprintf('\tOutput path did not exist and was created.\n')
                end
            end
            
            fprintf('\n\tSearching input path for data...\n')
            
            % search for raw (session folders) data
            [md, dupIdx, scanResults] =...
                etLoadMetadata(inPath, false, false);
        
            if isempty(md)
                fprintf('No (load-able) files found.')
                return
            end        
        
            P.AuditOperation('ScanFolder', scanResults);
            
            % load
            loadCounter = 0;
            numSes = size(md, 1);
            fprintf('\n\tIngesting %d sessions...\n', numSes);
            success = cell(numSes, 1);
            reason = cell(numSes, 1);
            guid = parProgress('INIT', 1, numSes);
            
            parfor s = 1:numSes
                
                % display progress
                parProgress(guid, s, numSes);
                fprintf('\t\tProgress %.0f%%...\n',...
                    parReadProgress(guid) * 100);

                % load one dataset into tmp structure
                var = ECKData;
                [~, success{s}, reason{s}] = var.Load(md{s, 4}, true);
                
                % save data
                filename = [outPath, filesep, var.ParticipantID,...
                    '_', var.TimePoint, '_', var.Battery,...
                    '.eckdata.mat'];
                P.parSave(filename, var)

            end
            
            results =...
                [{'Data path', 'Success', 'Reason'}; md(:, 4), success, reason];
                       
            % remove empties
            P.RemoveEmptyData;
            P.FilterApply;
            
            P.AuditOperation('LoadFolder', results);
            
            fprintf('\n<strong>Ingest completed in %s</strong>\n\n',...
                datestr(toc / 86400, 'HH:MM:SS'));
                        
        end
        
        function results = Load(P, sessionPath)
            if isempty(P.data)
                idx = 1;
            else
                idx = length(P.data) + 1;
            end
            
            tmp = ECKData;
            [~, success, reason] = tmp.Load(sessionPath);
            results = [num2cell(success), reason];
            P.data{idx} = tmp;
            P.FilterApply;
        end
        
        function results = LoadFolder(P, folderPath, loadGaze, autoCache)
            
            tic
            
            if ~exist('loadGaze', 'var') || isempty(loadGaze)
                loadGaze = true;
            end
            
            if ~exist('autoCache', 'var') || isempty(autoCache)
                autoCache = false;
            end
            
            % find data
            fprintf('<strong>ECKDataContainer: LoadFolder:</strong> Searching folder for data...\n')
            
            % search for raw (session folders) data
            found = recdir(folderPath);                 % find all files and folders
            scanResults = found;                        % record for audit
            isSess = cellfun(@isSessionFolder, found);  % filter for session folders
            found = found(isSess);
            
%             [md, dupIdx, scanResults] =...
%                 etLoadMetadata(folderPath, false, false);            
%             
%             fprintf('done.\n')
%             
%             if isempty(md)
%                 fprintf('No (load-able) files found.')
%             end

            if isempty(found)
                fprintf('No (load-able) files found.')
            end            
            
            P.AuditOperation('ScanFolder', scanResults);
            
            % load
            loadCounter = 0;
            numSes = length(found);
            fprintf('<strong>ECKDataContainer: LoadFolder:</strong> Loading %d sessions...\n',...
                numSes);
            success = cell(numSes, 1);
            reason = cell(numSes, 1);
            guid = parProgress('INIT', 1, numSes);
            for s = 1:numSes
                tmp = ECKData;
                [~, success{s}, reason{s}] = tmp.Load(found{s}, loadGaze);
                addIdx = P.AddData(tmp);
                tmp = [];
                if autoCache, P.Data{addIdx}.Cached = true; end
                loadCounter = loadCounter + 1;
                parProgress(guid, s, numSes);
                fprintf('<strong>ECKDataContainer: LoadFolder:</strong> Loading sessions %.0f%%...\n',...
                    parReadProgress(guid) * 100);
            end
            
            results =...
                [{'Data path', 'Success', 'Reason'}; found, success, reason];
            
            % remove empties
            P.RemoveEmptyData;
            fprintf('<strong>ECKDataContainer: LoadFolder:</strong> %d sessions loaded in %s.\n',...
                loadCounter, reportTimeElapsed(toc))  
            
            P.FilterApply;
            
            P.AuditOperation('LoadFolder', results);
            
%             close(wb)
            
        end
        
        function results = LoadMatFolder(P, folderPath, autoCache)

            if ~exist('autoCache', 'var') || isempty(autoCache)
                autoCache = false;
            end
            
            % find data
%             wb = waitbar(0, 'Searching folder for data...');
            fprintf('<strong>ECKDataContainer: LoadMatFolder: </strong>Searching folder for data...\n')
            
            d = dir([folderPath, filesep, '*.mat']);
            
            numSes = length(d);
            results = cell(numSes, 1);
%             f = 1;
%             desChunks = 16;
%             parGUID = parProgress('INIT');
%             while f <= length(d)
%                         
%                 parProgress(parGUID, f, length(d));
%                 fprintf('<strong>ECKDataContainer: LoadMatFolder:</strong> Loading: %.01f%%...\n',...
%                     parReadProgress(parGUID) * 100);
% 
%                     % put a chunk of data into a temp var
%                     numChunks = desChunks;
%                     if numChunks + f - 1 > length(d)
%                         numChunks = length(d) - f + 1;
%                     end
%                         
%                     chunk = cell(numChunks, 1);
%                     
%                     parfor ch = 1:numChunks
%                         chunk{ch} = load([folderPath, filesep, d(f).name]);
%                         if isa(chunk{ch}.var, 'uint8')
%                             chunk{ch}.var = getArrayFromByteStream(chunk{ch}.var);
%                         end
%                     end
%                     
%                     for ch = 1:numChunks
%                         P.AddData(chunk{ch}.var, autoCache);
%                     end
%                     
%                     f = f + numChunks;
%                     
%             end
                        
                       
                for f = 1:length(d)
                
                if mod(f, 20) == 0
                    fprintf('<strong>ECKDataContainer: LoadMatFolder: </strong>Loading %.1f%%...\n',...
                        (f / length(d)) * 100)
                end
                
                results{f} = 'Success';
                
                try
                    tmp = load([folderPath, filesep, d(f).name]);
                    if ~isfield(tmp, 'var') && isfield(tmp, 'data')
                        tmp.var = tmp.data;
                        tmp = rmfield(tmp, 'data');
                    end
                    if isa(tmp.var, 'uint8')
                        tmp.var = getArrayFromByteStream(tmp.var);
                    end
                catch ERR
                    results{f} = sprintf('Error loading mat file: %s', ERR.message);
                end
                
                newIdx = P.AddData(tmp.var, autoCache);
                if autoCache, P.Data{newIdx}.Cached = true; end
                
            end
   
        end
        
        function [success, results] = LoadExportFolder(P, folderPath,...
                jobLabel, autoCache, singlePrecision)
            
            if ~exist('jobLabel', 'var') || isempty(jobLabel)
                jobLabel = 'UNNAMED';
            end
            
            if ~exist('autoCache', 'var') || isempty(autoCache)
                autoCache = false;
            end

            if ~exist('singlePrecision', 'var') || isempty(singlePrecision)
                singlePrecision = false;
            end
            
            fprintf('<strong>ECKDataContainer: LoadExportFolder: </strong>Searching folder for data...\n')
            
            d = dir([folderPath, filesep, '*.mat']);
            
            numSes = length(d);
            results = cell(numSes, 2);  
            success = false(numSes, 1);
            
            parGUID = parProgress('INIT');
            parTmp = cell(numSes, 1);
            parfor f = 1:numSes
                
                filename = [folderPath, filesep, d(f).name];
                
                try
                    tmp = [];
                    tmp = load(filename);
                    if isstruct(tmp) && isfield(tmp.data, 'ParticipantID')
                        results(f, :) = {filename, 'OK'};
                        success(f) = true;
                    else
                        results(f, :) = {filename, 'Not a valid data file'};
                        success(f) = false;
                    end
                catch ERR
                    results(f, :) = {filename, ERR.message};
                    success(f) = false;
                end
                
                if success(f)
                    
                    try

                        % optionally convert to single precision to save memory
                        if singlePrecision
                            numSegs = length(tmp.data.Segments);
                            for s = 1:numSegs
                                tmp.data.Segments(s).MainBuffer =...
                                    single(tmp.data.Segments(s).MainBuffer);
                            end
                        end                        
                        % convert to ECKData
                        converted = ECKStruct2ECKData(tmp.data);


                        parTmp{f} = converted; 
                    catch ERR
                        success(f) = false;
                    end
                        
                end
                
%                 if mod(f, 20) == 0
                    parProgress(parGUID, f, numSes);
                    prog = parReadProgress(parGUID) * 100;
                    fprintf('<strong>ECKDataContainer: LoadExportFolder: </strong>%.1f%%...\n',...
                        prog)
%                 end
                
            end
            
            for f = 1:numSes
                if success(f)
                    P.AddData(parTmp{f})
                end
            end
            
        end
        
        function results = LoadGaze(P)
            
            tmpData = cell(P.NumData, 1);
            results = cell(P.NumData, 1);
            for d = 1:P.NumData
                tmpData{d} = P.Data{d};
            end
            
            parfor d = 1:P.NumData
                curData = tmpData{d};
                if ~curData.GazeLoaded
                    curData.LoadGaze;
                    tmpData{d} = curData;
                    results{d} = 'Gaze loaded';
                else
                    results{d} = 'Gaze already loaded';
                end
            end
            
            for d = 1:P.NumData
                P.Data{d} = tmpData{d};
            end
            
            
            hdrResults = {'Outcome'};
            P.AuditOperation('LoadGaze', [hdrResults; results]);
            
        end
        
        function results = ClearGaze(P)
            
            for d = 1:length(P.NumData)
                if P.Data{d}.GazeLoaded
                    dc.Data{d}.ClearGaze;
                    results{d} = 'Gaze cleared';
                else
                    results{d} = 'Gaze not loaded';
                end
            end
            
            hdrResults = {'Outcome'};
            P.AuditOperation('ClearGaze', [hdrResults; results]);
            
        end
        
        function results = Save(P, outputPath, type)
            
            tic
            
            if ~exist('type', 'var') || isempty(type)
                type = 'MAT';
            end
            
            if ~exist(outputPath, 'dir')
                error('Output path does not exist.')
            end
                    
            switch type
                case 'SESSIONFOLDERS'
                    
                    warning('You are using the legacy save flag SESSIONFOLDERS.')

                    for d = 1:P.NumData
                        P.Data{d}.Save(outputPath);
                    end
                    
                case {'MAT', 'MATSER'}
                    
                    parGUID = parProgress('INIT');
                    
                    d = 1;
                    desChunks = 8;
                    while d <= P.NumData

                        % put a chunk of data into a temp var
                        numChunks = desChunks;
                        if numChunks + d - 1 > P.NumData
                            numChunks = P.NumData - d + 1;
                        end
                        
                        chunk = cell(numChunks, 1);
                        reCache = false(numChunks, 1);
                        for ch = 1:numChunks
                            
                            % get id of ECKData in dc
                            idx = d + ch - 1;
                            
                            parProgress(parGUID, idx, P.NumData);
                            fprintf('<strong>ECKDataContainer: Save:</strong> Saving: %.01f%%...\n', parReadProgress(...
                                parGUID) * 100);   
    
                            % uncache if necessary
                            if P.Data{d}.Cached
                                P.Data{d}.Cached = false;
                                reCache(ch) = true;
                            else
                                reCache(ch) = false;
                            end                   
                            
                            % store in temp var
                            chunk{ch} = P.Data{idx};
                            
                        end
                        
                        % par save
                        parfor ch = 1:numChunks
                            
                            tmp = chunk{ch};
                            
                            fileName = [outputPath, filesep, tmp.ParticipantID,...
                                '_', tmp.TimePoint, '_', tmp.Battery,...
                                tmp.GUID, '.eckdata.mat'];
                        
                            if strcmpi(type, 'MATSER')
                                tmp = getByteStreamFromArray(tmp);
                            end
                        
                            P.parSave(fileName, tmp);
                        
                        end
                        
                        % uncache
                        for ch = 1:numChunks
                            
                            % get id of ECKData in dc
                            idx = d + ch - 1;
    
                            % recache if necessary
                            if reCache(ch)
                                P.Data{d}.Cached = true;
                                reCache(ch) = false;
                            end
                            
                        end
                        
                        d = d + numChunks;
                        
                    end
                                                            
%                     for d = 1:P.NumData
%                                               
%                         if P.Data{d}.Cached
%                             P.Data{d}.Cached = false;
%                             reCache = true;
%                         else
%                             reCache = false;
%                         end
% 
%                         tmp = P.Data{d};
%                         
%                         parProgress(parGUID, d, P.NumData);
%                         fprintf('<strong>ECKDataContainer: Save:</strong> Saving: %.01f%%...\n', parReadProgress(...
%                             parGUID) * 100);
%                         
%                         % make filename
%                         fileName = [outputPath, filesep, tmp.ParticipantID,...
%                             '_', tmp.TimePoint, '_', tmp.Battery,...
%                             tmp.GUID, '.eckdata.mat'];
%                         
%                         if strcmpi(type, 'MATSER')
%                             tmp = getByteStreamFromArray(tmp);
%                         end
%                         
%                         P.parSave(fileName, tmp);
%                         
%                         if reCache, P.Data{d}.Cached = true; end
%                                                 
%                     end
                    
                    fprintf('<strong>ECKDataContainer: Save:</strong> %d datasets saved in %s\n',...
                        P.NumData, reportTimeElapsed(toc));
                                        
            end 
            
        end
                
        function idx = AddData(P, data, autoCache)
            
            if ~exist('autoCache', 'var') || isempty(autoCache)
                autoCache = false;
            end
            
            if ~isa(data, 'ECKData')
                error('Must pass an ECKData instance.')
            end
            
            P.data{end + 1} = copyHandleClass(data);
            P.data{end}.GetGUID;
            P.data{end}.Loaded = true;
            if autoCache, P.data{end}.Cached = true; end
            P.FilterApply;
            % specify data index (i.e. dc.Data array) as an output variable
            if nargout > 0
                idx = length(P.data);
            end
            
        end
        
        function idx = AddExportStruct(P, s)
            idx = P.AddData(ECKStruct2ECKData(s));
        end
        
        function RemoveEmptyData(P)
            
            d = 1;
            while d < length(P.data)
                if ~P.data{d}.Loaded
                   P.data = [P.data(1:d - 1), P.data(d + 1:end)];
                else
                    d = d + 1;
                end
           end
            
        end
        
        function [qualityHdr, qualityData, qualityZScores] = ...
                QualitySummary(P, type)
           
            if isempty(P.Data), qualityHdr = {}; qualityData = {}; return, end
            
            % determine type
            if ~exist('type', 'var') || isempty(type)
                if ~P.MatchingTypes
                    error('Cannot summarise data quality across different data types. Specify a type when calling QualitySummary.')
                else
                    type = P.Data{1}.Type;
                    filtIdx = true(1, length(P.Data));
                end
            else
                filtIdx = false(1, length(P.Data));
                for d = 1:length(P.Data)
                    filtIdx(d) = strcmpi(P.Data{d}.Type, type);
                end
            end
            
            % number of datasets
            numData = sum(filtIdx);
                        
            switch type
                case 'ET'
                    
                    %% general
                    
                    qualityHdr = {...
                        'Participant ID',...
                        'TimePoint',...
                        'Battery',...
                        'Site',...
                        'Duration (secs)',...
                        'Mean Sample Rate',...
                        'Proportion No Eyes',...
                        'Flicker Ratio',...
                        'Flicker Ratio Valid',...
                        'Fixation RMS',...
                        'Posthoc Calib Drift X',...
                        'Posthoc Calib Drift Y',...
                        'Distance From Screen Mean',...
                        'Distance From Screen SD',...
                        'Distance From Centre Of Headbox Mean',...
                        'Distance From Centre Of Headbox SD'};
                    
                    % preallocate data array
                    qualityData = cell(numData, length(qualityHdr));
                    
%                     st = ECKStatus('Computing data quality...');
                    
                    % store data into array (out from DC) to allow
                    % reasonable parallel memory management
                    tmpData = cell(1, P.NumData);
                    for d = 1:P.NumData
                        tmpData{d} = P.Data{d};
                    end
                    numFiltData = length(filtIdx == 1);
                    
                    % loop through and populate data array with data
                    % quality metric
                    for d = 1:length(P.Data)
                        
                        if filtIdx(d)
                            % update status
%                             st.Status = ...
%                                 sprintf('Computing data quality (%d of %d)...',...
%                                 d, length(P.Data(filtIdx)));
                            fprintf('Computing data quality (%d of %d)...\n',...
                                d, numFiltData);    
                            
                            curData = tmpData{d};
                            
                            
%                             % attempt to load gaze data if necessary
%                             if ~curData.GazeLoaded
%                                 curData.LoadGaze;
%                                 gazeWasLoaded = true;
%                             else
%                                 gazeWasLoaded = false;
%                             end
%                             
                            try
                                tmp = etDataQualityMetric3(curData.MainBuffer,...
                                    curData.TimeBuffer, curData.EventBuffer);
                            
%                                 if gazeWasLoaded
%                                     curData.ClearGaze;
%                                 end

                                % store     
                                noEyes = find(tmp.EyeValidity(:, 1) == 0);

                                parTmp = {...
                                    curData.ParticipantID,...
                                    curData.TimePoint,...
                                    curData.Battery,...
                                    curData.Site,...
                                    tmp.DurationS,...
                                    tmp.SampleFrequencyMean,...
                                    tmp.EyeValidity(noEyes, 3),...
                                    tmp.FlickerRatio,...
                                    tmp.FlickerRatioValid,...
                                    tmp.FixationRMS,...
                                    [],...
                                    [],...
                                    tmp.DistanceFromScreenMean,...
                                    tmp.DistanceFromScreenSD,...
                                    tmp.DistanceFromHeadBoxCentreMean,...
                                    tmp.DistanceFromHeadBoxCentreSD};

                                qualityData(d, :) = parTmp;
                            
                            catch ERR
%                                 rethrow ERR
                                fprintf('Error dataset %d: %s\n', d, ERR.message);
                            end
                            
                            curData = [];
                            
%                             qualityData{d, 1} = P.Data{d}.ParticipantID;
%                             qualityData{d, 2} = P.Data{d}.TimePoint;
%                             qualityData{d, 3} = P.Data{d}.Battery;
%                             qualityData{d, 4} = P.Data{d}.Site;
%                             qualityData{d, 5} = tmp.DurationS;
%                             qualityData{d, 6} = tmp.SampleFrequencyMean;
%                             qualityData{d, 7} = tmp.EyeValidity(noEyes, 3);
%                             qualityData{d, 8} = tmp.FlickerRatio;
%                             qualityData{d, 9} = tmp.FixationRMS;
                        end
                        
                    end
                    
                    clear curData tmpData
                    
                    %% posthoc calib
                    
                    % get data
                    [~, phData] = etCollateTask(P, 'posthoc_calib');
                    
                    if ~isempty(phData)
                        
                        % calculate mean accuracy 
                        [subsLabels, ~, subs] = unique(phData(:, 1));
                        phDriftX = accumarray(subs, cell2mat(phData(:, 15)),...
                            [], @mean);
                        phDriftY = accumarray(subs, cell2mat(phData(:, 16)),...
                            [], @mean);

                        % loop through and append post-hoc accuracy for each
                        % dataset
                        for d = 1:length(P.Data)
                            if filtIdx(d)
                                phD = find(strcmpi(P.Data{d}.ParticipantID,...
                                    subsLabels));
                                if ~isempty(phD)
                                    qualityData{d, 10} = phDriftX(phD);
                                    qualityData{d, 11} = phDriftY(phD);
                                end
                            end
                        end
                    end
                    
                    %% gap
                    
                    % get data
                    [gapLogHdr, gapLogData] = etCollateTask(P, 'gap_trial');
                    
                    if ~isempty(gapLogData)
                        
                        % set up headers, resize main quality table to take
                        % gap data
                        gapHdr = {...
                            'Gap: Valid Trials',...
                            'Gap: Gaze on CS',...
                            'Gap: Gaze on CS at PS Onset',...
                            'Gap: Gaze to PS within 1200ms',...
                            'Gap: Gaze not to opposite side',...
                            'Gap: SRT > 200ms',...
                            'Gap: Prop lost eyes',...
                            'Gap: CS Skipped',...
                            'Gap: PS Skipped'};
                        
                        qualityHdr = [qualityHdr, gapHdr];
                        qualityDataIdx = size(qualityData, 2) + 1;
                        qualityData = [qualityData, cell(length(P.Data),...
                            length(gapHdr))];

                        % look up columns for relevant variables
                        gapColumns = [...
                            find(strcmpi('ParticipantID', gapLogHdr), 1, 'first'),...
                            find(strcmpi('TimePoint', gapLogHdr), 1, 'first'),...
                            find(strcmpi('ValidTrial', gapLogHdr), 1, 'first'),...
                            find(strcmpi('ValidGazeOnCS', gapLogHdr), 1, 'first'),...
                            find(strcmpi('ValidGazeOnCsAtPSOnset', gapLogHdr), 1, 'first'),...
                            find(strcmpi('ValidGazeToPS1200', gapLogHdr), 1, 'first'),...
                            find(strcmpi('ValidGazeToPsOppo1200', gapLogHdr), 1, 'first'),...
                            find(strcmpi('ValidGazeToPS200', gapLogHdr), 1, 'first'),...
                            find(strcmpi('ET.LostProp', gapLogHdr), 1, 'first'),...
                            find(strcmpi('CSGazeSkipped', gapLogHdr), 1, 'first'),...
                            find(strcmpi('PSGazeSkipped', gapLogHdr), 1, 'first')];
                        
                        % get data for relevant variables
                        gapData = gapLogData(:, gapColumns);
    
                        % calculate mean summary for each variable
                        [gap_subsLabels, ~, gap_subs] = unique(gapData(:, 1));
                        gapSummary = zeros(length(gap_subsLabels), length(gapHdr));

                        gapSummary(:, 1) = accumarray(gap_subs,...  
                            cell2mat(gapData(:, 3)), [], @mean);
                        gapSummary(:, 2) = accumarray(gap_subs,...
                            cell2mat(gapData(:, 4)), [], @mean);
                        gapSummary(:, 3) = accumarray(gap_subs,...
                            cell2mat(gapData(:, 5)), [], @mean);
                        gapSummary(:, 4) = accumarray(gap_subs,...
                            cell2mat(gapData(:, 6)), [], @mean);
                        gapSummary(:, 5) = accumarray(gap_subs,...
                            cell2mat(gapData(:, 7)), [], @mean);
                        gapSummary(:, 6) = accumarray(gap_subs,...
                            cell2mat(gapData(:, 8)), [], @mean);
                        gapSummary(:, 7) = accumarray(gap_subs,...
                            cell2mat(gapData(:, 9)), [], @mean);
                        gapSummary(:, 8) = accumarray(gap_subs,...
                            cell2mat(gapData(:, 10)), [], @mean);
                        gapSummary(:, 9) = accumarray(gap_subs,...
                            cell2mat(gapData(:, 11)), [], @mean);
                        
                        % loop through and append gap summary 
                        for d = 1:length(P.Data)
                            if filtIdx(d)
                                gapD = find(strcmpi(P.Data{d}.ParticipantID,...
                                    gap_subsLabels));
                                if ~isempty(gapD)
                                    qualityData(d, qualityDataIdx:end) =...
                                        num2cell(gapSummary(gapD, :));
                                end
                            end
                        end
                        
                    end
                    
                    %% static images
                    
                    % get data
                    [siLogHdr, siLogData] = etCollateTask(P, 'staticimages_trial');
                    
                    if ~isempty(siLogData)
                        
                        % set up headers, resize main quality table to take
                        % si data
                        siHdr = {...
                            'Static Images: Prop lost eyes',...
                            'Static Images: Skipped'};
                        
                        qualityHdr = [qualityHdr, siHdr];
                        qualityDataIdx = size(qualityData, 2) + 1;
                        qualityData = [qualityData, cell(length(P.Data),...
                            length(siHdr))];

                        % look up columns for relevant variables
                        siColumns = [...
                            find(strcmpi('ParticipantID', siLogHdr), 1, 'first'),...
                            find(strcmpi('TimePoint', siLogHdr), 1, 'first'),...
                            find(strcmpi('ET.LostProp', siLogHdr), 1, 'first'),...
                            find(strcmpi('Skipped', siLogHdr), 1, 'first')];
                        
                        % get data for relevant variables
                        siData = siLogData(:, siColumns);
    
                        % calculate mean summary for each variable
                        [si_subsLabels, ~, si_subs] = unique(siData(:, 1));
                        siSummary = zeros(length(si_subsLabels), length(siHdr));

                        siSummary(:, 1) = accumarray(si_subs,...  
                            cell2mat(siData(:, 3)), [], @mean);
                        siSummary(:, 2) = accumarray(si_subs,...
                            cell2mat(siData(:, 4)), [], @mean);
                        
                        % loop through and append si summary 
                        for d = 1:length(P.Data)
                            if filtIdx(d)
                                siD = find(strcmpi(P.Data{d}.ParticipantID,...
                                    si_subsLabels));
                                if ~isempty(siD)
                                    qualityData(d, qualityDataIdx:end) =...
                                        num2cell(siSummary(siD, :));
                                end
                            end
                        end
                        
                    end
                    
                    %% natural scenes
                    
                    % get data
                    [nsLogHdr, nsLogData] = etCollateTask(P, 'scenes_trial');
                    
                    if ~isempty(nsLogData)
                        
                        % set up headers, resize main quality table to take
                        % ns data
                        nsHdr = {...
                            'Natural scenes: Skipped'};
                        
                        qualityHdr = [qualityHdr, nsHdr];
                        qualityDataIdx = length(qualityData) + 1;
                        qualityData = [qualityData, cell(length(P.Data),...
                            length(nsHdr))];

                        % look up columns for relevant variables
                        nsColumns = [...
                            find(strcmpi('ParticipantID', nsLogHdr), 1, 'first'),...
                            find(strcmpi('TimePoint', nsLogHdr), 1, 'first'),...
                            find(strcmpi('MovieSkipped', nsLogHdr), 1, 'first')];
                        
                        % get data for relevant variables
                        nsData = nsLogData(:, nsColumns);
    
                        % calculate mean summary for each variable
                        [ns_subsLabels, ~, ns_subs] = unique(nsData(:, 1));
                        nsSummary = zeros(length(ns_subsLabels), length(nsHdr));

                        nsSummary(:, 1) = accumarray(ns_subs,...  
                            cell2mat(nsData(:, 3)), [], @mean);
                        
                        % loop through and append si summary 
                        for d = 1:length(P.Data)
                            if filtIdx(d)
                                nsD = find(strcmpi(P.Data{d}.ParticipantID,...
                                    ns_subsLabels));
                                if ~isempty(nsD)
                                    qualityData(d, qualityDataIdx:end) =...
                                        num2cell(nsSummary(nsD, :));
                                end
                            end
                        end
                        
                    end
                    
                    % convert to z scores
                    tmp = qualityData(:, 5:end);
                    tmp(cellfun(@isempty, tmp)) = {nan};
                    numbers = cell2mat(tmp);
                    z = zscore(numbers);
                    qualityZScores = [qualityData(:, 1:4), num2cell(z)];
                    
                    st.Status = sprintf('Computed quality for %d datasets.\n',...
                        length(P.Data(filtIdx)));
                    
                case 'EEG'
                    
                    qualityHdr = {};
                    qualityData = {};
            end
            
            
            
        end
        
        function [metaData] = LegacyMetadata(P)
           
            if isempty(P.Data)
                metaData = {};
                return
            end
            
            metaData = P.Table;
            metaData = metaData(:, 2:end);
            
        end
        
        function [success, outcome] = BatchExportToGrafix(P, exportPath)
           
            if ~exist('exportPath', 'var') 
                error('Must specify a path to export to.')
            end
            
            if ~exist(exportPath, 'dir')
                mkdir(exportPath)
            end
            
            success = false(sum(P.NumData), 1);
            outcome = cell(sum(P.NumData), 1);
            
            fprintf('Preparing to export...\n')
            
            guid = parProgress('INIT', 1, P.NumData);
            
            % pre-fetch data
            numSes = P.NumData;
            tmpData = cell(numSes, 1);
            for d = 1:numSes
                if P.dataFilter(d)
                    tmpData{d} = P.Data{d};
                end
            end
            
            % export
            parfor d = 1:numSes
               
                if ~isempty(tmpData{d})
                    
                    curData = tmpData{d};
                    
                    parProgress(guid, d, numSes);
                    fprintf('Exporting to GraFIX: %.0f%% [ID: %s, Dataset: %d]...\n',...
                        parReadProgress(guid) * 100, curData.ParticipantID, d);
                    
                    % attempt to load gaze data if necessary
                    if ~curData.GazeLoaded
                        curData.LoadGaze;
                        gazeWasLoaded = true;
                    else
                        gazeWasLoaded = false;
                    end
                            
                    [success(d), outcome{d}] =...
                        curData.ExportToGrafix(exportPath);
                    
                    if gazeWasLoaded
                        curData.ClearGaze;
                    end
                                
                else
                    success(d) = false;
                    outcome{d} = 'Excluded by filter';
                end
                
            end
            
            clear curData tmpData
                            
        end
        
        % filtering
        function [varargout] = FilterActive(P, varargin)
            % determine if we are setting or getting
            if nargout == 0 && nargin == 3
                
                % setting the filter
                name = varargin{1};
                active = varargin{2};
                idx = find(strcmpi(P.filterName, name));
                
                if isempty(idx)
                    error('No filter named (%s). Refer to AvailableFilters property.', name)
                end
                
                if ~islogical(active)
                    error('Filters must be set active with a logical (true/false) arguments.')
                end
                
                P.filterActive(idx) = active;
                P.FilterApply;
                P.FilterSummarise;
                
            elseif nargout == 1 && nargin == 2
                
                % getting the filter
                name = varargin{1};
                idx = find(strcmpi(P.filterName, name));
                
                if isempty(idx)
                    error('No filter named (%d). Refer to AvailableFilters property.')
                end
                
                varargout{1} = P.filterActive(idx);
                
            elseif nargin == 1
                
                % summarise filter settings
                P.FilterSummarise;
                
            end
            
        end
        
        function [varargout] = FilterValue(P, varargin)
            % determine if we are setting or getting
            if nargout == 0 && nargin == 3
                
                % setting the filter
                name = varargin{1};
                value = varargin{2};
                idx = find(strcmpi(P.filterName, name));
                
                if isempty(idx)
                    error('No filter named (%s). Refer to AvailableFilters property.', name)
                end
                
                P.filterValue{idx} = value;
                P.filterActive(idx) = true;
                P.FilterApply;
                P.FilterSummarise;
                
            elseif nargout == 1 && nargin == 2
                
                % getting the filter
                name = varargin{1};
                idx = find(strcmpi(P.filterName, name));
                
                if isempty(idx)
                    error('No filter named (%d). Refer to AvailableFilters property.')
                end
                
                varargout{1} = P.filterValue(idx);
                
            elseif nargin == 1
                
                % summarise filter settings
                P.FilterSummarise;
                
            end
            
        end
        
        function FilterDisableAll(P)
            P.filterActive = false(1, length(P.filterName));
            P.FilterApply;
            P.FilterSummarise;
        end
        
        function FilterSummarise(P)
            table = {'Filter Name', 'Active', 'Value'};
            table = [table; P.filterName', num2cell(P.filterActive)', P.filterValue'];
            fprintf('<strong>\n\nFilter summary:</strong>\n\n')
            disp(table);
            fprintf('\nNumber of datasets loaded: %d.\n', length(P.data))
            fprintf('Number of active datasets after filtering: %d\n',...
                sum(P.dataFilter));
        end
        
        function FilterApply(P)
            
            P.dataFilter = true(1, length(P.data));
            
            for d = 1:length(P.data)
                for f = 1:length(P.filterActive)
                    if P.filterActive(f)
                        switch P.filterName{f}
                            case 'TYPE'
                                P.dataFilter(d) = P.dataFilter(d) &&...
                                    strcmpi(P.data{d}.Type,...
                                    P.filterValue(f));
                            case {'PARTICIPANTID', 'ID'}
                                P.dataFilter(d) = P.dataFilter(d) &&...
                                    strcmpi(P.data{d}.ParticipantID,...
                                    P.filterValue(f));        
                            case 'TIMEPOINT'
                                if isnumeric(P.data{d}.TimePoint)
                                    TP = num2str(P.data{d}.TimePoint);
                                elseif ischar(P.data{d}.TimePoint)
                                    TP = P.data{d}.TimePoint;
                                else 
                                    error('TimePoint in a format other than numeric/char')
                                end
                                if isnumeric(P.filterValue{f})
                                    TP_filt = num2str(P.filterValue{f});
                                elseif ischar(P.filterValue{f})
                                    TP_filt = P.filterValue{f};
                                else 
                                    error('Filter value in a format other than numeric/char')
                                end                                
                                P.dataFilter(d) = P.dataFilter(d) &&... 
                                    strcmpi(TP, TP_filt);
                            case 'BATTERY'
                                P.dataFilter(d) = P.dataFilter(d) &&...
                                    strcmpi(P.data{d}.Battery,...
                                    P.filterValue(f));
                            case 'SITE'
                                P.dataFilter(d) = P.dataFilter(d) &&...
                                    strcmpi(P.data{d}.Site,...
                                    P.filterValue(f));
                            case 'TASK'
                                P.dataFilter(d) = P.dataFilter(d) &&...
                                    any(strcmpi(P.data{d}.Log.FunName,...
                                    P.filterValue{f}));
                        end
                    end
                end
            end
            
        end
        
        % data extraction
        function [mainBuffers, timeBuffers, eventBuffers] = GetAllGazeData(P)
            
            mainBuffers = cell(1, P.NumData);
            timeBuffers = cell(1, P.NumData);
            eventBuffers = cell(1, P.NumData);
            for d = 1:P.NumData
                mainBuffers{d} = P.Data{d}.MainBuffer;
                timeBuffers{d} = P.Data{d}.TimeBuffer;
                eventBuffers{d} = P.Data{d}.EventBuffer;
            end
            
        end
        
        % participant details/counting
        
        function [newVal] = MatchingTypes(P)
            if isempty(P.Data)
                newVal = false;
            elseif length(P.Data) == 1
                newVal = true;
            else
                tab = P.Table;
                if ~isempty(tab)
                    newVal = isequal(tab{:, 1});
                else 
                    newVal = false;
                end
            end
        end
        
        function [PIDs] = Participants(P)
            
            if P.ProgressBarEnabled 
                wb = waitbar(0, 'Retrieving participant list...');
            end
            
            % loop through and gather PIDs
            PIDs = cell(P.NumData, 1);
            if ~isempty(P.Data)
                for d = 1:P.NumData
                    
                    if P.ProgressBarEnabled && mod(d, 200) == 0
                        wb = waitbar(d / length(P.Data), wb, 'Retrieving participant list...');
                    end
                    
                    PID = P.Data{d}.ParticipantID;
                    if ~any(strcmpi(PIDs, PID))
                        PIDs{d} = PID;
                    end
                    
                end
                
                % remove blanks
                PIDs(cellfun(@isempty, PIDs)) = [];
                
                % remove duplicates
                if ~all(cellfun(@isempty, PIDs))
                    PIDs = unique(PIDs);
                end
                
            end
            
            if P.ProgressBarEnabled
                close(wb)
            end
            
        end
        
        function [tasks] = Tasks(P)
            
            if P.ProgressBarEnabled 
                wb = waitbar(0, 'Retrieving task list...');
            end
            
            % loop through and gather PIDs
            tasks = {};
            if ~isempty(P.Data)
                for d = 1:P.NumData
                    
                    if P.ProgressBarEnabled && mod(d, 10) == 0
                        wb = waitbar(d / length(P.Data), wb, 'Retrieving task list...');
                    end
                    
                    if isfield(P.Data{d}.Log, 'FunName')
                        tmpTasks = P.Data{d}.Log.FunName;
                        if ~isempty(tmpTasks)
                            tasks = unique([tasks; tmpTasks']);
                        end
                    end
                    
                end
                
                % remove blanks
                tasks(cellfun(@isempty, tasks)) = [];
                
                % remove duplicates
                if ~all(cellfun(@isempty, tasks))
                    tasks = unique(tasks);
                end
                
            end
            
            if P.ProgressBarEnabled
                close(wb)
            end

            
%             taskTable = etListTasks(P);
%             if ~isempty(taskTable)
%                 tasks = taskTable(:, 1);
%             else
%                 tasks = {};
%             end
            
        end
        
        function [TPs] = Timepoints(P)
            
%             % loop through and collect timepoints
%             TPs = {};
%             if ~isempty(P.Data)
%                 for d = 1:length(P.Data)
%                     TPs = [TPs; P.Data{d}.TimePoint];
%                 end

            if P.ProgressBarEnabled 
                wb = waitbar(0, 'Retrieving timepoint list...');
            end
            
            % loop through and gather PIDs
            TPs = cell(P.NumData, 1);
            if ~isempty(P.Data)
                for d = 1:P.NumData
                    
                    if P.ProgressBarEnabled && mod(d, 200) == 0
                        wb = waitbar(d / length(P.Data), wb, 'Retrieving timepoint list...');
                    end
                    
                    TPs{d} = P.Data{d}.TimePoint;
                    
                end 
                
                % convert to string
                if ~all(cellfun(@isempty, TPs))
                    TPs = convertCell(TPs, 'string');
                    TPs = unique(TPs);
                end
                
            end
            
            if P.ProgressBarEnabled
                close(wb)
            end
            
        end
        
        function [PIDCount] = ParticipantsCountData(P, PID)
            
            PIDCount = 0;
            if ~isempty(P.Data)
                for d = 1:length(P.Data)
                    if strcmpi(P.Data{d}.ParticipantID, PID)
                        PIDCount = PIDCount + 1;
                    end
                end
            end
            
        end
            
        function [varargout] = Table(P)
            
            if isempty(P.Data)
                varargout = {};
                return
            end
            
            if P.ProgressBarEnabled 
                wb = waitbar(0, 'Cataloguing data...');
            end
            
            table = cell(P.NumData, 11);
            for d = 1:P.NumData
                if P.Data{d}.Loaded
                    
                    if P.ProgressBarEnabled && mod(d, 200) == 0
                        wb = waitbar(d / length(P.Data), wb, 'Cataloguing data...');
                    end
                    
                    % count log entries, if there are any
                    if isfield(P.Data{d}.Log, 'FunName')
                        logLen = length(P.Data{d}.Log.FunName);
                    else 
                        logLen = 0;
                    end
                    
                    if isempty(P.Data{d}.Log)
                        error('Log data is empty - should be empty struct!')
                    end
                    
                    table{d, 1}     =   P.Data{d}.Type;
                    table{d, 2}     =   P.Data{d}.ParticipantID;
                    table{d, 3}     =   P.Data{d}.Battery;
                    table{d, 4}     =   P.Data{d}.TimePoint;
                    table{d, 5}     =   P.Data{d}.SessionPath;
                    table{d, 6}     =   logLen;
                    table{d, 7}     =   P.Data{d}.Tracker;
                    table{d, 8}     =   P.Data{d}.Log;
                    table{d, 9}     =   zeros(1, 26);
                    table{d, 10}    =   zeros(1, 2);
                    table{d, 11}    =   {0, 0, ''};
                    
%                     table(d, :) = [...
%                         {P.Data{d}.Type},...
%                         P.Data{d}.ParticipantID,...
%                         P.Data{d}.Battery,...
%                         P.Data{d}.TimePoint,...
%                         P.Data{d}.SessionPath,...
%                         logLen,...
%                         P.Data{d}.Tracker,...
%                         P.Data{d}.Log,...
%                         {zeros(1, 26)},...
%                         {zeros(1, 2)},...
%                         {{0, 0, ''}},...
%                         ];

                    % if ET, add buffers
                    if strcmpi(P.Data{d}.Type, 'ET') && ...
                            ~P.Data{d}.Cached
                        table{d, 9}     =   P.Data{d}.MainBuffer;
                        table{d, 10}    =   P.Data{d}.TimeBuffer;
                        table{d, 11}    =   P.Data{d}.EventBuffer;
                    end
                end
            end
            
            % if not ouputting to a variable, display as a table with
            % headers
            if nargout == 0
                hdr = {...
                    'Type',...
                    'ParticipantID',...
                    'Battery',...
                    'Time Point',...
                    'Session Path',...
                    'Num Tasks',...
                    'Tracker',...
                    'Log',...
                    'Main Buffer',...
                    'Time Buffer',...
                    'Event Buffer'};
                disp([hdr; table])
            else
                varargout = {table};
            end
            
            if P.ProgressBarEnabled
                close(wb)
            end
            
        end
        
        function [table] = ParticipantTaskTable(P)
            
            % get unique lists of participants and tasks
            pids = sort(P.Participants);
            tasks = sort(P.Tasks);
            
            % task x participants table to hold trial counts
            tab = nan(length(pids), length(tasks));
            
            % loop through all participants, and all tasks, count number of
            % trials for each task
            for d = 1:length(pids)
                
                for t = 1:length(tasks)
                    
                    pid = pids{d};
                    task = tasks{t};
                    found = find(strcmpi(P.Data{d}.Log.FunName, task), 1, 'first');
                    if ~isempty(found)
                        numFound = size(P.Data{d}.Log.Data{found}, 1);
                        tab(d, t) = numFound;
                    end
                    
                end
                
            end
            
            % append row/column headers
            table = num2cell(tab);
            table = [pids, table];
            table = [cellstr(' '), tasks'; table];
            
            % make heatmeap
            tabMax = repmat(max(tab), size(tab, 1), 1);
            nanCol = [.125, 0, .25];
%             nanCol = [0, 0, 0];
            hm = repmat(nanCol, 6, 1);
            f = 255 / 255;
            hm = [repmat(nanCol, 3, 1); f, 0, 0; f, f/2, 0; 0, f, 0];
            tab(isnan(tab)) = -1;
            tabProp = tab ./ tabMax;
            imagesc(tabProp);
            colorbar;
            colormap(hm);
%             set(gca, 'interpreter', 'none')
            set(gca, 'yticklabel', pids);
            set(gca, 'ytick', 1:length(pids));
            set(gca, 'xtick', 1:length(tasks));
            set(gca, 'xticklabel', tasks);
            set(gca, 'xaxislocation', 'top');
%             set(gca, 'xminorgrid', 'on');
%             set(gca, 'yminorgrid', 'on');
%             rotateXLabels(gca, -90)
            
        end
        
        % auditing
        
        function AuditOperation(P, operationName, results)
            
            % check vars
            if ~exist('operationName', 'var') || isempty(operationName)
                error('Must supply an operation name.')
            end
            
            if ~ischar(operationName)
                error('operationName must be a char.')
            end
            
            if ~exist('results', 'var'), results = {}; end
            
            if ~iscell(results)
                error('Results must be a cell array.')
            end
            
            % store operation details in private audit struct
            idx = length(P.audit) + 1;
            P.audit{idx}.Operation = operationName;
            P.audit{idx}.Results = results;
            P.audit{idx}.TimeDate = now;
            P.audit{idx}.Username =...
                char(java.lang.System.getProperty('user.name'));
            
        end
        
        % get/set methods
           
        function [newVal] = get.Data(P)
            newVal = P.data(P.dataFilter);
        end
        
        function P = set.Data(P, val)
            P.data = val;
        end
              
        function [numData] = get.NumData(P)
            
            if ~isempty(P.Data)
                numData = length(P.Data);
            else
                numData = 0;
            end
            
        end      
        
        function [val] = get.Audit(P)
            
            val = P.audit;
            
            for a = 1:length(P.audit)
                
                % get number of rows, minus the header row
                numRows = size(P.audit{a}.Results, 1) - 1;
                
                % build new header row by appending extra coulmn headers
                hdr = P.audit{a}.Results(1, :);
                hdr = ['Operation', 'Username', 'TimeDate', hdr];
                
                % build new data rows 
                data = P.audit{a}.Results(2:end, :);
                data = [...
                    cellstr(repmat(P.audit{a}.Operation, numRows, 1)),...
                    cellstr(repmat(P.audit{a}.Username, numRows, 1)),...
                    num2cell(repmat(P.audit{a}.TimeDate, numRows, 1)),...
                    data];
                
                val{a}.Table = [hdr; data];
                
            end     
            
        end
               
    end
    
    methods (Access=private)
        
        function parSave(P, fileName, var)
            
            save(fileName, 'var', '-v6');
            
        end
        
    end

        
end