function [eventBuffer, ftCorr, rtCorr, outcome] = etFixFrameTimes(...
    eventBuffer, timeBuffer, onsetEvent, offsetEvent, frameLabel, inc)
     
    % if not specified assume frame increment in CALC events of 29
    if ~exist('inc', 'var') || isempty(inc)
        inc = 29;
    end
    
    ftCorr = nan; rtCorr = nan; outcome = 'Unkown error';
    
    % filter for just natscenes events
    eb = etFilterEvents(eventBuffer, frameLabel, true);
    eb = etSortEvents(eb);
    if isempty(eb)
        ftCorr = nan;
        rtCorr = nan;
        outcome = 'No frame time labels';
        return
    end
    
    % find number of trials
    ebOnsets = etFilterEvents(eventBuffer, onsetEvent, false);
    ebOffsets = etFilterEvents(eventBuffer, offsetEvent);
    numTrials = size(ebOnsets, 1);
    
    if numTrials == 0
        outcome = 'No trials found.';
        return
    end

    % loop through trials
    for tr = 1:numTrials
        
        % get trial on/offset times
        trialOnsetTime = ebOnsets{tr, 2};
        trialOffsetTime = ebOffsets{tr, 2};
        
        % convert times to samples
        trialOnsetSamp =...
            find(cell2mat(eb(:, 2)) > trialOnsetTime, 1, 'first');
        trialOffsetSamp =...
            find(cell2mat(eb(:, 2)) < trialOffsetTime, 1, 'last');
        
%         % get check data 
%         eb_check = etFilterEvents(eventBuffer, 'NATSCENES_FRAME_TEST_', true);
%         frames_check = cellfun(@(x) x, eb_check(:, 4));        
%         ft_check = cellfun(@(x) x{2}, eb_check(:, 3));
%         rt_check = double(cell2mat(eb_check(:, 2)));
        
        % find all frametime events between these times
        rt = double(cell2mat(eb(trialOnsetSamp:trialOffsetSamp, 2)));       % remote times
        lt = double(cell2mat(eb(trialOnsetSamp:trialOffsetSamp, 1)));       % local times
        ftCell = eb(trialOnsetSamp:trialOffsetSamp, 3);                     % frame time events
        ft = cellfun(@(x) x{2}, ftCell);                                    % frame times
        
        % remove invalid frame times (-1) 
        invFt = ft == -1;
        if any(invFt)
            ft(invFt) = [];
            rt(invFt) = [];
            lt(invFt) = [];
        end
        
        numFt = size(ft, 1);                                                % number of frames times                
        frames = (inc .* (1:numFt))';                                       % frame numbers

        if numFt > 1
            
            % get mean deltas
            rtmd = abs(mean(diff(rt))) / inc;
            ltmd = abs(mean(diff(lt))) / inc;
            framesmd = abs(mean(diff(frames))) / inc;
            ftmd = abs(mean(diff(ft))) / inc;

            rt_calc_known = rt(1);
            rt_calc_first = rt_calc_known - ((inc - 1) * rtmd);
            durUs = trialOffsetTime - rt_calc_first;
            durS = double(durUs) / 1e6;
            fps = round(1 / (rtmd / 1e6));
            numFrames = floor(durS * fps);
            rt_calc_last = rt_calc_first + ((numFrames - 1) * rtmd);
            rt_calc = zeros(numFrames, 1);
            rt_calc(1:numFrames) = rt_calc_first:rtmd:rt_calc_last;

            lt_calc_known = lt(1);
            lt_calc_first = lt_calc_known - ((inc - 1) * ltmd);
            lt_calc_last = lt_calc_first + ((numFrames - 1) * ltmd);
            lt_calc = zeros(numFrames, 1);
            lt_calc(1:numFrames) = lt_calc_first:ltmd:lt_calc_last;

            ft_calc_known = ft(1);
            ft_calc_first = ft_calc_known - ((inc - 1) * ftmd);
            ft_calc_last = ft_calc_first + ((numFrames - 1) * ftmd);
            ft_calc = zeros(numFrames, 1);
            ft_calc(1:numFrames) = ft_calc_first:ftmd:ft_calc_last;

            frames_calc_known = frames(1);
            frames_calc_first =...
                frames_calc_known - ((inc - 1) * framesmd);
            frames_calc_last = frames_calc_first + ((numFrames - 1) * framesmd);
            frames_calc = zeros(numFrames, 1);
            frames_calc(1:numFrames) = frames_calc_first:framesmd:frames_calc_last;
            steps_calc = (inc:inc:inc * length(ft))';
            if steps_calc(end) > length(ft_calc)
                steps_calc(end) = length(ft_calc);
            end
            ftCorr = corr(ft, ft_calc(steps_calc));
            rtCorr = corr(rt, rt_calc(steps_calc));
            ltCorr = corr(lt, lt_calc(steps_calc));
            framesCorr = corr(frames, frames_calc(steps_calc));
            
            if ftCorr < .999
                warning('Calculated frame time correlation is low: %.8f', ftCorr)
            end
            if rtCorr < .999
                warning('Calculated remote time correlation is low: %.8f', rtCorr)
            end

            % put calculate events into buffer
            ebTmp = cell(numFrames, 3);
            ebTmp(1:numFrames, 1) = num2cell(int64(lt_calc));
            ebTmp(1:numFrames, 2) = num2cell(int64(rt_calc));
            for ev = 1:numFrames
                ebTmp{ev, 3} = {...
                    [frameLabel, '_FRAME_CALC'],...
                    ft_calc(ev),...
                    frames_calc(ev)};
            end
            eventBuffer = etCombineSortEvents({eventBuffer, ebTmp});

            outcome = 'Success';
            
        end
            
    end
    
end