function [smry, suc, oc] = etAlignLog2(dc, funName, var_onset, var_offset, var_sort, tol)

    % if sorting variable is not specified, use the onset as the sorting
    % variable
    if ~exist('var_sort', 'var') || isempty(var_sort)
        var_sort = var_onset;
    end
    
    % default tolerance of 100ms
    if ~exist('tol', 'var') || isempty(tol)
        tol = 0.100;
    end
    
    % validation table
    tab_val = table;

    % loop through DC data
    smry = {};
    suc = false(dc.NumData, 1);
    oc = cell(dc.NumData, 1);
    for d = 1:dc.NumData
        
        % attempt to process this dataset
        [suc(d), oc{d}, tmp_smry] = alignOneDataset(dc.Data{d}, funName,...
            var_onset, var_offset, var_sort, tol);
        
        if suc(d)
            smry = [smry; tmp_smry];
        end
        
    end
    
    smry = teLogExtract(smry);
    
end

function [suc, oc, smry] = alignOneDataset(data, funName, var_onset, var_offset, var_sort, tol)

    suc = false;
    oc = 'unknown error';
    smry = {};
    
    % check for valid log
    if ~ismember(funName, data.Log.FunName)
        suc = false;
        oc = sprintf('no log data: %s', funName);
        return
    end
    
    % extract on/offsets for each trial from the log
    [on, off, lg] = findLogValues(data, funName, var_onset, var_offset, var_sort);
    
    % iterate through all segments and find time buffers that are
    % encapsulated within log on/offsets
    numJobs = length(data.Segments);
    smry = {};
    for j = 1:numJobs
        smry = [smry; processOneJob(data, j, on, off, lg, tol)];
    end
    
    suc = true;
    oc = '';
    
end

function [on, off, lg] = findLogValues(data, funName, var_onset, var_offset, var_sort)

    % find log
    idx_log = strcmpi(data.Log.FunName, funName);
    if ~any(idx_log)
        error('Log %s not found.', funName)
    end
    
    % get log
    lg = ECKLog2Table(data.Log);
    
    % if more than one log returned, filter for just the required log name
    if iscell(lg) 
        lg = lg{idx_log};
    end
    
    % check on/offset vars are present in log
    varNames = lg.Properties.VariableNames;
    if ~ismember(var_onset, varNames)
        error('Onset variable %s not found in log.', var_onset)
    elseif ~ismember(var_offset, varNames)
        error('Offset variable %s not found in log.', var_offset)
    elseif ~ismember(var_sort, varNames)
       error('Sorting variable %s not found in log.', var_sort)
    end
    
    % attempt to sort
    lg = sortrows(lg, var_sort);
    
    % extract on/offsets
    on = lg.(var_onset);
    off = lg.(var_offset);
    
    % check data format of on/offsets
    if ~isnumeric(on)
        error('Values of onset log variable %s are not numeric.', var_onset)
    elseif ~isnumeric(off)
        error('Values of offset log variable %s are not numeric.', var_offset)
    end
    
    % convert to double if necessary
    if ~isa(on, 'double'), on = double(on); end
    if ~isa(off, 'double'), off = double(off); end
    
end

function smry = processOneJob(data, j, on, off, lg, tol)

    % convert tolerance to µSecs
    tol = tol * 1e6;
    
    numSegs = length(data.Segments(j).Segment);
    smry = cell(numSegs, 1);;
%     smry(numSegs).job = j;
    for s = 1:numSegs
        
        smry{s}.job = j;
        smry{s}.segment = s;
        smry{s}.success = false;
        smry{s}.log_row = nan;
        smry{s}.id = data.ParticipantID;
        smry{s}.wave = data.TimePoint;
        smry{s}.site = data.Site;

        tb = data.Segments(j).Segment(s).TimeBuffer;
        if isempty(tb)
            smry{s}.outcome = 'empty time buffer';
            continue
        end
        
        % get first and last timebuffer stamp
        tb1 = double(tb(1, 1));
        tb2 = double(tb(end, 1));
        
        % find log on/offsets that encapsulate this time buffer
        idx = abs(on - tb1) < tol & abs(off - tb2) < tol;
        
        % process too many or too few results
        if sum(idx) > 1
            smry{s}.outcome = 'more than one log entry matched time buffer';
            continue
        elseif ~any(idx)
            smry{s}.outcome = 'no log entries within tolerance';
            continue
        end
        
        % write log to segment
        data.Segments(j).Segment(s).Log = lg(idx, :);
        smry{s}.outcome = 'matched';
        smry{s}.success = true;
        smry{s}.log_row = find(idx);
        smry{s}.log_onset = on(idx);
        smry{s}.seg_onset = tb1;
        smry{s}.delta = (tb1 - on(idx)) / 1e6;
        
    end
    
end