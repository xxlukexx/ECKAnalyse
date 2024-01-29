function res = adbCombineDups(adb)

    % output var
    res = table;
    
    % quit if not dups
    [has, keys] = adb.HasDuplicates;
    if ~has, return, end;

    % get number of unique IDs
    tab = adb.DuplicateTable;    
    [ids_u, ids_i, ids_s] = unique(tab.ID);
    numIDs = length(ids_u);
    fprintf('Found %d duplicate sessions, with %d unique IDs in ADB.\n',...
        length(keys), numIDs)
    
    % loop through sessions
    for s = 1:numIDs
        
        fprintf('\t- Loading sessions for ID %d (%s)...\n', s, ids_u{s})
        % get paths to data
        pths = tab.SessionPath(ids_s == s);
        % load data
        dc = ECKDataContainer;
        cellfun(@(x) dc.Load(x), pths);
        % convert to legacy metadata format
        md = dc.LegacyMetadata;
        % storage for final actions
        action = ones(dc.NumData, 1);   % default to 1 = combine
        
        % find duplicates
        ser = cell(dc.NumData, 1);
        for r = 1:dc.NumData
            compare = md(r, [1:3, 7:10]);
            ser{r} = CalcMD5(getByteStreamFromArray(compare));
        end
        % tabulate to find numbers of duplicates
        tb = tabulate(ser);
        dupNum = cell2mat(tb(:, 2));
        % remove non-duplicates
        tb = tb(dupNum > 1, :);  
        if ~isempty(tb)
            % find indices of rows that have duplicates
            dupIdx = cellfun(@(x) find(strcmpi(ser, x)), tb(:, 1),...
                'uniform', 0);
            % remove first instance of each duplicate - we will keep
            % this one as the "master/original" row and delete all
            % others
            dupIdx = cellfun(@(x) x(2:end), dupIdx, 'uniform', 0);
            % delete duplicate rows from the table
            remIdx = [];
            for dup = 1:length(dupIdx)
                remIdx = [remIdx; cell2mat(dupIdx(dup))];
            end   
            action(remIdx) = 2;     % 2 = delete
        end

        % combine
        fprintf('\t- Combining...\n')
        md_comb = etCombineSessions(md(action == 1, :));
        
        % remove duplicate ET samples
        mb = md_comb{1, 8}; 
        tb = md_comb{1, 9};
        [~, so] = sort(tb(:, 1));
        mb = mb(so, :);
        tb = tb(so, :);
        delta = tb(2:end, 1) - tb(1:end - 1, 1);
        tb(delta == 0, :) = [];
        mb(delta == 0, :) = [];
        mb_comb{1, 8} = mb;
        mb_comb{1, 9} = tb;
        
        % set combined to be deleted
        action(action == 1) = 2;
        
        % delete
        cellfun(@(x) rmdir(x, 's'), md(action == 2, 4));
        
        % write data
        fprintf('\t- Writing...\n')
        outPath = md_comb{1, 4};
        mkdir(outPath);
        trackInfo = md_comb{1, 6};
        Log = md_comb{1, 7};
        save([outPath, filesep, 'tracker.mat'], 'trackInfo');
        save([outPath, filesep, 'tempData.mat'], 'Log');

        % write ET
        gazePath = [outPath, filesep, 'gaze'];
        tp = dc.Data{1}.TimePoint;
        if isnumeric(tp), tp = num2str(tp); end
        postFix = ['_', dc.Data{1}.ParticipantID, '_', tp];     
        mkdir(gazePath)
        mainBuffer = md_comb{1, 8};
        timeBuffer = md_comb{1, 9};
        eventBuffer = md_comb{1, 10};
        save([gazePath, filesep, 'mainBuffer', postFix, '.mat'], 'mainBuffer')
        save([gazePath, filesep, 'timeBuffer', postFix, '.mat'], 'timeBuffer')
        save([gazePath, filesep, 'eventBuffer', postFix, '.mat'], 'eventBuffer')
        ECKSaveETGazeTime([gazePath, filesep, 'session gaze data_',...
            postFix, '.csv'], mainBuffer, timeBuffer);
        ECKSaveETEvents([gazePath, filesep, 'session events_',...
            postFix, '.csv'], eventBuffer);
        ECKSaveLog(outPath, Log);
        clear mainBuffer timeBuffer eventBuffer trackInfo Log
        
    end

end