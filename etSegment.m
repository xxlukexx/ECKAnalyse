function [dcOut, summary, segList] = etSegment(data, cfg)

summary = {'Dataset', 'ParticipantID', 'Success', 'Num Segs', 'Outcome'};
dcOut = ECKDataContainer;

%% interrogate cfg file
if ~exist('cfg', 'var') || isempty(cfg)
    error('No cfg struct passed.')
end

% check data container
if ~exist('dataIn', 'var') &&...
    ~isa(data, 'ECKDataContainer') &&...
    ~isa(data, 'ECKData')

    error('Must pass either an ECKData or ECKDataContainer instance.')
end

dcIn = checkDataIn(data);
clear data

% check data types
if ~dcIn.MatchingTypes
    fprintf('Data container has multiple data types, filtering to just ET...\n')
    dcIn.FilterValue('TYPE', 'ET');
end

% check number of data files
% numData = length(dcIn.Data);
numData = dcIn.NumData;
if numData == 0
    error('No eye tracking data found in passed container.')
end

% check output options
if ~isfield(cfg, 'outputtype')
    % LEGACY = output to a new DC, with each dataset being a segment
    % INLINE = output to the 'segments' field of the existing DC
    % default to LEGACY to not break backward compatibility, but warn
    % because this may change in future
    cfg.outputtype = 'LEGACY';
%     warning('outputtype: currently defaulting to LEGACY, will stop working at some point in future.')
end

% if output type is inline, check for a label to name this particular
% segmentation job, otherwise make a default
if strcmpi(cfg.outputtype, 'INLINE')
    if ~isfield(cfg, 'joblabel') || isempty(cfg.joblabel)
        joblabel = 'UNNAMED_SEGMENTATION';
    else
        joblabel = cfg.joblabel;
    end
    if ~isfield(cfg, 'task') || isempty(cfg.task)
        task = joblabel;
    else
        task = cfg.task;
    end
end

 % segment label (if available)
if isfield(cfg, 'outputlabel') &&...
        ~isempty(cfg.outputlabel)
    outputLabel = cfg.outputlabel;
else
    outputLabel = 'Segment';
end

% translate ref frame. Sometimes this needs to be done on a task-by-task
% basis, and in that case the etSegment function offers this. 
if isfield(cfg, 'trf') && cfg.trf.transformRefFrame
    if isfield(cfg.trf, 'tasks')
        % store the list of tasks that ref frame translation should be
        % applied to
        refFrameTasks = cfg.trf.tasks;
        % check that the tasks are a cellstr
        if ~iscellstr(refFrameTasks)
            error('cfg.trf.tasks must be a cell array of strings.')
        end
        % check that the trf struct includes monitor/window size, and that
        % the values in these fields are two-element vectors of [width,
        % height]
        if ~isfield(cfg.trf, 'windowSize') || ~isfield(cfg.trf, 'monitorSize')
            error('cfg.trf must includes ''windowSize'' and ''monitorSize'' fields.')
        elseif ~isnumeric(cfg.trf.windowSize) || ~isvector(cfg.trf.windowSize) ||...
                ~isnumeric(cfg.trf.monitorSize) || ~isvector(cfg.trf.monitorSize) ||...
                length(cfg.trf.windowSize) ~= 2 || length(cfg.trf.monitorSize) ~= 2
            error('cfg.trf.windowSize and cfg.trf.monitorSize must be vectors in the form of [width, height].')
        end
        % check that output type is inline, as this is not supported in
        % legacy
        if ~strcmpi(cfg.outputtype, 'INLINE')
            error('Transforming reference frame is only currently supported for output type ''inline''.')
        end
    else
        error('A trf (transform reference frame) struct was found in cfg, but the ''tasks'' filed was not set.')
    end
else
    cfg.trf.transformRefFrame = false;
end
trf = cfg.trf;

% defaults
if ~isfield(cfg, 'takefirstonset') || isempty(cfg.takefirstonset)
    cfg.takefirstonset = false;
end
if ~isfield(cfg, 'takefirstoffset') || isempty(cfg.takefirstoffset)
    cfg.takefirstoffset = false;
end
if ~isfield(cfg, 'matchneighbours') || isempty(cfg.matchneighbours)
    cfg.matchneighbours = false;
end
if ~isfield(cfg, 'dumbloop') || isempty(cfg.dumbloop)
    cfg.dumbloop = false;
end

segList = [];

% check whether a status object was passed
statPresent = isfield(cfg, 'stat') && isa(cfg.stat, 'ECKStatus');
if statPresent, cfg.stat.Status = 'Starting up...'; end

%% segment

if isfield(cfg, 'type') 
    switch cfg.type
        
        case 'labelpairs'
            
            % check label args
            if ~isfield(cfg, 'onsetlabel') 
                error('Must supply a cfg.onsetlabel argument.')
            end
            
            if ~isfield(cfg, 'offsetlabel') 
                error('Must supply a cfg.offsetlabel argument.')
            end
            
            % check number of pairs (if more than one onsetlabel and
            % offsetlabel are specified, we essentially OR them in terms of
            % segmenting any of the labels in the array
            if ischar(cfg.onsetlabel) && ischar(cfg.offsetlabel)
                cfg.onsetlabel = {cfg.onsetlabel};
                cfg.offsetlabel = {cfg.offsetlabel};
            end
            
            if length(cfg.onsetlabel) ~= length(cfg.offsetlabel)
                error('onsetlabel and offsetlabel must be the same size.')
            end
            numPairs = length(cfg.onsetlabel);
                        
            % check whether an exact match has been specified
            if ~isfield(cfg, 'onsetlabelexactmatch')
                cfg.onsetlabelexactmatch = false;
            end

            if ~isfield(cfg, 'offsetlabelexactmatch')
                cfg.offsetlabelexactmatch = false;
            end
            
            % var to store segment onset timestamps so that multiple label
            % pairs can be sorted in time order once processed
            pairOnsets = [];
            
            for p = 1:numPairs
                
                % convert any numeric fields to string
                if isnumeric(cfg.onsetlabel{p})
                    cfg.onsetlabel{p} = num2str(cfg.onsetlabel{p});
                end

                if isnumeric(cfg.offsetlabel{p})
                    cfg.offsetlabel{p} = num2str(cfg.offsetlabel{p});
                end

                % check data type of labels
                if ~iscell(cfg.onsetlabel{p}) && ~ischar(cfg.onsetlabel{p})
                    error('onsetlabel must be either cell or string.')
                end

                if ~iscell(cfg.offsetlabel{p}) && ~ischar(cfg.offsetlabel{p})
                    error('offsetlabel must be either cell or string.')
                end
            
                % loop through and segment
                for d = 1:numData
                    
                    % check for empty event buffer
                    if isempty(dcIn.Data{d}.EventBuffer)
                        error('Empty event buffer.')
                    end
                    
                    % sort event buffer by remote time - fixes issue where
                    % local time and remote time do not match after
                    % combining split sessions (local time can reset due to
                    % computer clock being reset to 0, remote time cannot,
                    % so we should use remote time to determine the order
                    % of events)
                    [~, so] = sort(cell2mat(dcIn.Data{d}.EventBuffer(:, 2)));
                    dcIn.Data{d}.EventBuffer = dcIn.Data{d}.EventBuffer(so, :);

                    if dcIn.Data{d}.Cached
                        dcIn.Data{d}.Cached = false;
                        reCache = true;
                    else
                        reCache = false;
                    end

                    if statPresent
                        cfg.stat.Status = sprintf(...
                            'etSegment: Dataset %d of %d (%.1f%%)\n',...
                            d, numData, (d / numData) * 100);
                    end

                    success = true;
                    outcome = '';
                    numSegs = 0;

                    evOnset = etFilterEvents(dcIn.Data{d}.EventBuffer,...
                        cfg.onsetlabel{p}, cfg.onsetlabelexactmatch);
                    evOffset = etFilterEvents(dcIn.Data{d}.EventBuffer,...
                        cfg.offsetlabel{p}, cfg.offsetlabelexactmatch); 

                    % check some labels were returned
                    if isempty(evOnset) && isempty(evOffset)
                        success = false;
                        outcome = 'No onset or offset labels found.';
                    elseif isempty(evOnset)
                        success = false;
                        outcome = 'No onset labels found.';
                    elseif isempty(evOffset)
                        success = false;
                        outcome = 'No offset labels found.';
                    end

                    % check labels can be paired
                    canPair = true;
                    if success && size(evOnset, 1) ~= size(evOffset, 1)

                        canPair = false; 
                        
                        if cfg.dumbloop 
                            % dumb loop finds onsets, then loops, starting
                            % at each onset, until it finds an offset. 
                            s = 1;
                            sOn = [];
                            sOff = [];
                            counter = 1;
                            eb = dcIn.Data{d}.EventBuffer;
                            foundOnset = false;
                            foundOffset = false;
                            evOffset = {};
                            evOffset = {};
                            maskOn = regexptranslate('wildcard', cfg.onsetlabel);
                            maskOff = regexptranslate('wildcard', cfg.offsetlabel);
                            while s < size(eb, 1)
                                if ~foundOnset
                                    % look for onset
%                                     ev_str = strrep(cell2char(eb{s, 3}, '#'), '#', ' ');
                                    ev_str = cell2char(eb{s, 3}, ' ');
                                    res = regexp(ev_str, maskOn);
                                    foundOnset = ~isempty(res{1}) && res{1} == 1;
                                    if foundOnset, sOn = s; end
                                    s = s + 1;
                                elseif foundOnset && ~foundOffset
                                    % look for offset
                                    ev_str = cell2char(eb{s, 3}, ' ');
                                    res = regexp(cell2char(ev_str, ' '), maskOff);
                                    foundOffset = ~isempty(res{1}) && res{1} == 1;
                                    if foundOffset, sOff = s; end
                                    s = s + 1;
                                elseif foundOnset && foundOffset
                                    evOnset(counter, 1:3) = eb(sOn, 1:3);
                                    evOffset(counter, 1:3) = eb(sOff, 1:3);
                                    counter = counter + 1;
                                    sOn = [];
                                    sOff = [];
                                    foundOnset = false;
                                    foundOffset = false;
                                end
                            end
                            canPair = isequal(size(evOnset), size(evOffset));
                        end
                           
                        if ~canPair && isfield(cfg, 'takefirstoffset') &&...
                                cfg.takefirstoffset &&...
                                size(evOffset, 1) > size(evOnset, 1)
                            % if takeFirstOffset flag is set, take the first of the
                            % multiple offset events that were returned. If not,
                            % mark as error and move on
                        
                            sampOffset = [];
                            for on = 1:size(evOnset, 1)

                                % get onset time 
                                timeOnset = evOnset{on, 2};

                                % get all possible offset times
                                offsetTimes = cell2mat(evOffset(:, 2));

                                % find first offset event that occurred AFTER the
                                % timestamp of the onset event
                                found = find(offsetTimes > timeOnset, 1, 'first');

                                % if no offset found, delete the onset
                                if ~isempty(found)
                                    sampOffset = [sampOffset; found];
                                else
                                    evOnset(on, :) = [];
                                end
                            end

                            if isempty(sampOffset)
                                success = false;
                                outcome = 'No offset event could be paired to the onset event.';
                            else
                                evOffset = evOffset(sampOffset, :);
                                canPair = true;
                            end
                            
                        end

                        if ~canPair &&  isfield(cfg, 'takefirstonset') &&...
                                cfg.takefirstonset &&...
                                size(evOnset, 1) > size(evOffset, 1)
                            % if takeFirstOnset flag is set, take the first of the
                            % multiple onset events that were returned. If not,
                            % mark as error and move on                            

                            % get onset time 
                            timeOffset = evOffset{1, 2};

                            % get all possible offset times
                            onsetTimes = cell2mat(evOnset(:, 2));

                            % find first offset event that occurred AFTER the
                            % timestamp of the onset event
                            sampOnset = find(onsetTimes < timeOffset);
                            if isempty(sampOnset)
                                success = false;
                                outcome = 'No offset event could be paired to the onset event.';
                            else
                                evOnset = evOnset(sampOnset, :);
                                canPair = true;
                            end
                            
                        end
                        
                        if ~canPair && isfield(cfg, 'droporphanedonsets') &&...
                                cfg.droporphanedonsets &&...
                                size(evOnset, 1) > size(evOffset, 1)
                            % if more onsets than offsets were returned (e.g.
                            % if a sesson ended during the middle of a trial,
                            % so we got an onset event but not it's matching
                            % offset event), and if the dropOrphanedOnsets flag
                            % is true, remove the final onset (essentially
                            % dropping the final truncated trial)                            
                            
                            evOnset = evOnset(1:size(evOffset, 1), :);
                            canPair = true;
                            
                        end
                                                    
                        if ~canPair && ~isequal(size(evOnset), size(evOffset)) &&...
                                cfg.matchneighbours 
                            % if the number of onset and offset events doesn't
                            % match, and the 'matchNeighbours' flag is set,
                            % then match each onset to it's nearest temporal
                            % neighbour. Any orphaned on/offsets that didn't
                            % get a neighbour are dropped
                        
                            % only validated for numOnset > numOffset
                            if size(evOnset, 1) < size(evOffset, 1)
                                warning('Not validated - check & debug!')
                            end
                            % mark events as onset (1) or offset(2),
                            % combine into one list
                            numOn       = size(evOnset, 1);
                            numOff      = size(evOffset, 1);
                            ev_on       = [evOnset, num2cell(ones(numOn, 1))];
                            ev_off      = [evOffset, num2cell(repmat(2, numOff, 1))];
                            ev          = [ev_on; ev_off];
                            % sort by remote time
                            [~, so]     = sort(cell2mat(ev(:, 2)));
                            ev          = ev(so, :);
                            % loop through and find on/offset pairs
                            evOnset = {};
                            evOffset = {};
                            counter = 1;
                            for i = 1:size(ev, 1) - 1
                                if ev{i, end} == 1 && ev{i + 1, end} == 2
                                    evOnset(counter, 1:3) = ev(i, 1:3);
                                    evOffset(counter, 1:3) = ev(i + 1, 1:3);
                                    counter = counter + 1;
                                end
                            end
                            canPair = ~isempty(evOnset) && ~isempty(evOffset) &&...
                                isequal(size(evOnset), size(evOffset));
                        end
                        
                    end
                        
                    if ~canPair

                        success = false;
                            outcome =...
                                'Unequal number of onset/offset labels, cannot be paired.';

                    elseif success && canPair

                        % segment
                        numSegs = size(evOnset, 1);
                        for seg = 1:numSegs

                            % get on/offset times
                            timeOnset = evOnset{seg, 2};
                            timeOffset = evOffset{seg, 2};
                            segList(seg, :) = [timeOnset, timeOffset];
                            
                            % additional data (from onset event)
                            addData = evOnset{seg, 3};
                            if ~iscell(addData), addData = {addData}; end

                            % append segment number to output label
                            numberedOutputLabel = [outputLabel, '_',...
                                LeadingString('0000', seg)];
                            
                            % store onset time for later sorting
                            pairOnsets(end + 1) = timeOnset;
                                
                            % fill in data
                            switch cfg.outputtype
                                case {'LEGACY', 'Legacy', 'legacy'}
                                    dcOut = dcSegmentLegacy(dcIn.Data{d}, dcOut,...
                                        timeOnset, timeOffset, numberedOutputLabel);
                                case {'INLINE', 'Inline', 'InLine', 'inline'}
                                    dcIn = dcSegmentInline(dcIn, d, timeOnset,...
                                        timeOffset, addData, numberedOutputLabel,...
                                        joblabel, task, trf);
                            end

                        end

                    end

                    % update summary
                    summary = [summary;...
                        {d,...
                        dcIn.Data{d}.ParticipantID,...
                        success,...
                        numSegs,...
                        outcome}];

                    if reCache
                        dcIn.Data{d}.Cached = true;
                        reCache = false;
                    end

                end
                
            end
            
            % sort segments by timestamp
            if ~isempty(pairOnsets)
                [~, idx] = sort(pairOnsets);
                dcOut = ECKDuplicateDC(dcOut, idx);
            else
%                 warning('pairOnsets is empty!')
            end
                
            if strcmpi(cfg.outputtype, 'INLINE'), dcOut = dcIn; end
            
        case 'timepairs'
                        
            % check label args
            if ~isfield(cfg, 'onsettime') 
                error('Must supply a cfg.onsettime argument.')
            end
            
            if ~isfield(cfg, 'offsettime') 
                error('Must supply a cfg.offsettime argument.')
            end
            
            % check data type of times
            if ~isa(cfg.onsettime, 'uint64')
                if ~isnumeric(cfg.onsettime)
                    error('Onset time(s) must be numeric.')
                else
                    if cfg.onsettime < 0
                        error('Onset time(s) must be positive.')
                    end
                    cfg.onsettime = uint64(cfg.onsettime);
                end
            end
            
            if ~isa(cfg.offsettime, 'uint64')
                if ~isnumeric(cfg.offsettime)
                    error('Offset time(s) must be numeric.')
                else
                    if cfg.offsettime < 0
                        error('Offset time(s) must be positive.')
                    end
                    cfg.offsettime = uint64(cfg.offsettime);
                end
            end            
            
            % check that the same number of on/offset times have been
            % passed
            if ~isvector(cfg.onsettime) 
                error('Onset time(s) must be vectors.')
            end
            
            if ~isvector(cfg.offsettime) 
                error('Offset time(s) must be vectors.')
            end
            
            if length(cfg.onsettime) ~= length(cfg.offsettime)
                error('Must supply the same number of onset and offset times.')
            end
            
            % check that only one dataset has been passed
            if length(dcIn.Data) ~= 1
                error('Timepairs segmentation can only be run on single datasets.')
            end
            
            success = true;
            outcome = '';
            d = 1;
            
            % loop through timecode pairs and segment
            numTimePairs = length(cfg.onsettime);
            for tp = 1:numTimePairs
                
                % get times
                timeOnset = cfg.onsettime(tp);
                timeOffset = cfg.offsettime(tp);
                segList(tp, :) = [timeOnset, timeOffset];

                % segment
                switch upper(cfg.outputtype)
                    case 'LEGACY'
                        dcOut = dcSegmentLegacy(dcIn.Data{1}, dcOut,...
                            timeOnset, timeOffset);
                    case 'INLINE'
                        dcIn = dcSegmentInline(dcIn, d, timeOnset,...
                            timeOffset, [], outputLabel, joblabel, task, trf);
                end
                               
            end
            
            % update summary
            summary = [summary;...
                {1,...
                dcIn.Data{1}.ParticipantID,...
                success,...
                numTimePairs,...
                outcome}];
            
        case 'labelduration'
                       
             % check label args
            if ~isfield(cfg, 'onsetlabel') 
                error('Must supply a cfg.onsetlabel argument.')
            end
            
            if ~isfield(cfg, 'duration') 
                error('Must supply a cfg.duration argument.')
            end
            
            % convert any numeric fields to strin
            if isnumeric(cfg.onsetlabel)
                cfg.onsetlabel = num2str(cfg.onsetlabel);
            end
            
            % loop through and segment
            for d = 1:numData
                
                if dcIn.Data{d}.Cached
                    dcIn.Data{d}.Cached = false;
                    reCache = true;
                else
                    reCache = false;
                end
                    
                if statPresent
                    cfg.stat.Status = sprintf(...
                        '<strong>etSegment: </strong>Dataset %d of %d (%.1f%%)\n',...
                        d, numData, (d / numData) * 100);
                end
                    
                success = true;
                outcome = '';
                numSegs = 0;
                
                % filter for onset events
                evOnset = etFilterEvents(dcIn.Data{d}.EventBuffer,...
                    cfg.onsetlabel, cfg.onsetlabelexactmatch);
                
                % check some labels were returned
                if size(evOnset, 1) == 0
                    success = false;
                    outcome = 'No onset labels found.';
                end
                
                if success
                                       
                    % segment
                    numSegs = size(evOnset, 1);
                    for seg = 1:numSegs

                        % get on/offset times
                        timeOnset = evOnset{seg, 2};
                        timeOffset = timeOnset + (cfg.duration * 1000000);
                        segList(seg, :) = [timeOnset, timeOffset];
                        
                        % additional data (from onset event)
                        addData = evOnset{seg, 3};
                        if ~iscell(addData), addData = {addData}; end
                        
                        % append segment number to output label
                        numberedOutputLabel = [outputLabel, '_',...
                            LeadingString('0000', seg)];

                        % fill in data
                        switch cfg.outputtype
                            case {'LEGACY', 'Legacy', 'legacy'}
                                dcOut = dcSegmentLegacy(dcIn.Data{d}, dcOut,...
                                    timeOnset, timeOffset, numberedOutputLabel);
                            case {'INLINE', 'Inline', 'InLine', 'inline'}
                                dcIn = dcSegmentInline(dcIn, d, timeOnset,...
                                    timeOffset, addData, numberedOutputLabel,...
                                    joblabel, task, trf);
                        end
                        
                    end
                    
                end
                
                if reCache
                    dcIn.Data{d}.Cached = true;
                    reCache = false;
                end
                    
            end
                        
        case 'subsegment'
                        
            if ~isfield(cfg, 'duration') 
                error('Must supply a cfg.duration argument.')
            end
                        
            % loop through and segment
            segCounter = 1;
            for d = 1:numData
                
                if dcIn.Data{d}.Cached
                    dcIn.Data{d}.Cached = false;
                    reCache = true;
                else
                    reCache = false;
                end
                    
                if statPresent
                    cfg.stat.Status = sprintf(...
                        '<strong>etSegment: </strong>Dataset %d of %d (%.1f%%)\n',...
                        d, numData, (d / numData) * 100);
                end
                    
                success = true;
                outcome = '';
                numSegs = 0;
                
                % check for pause events, if found, truncate data at pause
                % onset
                pauseOn = find(strcmpi(dcIn.Data{d}.EventBuffer(:, 3),...
                    'PAUSE_ONSET'));
                if ~isempty(pauseOn)
                    pauseTime = dcIn.Data{d}.EventBuffer{pauseOn, 2};
                    s1 = 1; 
                    s2 = etTimeToSample(dcIn.Data{d}.TimeBuffer, pauseTime) - 1;
                else
                    s1 = 1;
                    s2 = size(dcIn.Data{d}.TimeBuffer, 1);
                end 
                
                % convert timebuffer to secs
                secs = double(dcIn.Data{d}.TimeBuffer(s1:s2, 1) -...
                    dcIn.Data{d}.TimeBuffer(1, 1)) / 1000000;
                
                % calculate number of x second segements
%                 numSegs = floor(max(secs) / cfg.duration) - 1;
                numSegs = floor(max(secs) / cfg.duration);
                durUs = uint64(cfg.duration * 1000000);

                % segment
                for seg = 1:numSegs

                    % get on/offset times
                    timeOnset = dcIn.Data{d}.TimeBuffer(1, 1) +...
                        uint64((seg - 1)) * durUs;
                    timeOffset = timeOnset + durUs;
                    segList(segCounter, :) = [timeOnset, timeOffset];
                    segCounter = segCounter + 1;
                                        
                    % additional data (from onset event)
                    addData = [dcIn.Data{d}.EventBuffer{1, 3},...
                        LeadingString('0000', d)];
                    if ~iscell(addData), addData = {addData}; end
                    
                    % store parent event, and parent trial number
                    % (equivalent to dataset number in DC) in output label
                    numberedOutputLabel = addData;

                    % fill in data
                    switch cfg.outputtype
                        case {'LEGACY', 'Legacy', 'legacy'}
                            dcOut = dcSegmentLegacy(dcIn.Data{d}, dcOut,...
                                timeOnset, timeOffset, numberedOutputLabel);
                        case {'INLINE', 'Inline', 'InLine', 'inline'}
                            dcIn = dcSegmentInline(dcIn, d, timeOnset,...
                                timeOffset, addData, numberedOutputLabel,...
                                joblabel, task, trf);
                    end

                end
                
                if reCache
                    dcIn.Data{d}.Cached = true;
                    reCache = false;
                end
                    
            end
            
    end
        
end

% close(wb)

end

function dcOut = dcSegmentLegacy(dataIn, dcOut, timeOnset, timeOffset, label)

    % if no label has been supplied, used a default "SEGMENT" label
    if ~exist('label', 'var') || isempty(label)
        label = 'SEGMENT';
    end

    comment = 'Success';

    % extract metadata
    tmpData = ECKData;
    tmpData.Type = 'ET';
    tmpData.ParticipantID = dataIn.ParticipantID;
    tmpData.TimePoint = dataIn.TimePoint;
    tmpData.Battery = dataIn.Battery;
    tmpData.CounterBalance = dataIn.CounterBalance;
    tmpData.Site = dataIn.Site;
    
    % segment main, time and eventbuffers by on/offset times
    [mb, tb, eb, s1, s2] = etGetGazeByTime(dataIn.MainBuffer,...
        dataIn.TimeBuffer, dataIn.EventBuffer,...
        timeOnset, timeOffset);
    
    % if a fixation buffer is present, also segment this
    if isprop(dataIn, 'FixationBuffer') && ~isempty(dataIn.FixationBuffer)
        fb = dataIn.FixationBuffer(s1:s2, :);
    else
        fb = {[]};
    end
    
    % store in output ECKData object
    tmpData.MainBuffer = mb{:};
    tmpData.TimeBuffer = tb{:};
    tmpData.EventBuffer = eb{:};
    tmpData.FixationBuffer = fb{:};
    
    % store output label
    if iscellstr(label), label = cell2char(label); end
    tmpData.ExtraData.SegmentLabel = label;
    
    % check data
    if size(tmpData.TimeBuffer, 1) == 1
        
        if etDetectJumpBuffer(dataIn.TimeBuffer)
            comment = 'Jump detected in raw time data.';
        else
            comment = 'Segmentation failed to yield data (size = 1), unknown reason.';
        end
        
    end
    
    if isempty(tmpData.TimeBuffer)
        comment = 'Segmentation failed to yield data (empty), unknown reason.';
    end

    % store
    datasetIdx = dcOut.AddData(tmpData);
    
    % calculate and write summary info
    if ~isfield(dcOut.ExtraData', 'SegmentSummary')
        dcOut.ExtraData.SegmentSummary = {...
            'Data', 'Seg Label', 'ID', 'Timepoint', 'Duration (s)', 'Prop valid', 'Comment'};
    end
    
    dcOut.ExtraData.SegmentSummary = [dcOut.ExtraData.SegmentSummary;...
        {...
        datasetIdx,...
        label,...
        tmpData.ParticipantID,...
        tmpData.TimePoint,...
        double(tmpData.TimeBuffer(end, 1) - tmpData.TimeBuffer(1, 1)) / 1000000,...
        etPropValBuffer(tmpData.MainBuffer),...
        comment,...
        }...
        ];
    
end

function dc = dcSegmentInline(dc, d, timeOnset, timeOffset, addData, label,...
    jobLabel, task, trf)
       
    % get segmented data
    [mb, tb, eb, s1, s2] = etGetGazeByTime(dc.Data{d}.MainBuffer,...
        dc.Data{d}.TimeBuffer, dc.Data{d}.EventBuffer,...
        timeOnset, timeOffset);
    
    % if a fixation buffer is present, also segment this
    if isprop(dc.Data{d}, 'FixationBuffer') &&...
            ~isempty(dc.Data{d}.FixationBuffer)
        fb = arrayfun(@(x, y) dc.Data{d}.FixationBuffer(x:y, :),...
            s1, s2, 'uniform', false);
    else
        fb = {[]};
    end
    
    % optionally transform ref frame
    if trf.transformRefFrame && isfield(trf, 'perTask') && trf.perTask &&...
            ismember(task, trf.tasks)
        for d = 1:length(mb)
            mb{d} = etScaleBySize(mb{d}, trf.monitorSize, trf.windowSize);
        end
        fprintf('REF FRAME %s\n', task);
    end
    
    % look for existing segmentation job in dc
    jobFound = false;
    jobIdx = nan;
    if isfield(dc.Data{d}.Segments, 'JobLabel')
        % search for job label
        jobs = {dc.Data{d}.Segments.JobLabel};
        jobIdx = find(strcmpi(jobs, jobLabel));
        jobFound = ~isempty(jobIdx);
        if ~jobFound
            dc.Data{d}.Segments(end + 1).JobLabel = jobLabel;
            jobIdx = length(dc.Data{d}.Segments);
        end
    else
        dc.Data{d}.Segments.JobLabel = jobLabel;
        jobIdx = 1;
    end
       
    % get index for storing segment
    if ~isfield(dc.Data{d}.Segments(jobIdx), 'Segment') ||...
            isempty(dc.Data{d}.Segments(jobIdx).Segment)
        dc.Data{d}.Segments(jobIdx).Segment = struct;
        segIdx = 1;
    else
        segIdx = length(dc.Data{d}.Segments(jobIdx).Segment) + 1;
    end
    
    % store task
    dc.Data{d}.Segments(jobIdx).Task = task;
    
    % store
    dc.Data{d}.Segments(jobIdx).Segment(segIdx).MainBuffer = mb{:};
    dc.Data{d}.Segments(jobIdx).Segment(segIdx).TimeBuffer = tb{:};
    dc.Data{d}.Segments(jobIdx).Segment(segIdx).EventBuffer = eb{:};
    dc.Data{d}.Segments(jobIdx).Segment(segIdx).FixationBuffer = fb{:};

    % if available, also store additional data (e.g. experimental vars) 
    if exist('addData', 'var') && ~isempty(addData)
        dc.Data{d}.Segments(jobIdx).Segment(segIdx).AddData = addData;
    end
    
    % if available, label the segment 
    if exist('label', 'var') && ~isempty(label)
        dc.Data{d}.Segments(jobIdx).Segment(segIdx).Label = label;
    end
    
end