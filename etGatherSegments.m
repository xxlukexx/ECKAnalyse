function [seg, numIDs] = etGatherSegments(data, cfg)

    % etGatherSegments
    %
    % Jul 2016 LM
    %
    % gather eye tracking data across subjects and segments. params set
    % with a cfg struct:
    %
    % cfg.segmentmode = 'SESSION' | ['SEGMENT']
    % Gather data across a session of continuous data, or across multiple
    % segments. SESSION mode not yet implemented. 
    %
    % cfg.outputmode = 'STRUCTARRAY' | ['CELLARRAY']
    % Determines how gathered segments are presented in the output
    % variabkle. CELL array (default) will produce a struct, with each
    % field being a cell array (e.g. ID, TimePoint etc.). STRUCTARRAY makes
    % a struct array, with one element per segment and single fields on
    % each element of the array.
    %
    % cfg.segmentGroupingMode = 'LABEL' | ['ADDDATA']
    % Segments may be referred to by label (e.g. 'Segment_0001') or by the
    % ADDDATA (additional data) field (usually the onset event of a
    % segmentation job). By default, data is gathered over participants,
    % and over ADDDATA, but this can be set to LABEL if you prefer. 

    
    % check data, convert to DC if necessary
    dc = checkDataIn(data);
    
    % check that a cfg struct has been passed. This contains all
    % configuration parameters
    if ~exist('cfg', 'var') || ~isstruct(cfg)
        cfg = struct;
%         error('Must supply cfg struct.')
    end
    
    % make all struct fields lowercase
    cfg = structFieldsToLowercase(cfg);
    
    % check params
    if ~isfield(cfg, 'segmentmode') || isempty(cfg.segmentmode)
        cfg.segmentmode = 'SEGMENT';
    end
    
    % output mode
    if ~isfield(cfg, 'outputmode') || isempty(cfg.outputmode)
        cfg.outputmode = 'CELLARRAY'; 
    end
    
    % check SementMode (n.b. session mode not implemented)
    if strcmpi(cfg.segmentmode, 'SESSION')
        error('SESSION segmentmode not yet implemented.')
    elseif ~strcmpi(cfg.segmentmode, 'SEGMENT')
        error('segmentmode of %s is not supported.', cfg.segmentmode)
    end
    
    % check flags to filter gaze offscreen and average eyes
    if ~isfield(cfg, 'filtergazeonscreen')
        cfg.filtergazeonscreen = false;
    end
    
    if ~isfield(cfg, 'averageeyes')
        cfg.averageeyes = false;
    end
    
    % check resampling option params
    if ~isfield(cfg, 'resample')
        cfg.resample = false;
    else
        if ~isfield(cfg, 'resamplefs')
            error('If cfg.resample is true, must supply cfg.resamplefs to specify target sampling rate.')
        end
    end
    
    % create empty output variable
    seg.cfg = cfg;
    seg.numIDs = 0;
    seg.ids = {};
    seg.timePoints = {};
    seg.batteries = {};
    seg.counterBalance = [];
    seg.site = {};
    seg.jobLabels = {};
    seg.labels = {};
    seg.addData = {};
    seg.duration = [];
    seg.fs = [];
    seg.mainBuffer = {};
    seg.timeBuffer = {};
    seg.eventBuffer = {};
    seg.lostProp = [];
    seg.firstTimeStamp = [];
    idx = 0;
    
    switch cfg.segmentmode
        
        case 'SEGMENT'
                       
            % loop through subjects
            for d = 1:dc.NumData
                
                % update ECKStatus if one has been passed
                if isfield(cfg, 'stat')
                    cfg.stat.Status =...
                        sprintf('Gathering segments %.1f%% (%d found)...\n',...
                        (d / dc.NumData) * 100, idx);
                end
                                
                % get ID
                id = dc.Data{d}.ParticipantID;
                timepoint = dc.Data{d}.TimePoint;
                battery = dc.Data{d}.Battery;
                counterBalance = dc.Data{d}.CounterBalance;
                site = dc.Data{d}.Site;
                                        
                % loop through segmentation jobs
                numJobs = length(dc.Data{d}.Segments);
                fprintf('%d\t%s\t%d\n', d, id, numJobs);
                for j = 1:numJobs
                    
                    numSegs = length(dc.Data{d}.Segments.Segment);
                    
                    % get job label
                    jobLabel = dc.Data{d}.Segments.JobLabel;
                    
                    % get eye tracker timestamps of first sample of each
                    % segment, to allow for sorting out-of-order data
                    onset = nan(numSegs, 1);
                    for s = 1:numSegs
                        tb = dc.Data{d}.Segments(j).Segment(s).TimeBuffer;
                        if ~isempty(tb)
                            onset(s) = tb(1, 1);
                        end
                    end

                    % find sort order
                    [~, so] = sort(onset);                    
                    
                    % loop through segments within a job
%                     fprintf('%d\t%s\t%d\n', d, id, numSegs);
                    for i = 1:numSegs

                        s = so(i);
                    
                        idx = idx + 1;
                    
                        % get label
                        label = dc.Data{d}.Segments(j).Segment(s).Label;
                        
                        % attempt to convert cell array adddata to string.
                        % Only works if all elements of the array are
                        % string, if this is not the case then catch this
                        % error and fill the adddata field with a comment
                        % noting that this was not possible
                        addDataCell =...
                            dc.Data{d}.Segments(j).Segment(s).AddData;
                        if iscell(addDataCell)
                            try
                                addDataStr = cell2mat(addDataCell);
                            catch ERR
                                if strcmpi(ERR.identifier,...
                                        'MATLAB:cell2mat:MixedDataTypes')
                                    % attempt to summarise adddata by
                                    % converting the lot to a string
                                    try
                                        addDataStr = cell2char(addDataCell);
                                    catch ERR2
                                        addDataStr =...
                                            'Could not extract text summary.';
                                    end
                                end
                            end
                        elseif ischar(addDataCell)
                            addDataStr = addDataCell;
                        else
                            addDataStr = 'Could not read AddData field, not cell or char';
                        end
                        
                        % get buffers
                        mb = dc.Data{d}.Segments(j).Segment(s)...
                            .MainBuffer;
                        tb = dc.Data{d}.Segments(j).Segment(s)...
                            .TimeBuffer;
                        eb = dc.Data{d}.Segments(j).Segment(s)...
                            .EventBuffer;       
                        
                        % calculate sample rate
                        seg.fs(idx) = etDetermineSampleRate(tb);
                        
                        % calculate duration
                        if ~isempty(tb)
                            seg.duration(idx) =...
                                (double(tb(end, 1) - tb(1, 1))) / 1000000;
                        else
                            seg.duration(idx) = nan;
                        end
                        % filter gaze on screen (if requested)
                        if cfg.filtergazeonscreen
                            mb = etFilterGazeOnscreen(mb);
                        end
                        
                        % average eyes (if requested)
                        if cfg.averageeyes
                            mb = etAverageEyeBuffer(mb);
                        end
                        
                        % calculate missing data
                        miss = isnan(mb(:, 7)) & isnan(mb(:, 20));
                                                
                        % resample (if requested)
                        if cfg.resample
                            
                            warning('Resampling in etGatherSegments uses an old version of etResample, consider resampling separately using etResample2')
                            
%                             % TEMP: shorten mb, tb
%                             mb = mb(1:300, :); tb = tb(1:300, :);
                            
                            % resample to regular intervals, at requested
                            % sample rate
                            [mb, tb] = etResample(mb, tb, cfg.resamplefs);
                            
                        end
                        
                        % figure out first timestamp
                        if ~isempty(tb)
                            seg.firstTimeStamp(idx) = tb(1, 1);
                        else
                            seg.firstTimeStamp(idx) = nan;
                        end
                        
                        % write to output struct
                        seg.ids{idx} = id;
                        seg.timePoints{idx} = timepoint;
                        seg.batteries{idx} = battery;
                        seg.counterBalance{idx} = counterBalance;
                        seg.site{idx} = site;
                        seg.jobLabels{idx} = jobLabel;
                        seg.labels{idx} = label;
                        seg.addData{idx} = addDataStr;
                        seg.mainBuffer{idx} = mb;
                        seg.timeBuffer{idx} = tb;
                        seg.eventBuffer{idx} = eb;
                        seg.lostProp(idx) = sum(miss) / length(miss);
                        if isfield(dc.Data{d}.Segments(j).Segment(s), 'Log')
                            seg.log{idx} = dc.Data{d}.Segments(j).Segment(s).Log;
                        else
                            seg.log{idx} = [];
                        end

                    end
                    
                end
                
            end
            
            seg.numIDs = length(seg.ids);
                        
    end
    
    % if outputmode is STRUCTARRAY, convert from CELLARRAY format
    if strcmpi(cfg.outputmode, 'STRUCTARRAY')
        for d = 1:idx
            seg(d).id = seg.ids{d};
            seg(d).timePoint = seg.timePoints{d};
            seg(d).batterie = seg.batteries{d};
            seg(d).counterBalance = seg.counterBalance{d};
            seg(d).site = seg.site{d};
            seg(d).jobLabel = seg.jobLabels{d};
            seg(d).label = seg.labels{d};
            seg(d).addData = seg.addData{d};
            seg(d).mainBuffer = seg.mainBuffer{d};
            seg(d).timeBuffer = seg.timeBuffer{d};
            seg(d).eventBuffer = seg.eventBuffer{d};
            seg(d).lostProp = seg.lostProp(d);
            seg(d).duration = seg.duration(d);
            seg(d).fs = seg.fs(d);
        end
        numIDs = seg.numIDs;
        seg = seg;
    end

end