function [found, onset, offset] = ECKTimestampsFromLog(data, task)

    labs = {...
        'falsebelief_trial',    'TrialOnsetRemote',             'TrialOffsetRemote';...
        'asahi_trial',          'BaselineOnsetTimeRemote',      'StimImageOffsetTimeRemote';...
        'reflex_trial',         'MovieOnsetETRemoteTime',       6;...
        'scenes_trial',         'MovieOnsetETRemoteTime',       21;...
        'staticimages_trial',   'StimImageOnsetTimeRemote',     'StimImageOffsetTimeRemote';...
        'contingency_trial',    'TrialOnsetRemote',             'MovieOffsetRemote';...
        'emotion_trial',        'TrialOnsetTimeRemote',         'TrialOffsetTimeRemote';...
        'frequency_trial',      'TrialOnsetTimeRemote',         'TrialOffsetTimeRemote';...
        'kanisza_trial',        'TrialOnsetTimeRemote',         'TrialOffsetTimeRemote';...
        'ns_contingency_trial', 'TrialOnsetTimeRemote',         'RewardOffsetRemote';...
        'wm_trial',             'TrialOnsetRemote',             'CurtainChosenDownRemote';...
        'cog_control_trial',    'TrialOnsetRemote',             'MovieOffsetRemote';...
        'ms_trial',             'TrialOffsetTime',              'TrialOffsetRemote';...
        'soc_contingency_trial','TrialOffsetTime',              'TrialOffsetRemote';...
        'gap_trial',            'TrialOnsetRemoteTime',         'TrialOffsetRemoteTime';...
        'gap4_trial',            'TrialOnsetRemoteTime',         'TrialOffsetRemoteTime'};
            
    found = false;
    onset = []; offset = [];
    
    dc = checkDataIn(data);
    
    % check that we have on/offset labels for this task
    taskIdx = find(strcmpi(labs(:, 1), task), 1);
    if isempty(taskIdx)
        warning('On/offset labels have not been defined for this task.')
        return
    end
    
    % get on/offset labels
    labOn = labs{taskIdx, 2};
    labOff = labs{taskIdx, 3};
    
    % collate log data 
    [hdr, dta] = etCollateTask(dc, task);
    if isempty(hdr) || isempty(dta)
        warning('No log data found for this task.')
        return
    end
    
    % get on/offset columns
    if ischar(labOn)
        colOn = find(strcmpi(hdr, labOn));
        dtaOn = standardiseData(dta(:, colOn));
        onset = cell2mat(dtaOn);
        if isempty(colOn)
            warning('Onset column not found in log.')
            return
        end
    end
    
    if ischar(labOff)
        colOff = find(strcmpi(hdr, labOff));
        dtaOff = standardiseData(dta(:, colOff));
        offset = cell2mat(dtaOff);
        if ischar(offset), offset = str2num(offset); end
        if isempty(colOff)
            warning('Offset column not found in log.')
            return
        end
    else
        offset = onset + (labOff * 1000000);
    end  
    
    found = true;
     
end

function data = standardiseData(data)

    % if whole column is char, convert to number
    if ischar(data), data = str2num(data); end
    
    % index each possible data type, convert all to int64
    dblIdx = cellfun(@(x) isa(x, 'double'), data);
    if any(dblIdx)
        data(dblIdx) = cellfun(@(x) num2cell(int64(x)), data(dblIdx));
    end
    
    charIdx = cellfun(@ischar, data);
    if any(charIdx)
        data(charIdx) =...
            cellfun(@(x) int64(str2num(x)), data(charIdx), 'uniform', 0);
    end    
    
    emptyIdx = cellfun(@isempty, data);
    if any(emptyIdx)
        data(emptyIdx) = num2cell(zeros(sum(emptyIdx), 1, 'int64'));
    end    
    
end