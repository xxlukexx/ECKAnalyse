function [success, id] = getIDFromSessionFolder(path_ses)

    id = {};
    success = true;
    
    if ~exist(path_ses, 'dir') 
        return
    end
     
    % search in tracker
    file_tracker = findFilename('tracker', path_ses);
    if ~isempty(file_tracker) && iscell(file_tracker) 
        file_tracker = file_tracker{1};
    end    
    if ~isempty(file_tracker)
        try
            tmp_tracker = load(file_tracker);
        catch ERR
            success = false;
            return
        end
        if isfield(tmp_tracker, 'trackInfo') &&...
                isfield(tmp_tracker.trackInfo, 'ParticipantID')
            id = tmp_tracker.trackInfo.ParticipantID;
            if ~isempty(id)
                if isnumeric(id), id = num2str(id); end
                if ischar(id), return, end
            end
        end
    end
    
    % look for ID in gaze folder
    file_mb = findFilename('mainBuffer', [path_ses, filesep, 'gaze']);
    if ~isempty(file_mb)
        if iscell(file_mb), file_mb = file_mb{1}; end
        [~, file] = fileparts(file_mb);
        if ~isempty(file)
            parts = strsplit(file, '_');
            if length(parts) >= 2
                id = parts{2};
                if isnumeric(id), id = num2str(id); end
                return
            end
        end
    end
 
    % look for ID in log
    file_log = findFilename('tempData', path_ses);
    if ~isempty(file_log)
        if iscell(file_log), file_log = file_log{1}; end
        try
            tmp_log = load(file_log);
        catch ERR
            success = false;
            return
        end
        if isfield(tmp_log, 'tempData')
            possHead = cellfun(@(x) find(strcmpi(x, 'ParticipantID')),...
                tmp_log.tempData.Headings, 'uniform', false);
            hasIDField = find(~cellfun(@isempty, possHead), 1, 'first');
            try
                dta = ECKLogExtract(...
                    tmp_log.tempData, tmp_log.tempData.FunName{hasIDField},...
                    {'ParticipantID', 'CounterBalanceCondition'});
                if ~isempty(dta) && size(dta, 2) == 2
                    ids = dta(:, 1);
                    cbc = dta(:, 2);
                    dataExtracted = true;
                else
                    dataExtracted = false;
                end
            catch ERR
                dataExtracted = false;
            end
            if dataExtracted
                % check for counterbalance and ID mix-up (ADDS)
                cbMix = false;
                cbMix = cbMix || all(cellfun(@isnumeric, ids)) &&...
                    all(~cellfun(@isnumeric, cbc));
                cbMix = cbMix && all(cell2mat(ids) <= 2);
                if cbMix
                    ids = dta(:, 2);
                    cbc = dta(:, 1);
                end
                id = ids{1};
            end
        end
    end
    
    success = false;
            
end