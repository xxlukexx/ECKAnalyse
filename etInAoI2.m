function [res, in, missing] = etInAoI2(rect, mainBuffer, timeBuffer, varargin)

% parse inputs

    parser                  = inputParser;
    addParameter(           parser, 'fixationbuffer',           [],         @isnumeric      )
    addParameter(           parser, 'figure',                   [],         @ishandle       )
    addParameter(           parser, 'interpolateSecs',          [],         @isnumeric      )
    addParameter(           parser, 'triggerToleranceSecs',     [],         @isnumeric      )
    addParameter(           parser, 'triggerToleranceSamps',    [],         @isnumeric      )
    parse(                  parser, varargin{:})
    fb                      = parser.Results.fixationbuffer;
    fig                     = parser.Results.figure;
    interpS                 = parser.Results.interpolateSecs;
    trigTolS                = parser.Results.triggerToleranceSecs;
    trigTolSamps            = parser.Results.triggerToleranceSamps;
    
% general setup

    % check format of rect argument - must be a [n x 4] vector/matrix,
    % where n is the number of AOIs, and columns represent [x1, x2, y1, y2]
    if ~isnumeric(rect) || size(rect, 2) ~= 4
        error('''rect'' argument must be an [n x 4] vector or matrix, with a row for each AOI.')
    end
    
    % determine number of AOIs
    numAOIs = size(rect, 1);
    
    % shorten vars
    mb = mainBuffer;
    tb = timeBuffer;
    
    % get time vector
    t = etTimeBuffer2Secs(tb);  
    
    % calculate effective sample rate
    sr = etDetermineSampleRate(timeBuffer);
    
    % defaults
    res = struct(...
            'propValid', nan,...
            'propInAOI', nan,...
            'samplesInAOI', nan,...
            'timeInAOI', nan,...
            'firstTimestamp', inf,...
            'firstTimeSecs', inf,...
            'firstSamp', inf);
    res.fix = struct(...
            'samplesInAOI', nan,...
            'propInAOI', nan,...
            'timeInAOI', nan,...
            'fixationsInAOI', nan,...
            'fixationDurations', nan,...
            'meanFixationDuration', nan);
        
% results interpolation
    
    % flag to apply tolerance criterion
    doInterp = ~isempty(interpS);
    
% trigger tolerance

    % cannot specify trigger tolerance on samples and seconds
    % simulataneously
    if ~isempty(trigTolS) && ~isempty(trigTolSamps)
        error('Specify trigger tolerance either in seconds (triggerToleranceSecs) or samples (triggerToleranceSamps) - not both.')
    end
    
    % flag to apply tolerance criterion
    doTol = ~isempty(trigTolS) && ~isempty(trigTolSamps);
    
    % if trigger tolereance specified in seconds, convert to samples
    if ~isempty(trigTolS)
        sr = etDetermineSampleRate(timeBuffer);
        trigTolSamps = round(trigTolS * sr);
        fprintf('Trigger tolerance of %.3fs was converted to %d samples at calculated sampling rate of %.3fHz.\n',...
            trigTolS, trigTolSamps, sr);
    end
    
% fixation buffer
    
    % flag whether we have a fixation buffer
    hasFix = ~isempty(fb);
    
% preprocess raw data, extract x, y, for left/right/avg eyes. Record missing data

    % find valid data - defined as at least one eye detected (even if it 
    % can't reliably be identified as left or right)      
    val = mb(:, 13) ~= 4 | mb(:, 26) ~= 4;     
    
    % extract data
    [gx, gy, ~] = etAverageEyeBuffer(mb);                                   % average L+R eyes
    lgx = mb(:, 7);                                                         % left x
    lgy = mb(:, 8);                                                         % left y
    rgx = mb(:, 20);                                                        % right x
    rgy = mb(:, 21);                                                        % right y
    if all(isempty(gx)) || all(isempty(gy)), return, end                    % if no samples, give up

% score AOI(s)

    % find gaze samples inside the AOI. Samples from the left, right or the
    % averaged gaze position are counted if they are in the AOI
    in = nan(length(gx), numAOIs);
    
    for a = 1:numAOIs
        
        % get gaze samples within AOI
        in(:, a) = (...    
                gx >= rect(a, 1) &...                                            % average gaze 
                gx <= rect(a, 3) &...
                gy >= rect(a, 2) &...
                gy <= rect(a, 4)...
            ) |...
            (...
                lgx >= rect(a, 1) &...                                           % left eye
                lgx <= rect(a, 3) &...
                lgy >= rect(a, 2) &...
                lgy <= rect(a, 4)...
            ) |...
            (...
                rgx >= rect(a, 1) &...                                           % right eye
                rgx <= rect(a, 3) &...
                rgy >= rect(a, 2) &...
                rgy <= rect(a, 4)...
            );
    end
    
% interpolate

    if doInterp

        for a = 1:numAOIs

            % put inAOI data into a matrix
            in_aoi_cell = arrayfun(@(x) x.inAOI, res, 'uniform', false)';
            in_aoi_raw = horzcat(in_aoi_cell{:});

            % interp and store results, plus updated missing vector
            [in_aoi_interp, postInterpMissing] =...
                aoiInterp(in_aoi_raw, ~val, t, interpS);

            % loop through AOIs and update results structure with new inAOI
            % values
            for a = 1:numAOIs
                res(a).inAOI = in_aoi_interp(:, a);                                 % in AOI post-interp
                res(a).propValid = prop(~postInterpMissing);                        % prop valid post-interp    
                res(a).preInterpPropValid = prop(val);                              % prop valid pre-interp
            end

                % store post-interp validity vector for use later
                postProcVal = ~postInterpMissing;
                missing = postInterpMissing;
% 
%             else
% 
%                 res(a).propValid = prop(val);
%                 res(a).preInterpPropValid = nan;
%                 postProcVal(a, :) = val;
%                 missing = ~val;
% 
%             end    
            
        end
        
    end
        
        
        
        
        
        
    
        % trigger tolerance
        if ~isempty(trigTolSamps)

             % find contiguous runs of samples
            ct = findcontig2(res(a).inAOI);

            % find runs below trigger threshold
            idx_trig = ct(:, 3) < trigTolSamps;

            % remove runs ABOVE threshold (we only work with those
            % below)
            ct = ct(idx_trig, :);
            numTrig = sum(idx_trig);

            % convert below-threshold runs back to logical index
            for trig = 1:numTrig

                % find sample edges of look that is being deleted on
                % account of being below trigger threshold
                s1 = ct(trig, 1);
                s2 = ct(trig, 2);

                % delete look
                res(a).inAOI(s1:s2) = false;

            end

        end
        
 
        
        % fill in AOI metrics
        res(a).samplesInAOI             = sum(res(a).inAOI);                                      % total number of samples in AOI
        in(:, a)                     = res(a).inAOI;
        res(a).propInAOI                = res(a).samplesInAOI / sum(postProcVal(a, :));              % prop in AOI - note prop of all VALID samples
        sr                              = etDetermineSampleRate(tb);
        res(a).timeInAOI                = res(a).samplesInAOI / sr;
        res(a).firstSamp                = find(res(a).inAOI, 1, 'first');
        if isempty(res(a).firstSamp), res(a).firstSamp = inf; end
        if any(res(a).inAOI)
            res(a).firstTimestamp       = double(timeBuffer(res(a).firstSamp, 1));
            res(a).firstTimeSecs        = double(res(a).firstTimestamp -...
                                            timeBuffer(1, 1)) / 1e6;
        end        

    end
        
% %% calculate AOI metrics
% 
%     % loop through AOIs
%     for a = 1:numAOIs
%         
%         % fill in AOI metrics
%         res(a).samplesInAOI             = sum(res(a).inAOI);                                      % total number of samples in AOI
%         inAOI(:, a)                     = res(a).inAOI;
%         res(a).propInAOI                = res(a).samplesInAOI / sum(postProcVal);              % prop in AOI - note prop of all VALID samples
%         sr                              = etDetermineSampleRate(tb);
%         res(a).timeInAOI                = res(a).samplesInAOI / sr;
%         res(a).firstSamp                = find(res(a).inAOI, 1, 'first');
%         if isempty(res(a).firstSamp), res(a).firstSamp = inf; end
%         if any(res(a).inAOI)
%             res(a).firstTimestamp       = double(timeBuffer(res(a).firstSamp, 1));
%             res(a).firstTimeSecs        = double(res(a).firstTimestamp -...
%                                             timeBuffer(1, 1)) / 1e6;
%         end
%         
%     end
    
%     %% fixations
%     if hasFix
%         error('Not implemented.')
%         
%         % sample indices of fixations only
%         fVal = fb(:, 8) ~= 0;                                               % fix. no. is not 0
%         
%         % get fix x and y
%         fx = fb(:, 10);
%         fy = fb(:, 11);
%         
%         % replace non-fixation samples with nans
%         fx(~fVal) = nan;
%         fy(~fVal) = nan;
%         
%         % find fixations inside AOI
%         res.fix.inAOI = ...
%             fx >= rect(:, 1) &...                                            
%             fx <= rect(:, 3) &...
%             fy >= rect(:, 2) &...
%             fy <= rect(:, 4);
%         res.fix.samplesInAOI = sum(res.fix.inAOI);                          % total number of samples in AOI
%         res.fix.propInAOI = res.fix.samplesInAOI / sum(fVal);               % prop in AOI - note prop of all FIXATION samples
%         res.fix.timeInAOI = res.fix.samplesInAOI / sr;
%         
%         % indices of samples where a fixation in the AOI begins
%         fixNumInAOI = unique(fb(fVal & res.fix.inAOI, 8));
%         res.fix.fixationsInAOI = length(fixNumInAOI);
%         
%         % individual fixation durations
%         res.fix.fixationDurations =...
%             unique(fb(fVal & res.fix.inAOI, 9)) / 1e3;
%         res.fix.meanFixationDuration = mean(res.fix.fixationDurations);
%              
%     end
%     
%     %% plot
%     if exist('fig', 'var') && ~isempty(fig) && ishandle(fig)
%         error('Not implemented.')
%         hold on
%         set(gca, 'ydir', 'reverse')
%         xlim([0, 1])
%         ylim([0, 1])
%         rectangle('position', aoi2rect(rect));
%         scatter(gx(res.inAOI), gy(res.inAOI), 1);
%         if hasFix
%             scatter(fx(res.fix.inAOI), fy(res.fix.inAOI), 150);
%             str = sprintf('%.1f%% [%.1f%%]', res.propInAOI * 100,...
%                 res.fix.propInAOI * 100);
%         else
%             str = sprintf('%.1f%%', res.propInAOI * 100);
%         end
% 
% %         text(rect(1), rect(2) + .05, str, 'fontsize', 14, 'color', 'm');
%         
%     end
    
    
    
% end
    
