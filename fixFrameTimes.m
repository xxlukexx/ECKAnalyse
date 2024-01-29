function [eventBuffer, ftCorr, rtCorr, outcome] = etFixFrameTimes(...
    eventBuffer, timeBuffer, onsetEvent, offsetEvent, frameLabel)
     
    ftCorr = nan; rtCorr = nan; outcome = 'Unkown error';
    
    % filter for just natscenes events
    eb = etFilterEvents(eventBuffer, frameLabel, true);
    
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

        % find all frametime events between these times
        rt = cell2mat(eb(trialOnsetSamp:trialOffsetSamp, 2));
        lt = cell2mat(eb(trialOnsetSamp:trialOffsetSamp, 1));
        ftCell = eb(trialOnsetSamp:trialOffsetSamp, 3);
        ft = cellfun(@(x) x{2}, ftCell);
        numFt = size(ft, 1);
        frames = (29 .* (1:numFt))';
        
        if size(ft, 1) > 2
       
            % calculate seconds-per-frame, and microsecs-per-frame
            spf = ft(1) / frames(1);
            uspf = spf * 1000000;

            % recalculate frame times and remote times for known frames (as a
            % sanity check)
            ft_calc = frames .* spf;
            ft_calc_us = frames .* uspf;
            rt_calc = double(rt(1)) + ft_calc_us;
            lt_calc = double(lt(1)) + ft_calc_us;
            ftCorr = corrcoef(ft, ft_calc);
            ftCorr = ftCorr(2, 1);
            rtCorr = corrcoef(double(rt), rt_calc);
            rtCorr = rtCorr(2, 1);
    %         fprintf('<strong>LEAP_ET_fixFrameTimes</strong> known frame times vs calculated frame times: %.8f\n', ftCorr)
    %         fprintf('<strong>LEAP_ET_fixFrameTimes</strong> known remote times vs calculated remote times: %.8f\n', rtCorr)
            if ftCorr < .999
                warning('Calculated frame time correlation is low: %.8f', ftCorr)
            end
            if rtCorr < .999
                warning('Calculated remote time correlation is low: %.8f', rtCorr)
            end

            % derive frame times for every frame
            frames_all = (1:max(frames))';
            ft_all = frames_all .* spf;
            ft_all_us = frames_all .* uspf;

            % derive local and remote times
            rt_calc_all = zeros(max(frames), 1, 'int64');
            lt_calc_all = zeros(max(frames), 1, 'int64');

            knownIdx = frames(1);        
            preIdx = (1:knownIdx - 1)';
            postIdx = (knownIdx + 1:max(frames))';

            pre_rt_calc = rt(1) + -int64(flipud(preIdx * uspf));
            post_rt_calc = rt(1) + int64((postIdx - knownIdx) * uspf);

            pre_lt_calc = lt(1) + -int64(flipud(preIdx * uspf));
            post_lt_calc = lt(1) + int64((postIdx - knownIdx) * uspf);

            rt_calc_all(knownIdx) = rt(1);
            rt_calc_all(preIdx) = pre_rt_calc;
            rt_calc_all(postIdx) = post_rt_calc;

            lt_calc_all(knownIdx) = lt(1);
            lt_calc_all(preIdx) = pre_lt_calc;
            lt_calc_all(postIdx) = post_lt_calc;

            % put calculate events into buffer
            numFrames = length(ft_all);
            ebTmp = cell(numFrames, 3);
            ebTmp(1:numFrames, 1) = num2cell(lt_calc_all);
            ebTmp(1:numFrames, 2) = num2cell(rt_calc_all);
            for ev = 1:numFrames
                ebTmp{ev, 3} = {...
                    [frameLabel, '_FRAME_CALC'],...
                    ft_all(ev),...
                    frames_all(ev)};
            end
            eventBuffer = etCombineSortEvents({eventBuffer, ebTmp});

            outcome = 'Success';
            
        end
            
    end
    
end