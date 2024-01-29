function [mbr, tbr, tr] = etResample(mb, tb, fs)

    % convert time to seconds
    t = etTimeBuffer2Secs(tb);
    
    % defaults
    mbr = mb;
    tbr = tb;
    tr = t;
    
    % check time buffer for jumps, remove jump samples if found
    [jumpFound, jumpIdx] = etDetectJumpBuffer(tb);
    if jumpFound
        mb(jumpIdx, :) = [];
        tb(jumpIdx, :) = [];
        t(jumpIdx, :) = [];
    end
    
    % if buffer is empty, or only one row high, then give up
    if size(mb, 1) <= 1, return, end
    
    % check that main and time buffers are of the same size
    if size(mb, 1) ~= size(tb, 1)
        error('Size mismatched between main and time buffers.')
    end
    
    % find missing eyes. these will be replaced after resampling, because
    % matlab's resample function interpolates missing data (which we don't
    % want). Pad first and last samples with nans, as otherwise findcontig
    % will miss them
    mb = [nan(1, size(mb, 2)); mb; nan(1, size(mb, 2))];
    
    missL = mb(:, 13) == 4;
    missR = mb(:, 26) == 4;
    
    % find runs of nans (separately for each eye). 
    missRunsL = findcontig2(missL, 1);
    missRunsR = findcontig2(missR, 1);
    
    % remove padding
    mb([1, end], :) = [];
    missL([1, end]) = [];
    missR([1, end]) = [];
    
    % convert missing sample numbers to times
    missTimeL = contig2time(missRunsL, t);
    missTimeR = contig2time(missRunsR, t);
    
    % Matlab's resample function won't work if all data are missing. Detect
    % this for each eye separately, and fill entirely missing data with
    % infs - these will be removed again later. 
    missL = mb(:, 13) == 4;
    missR = mb(:, 26) == 4;
    mb(missL, 1:13) = inf(sum(missL), 13);
    mb(missR, 14:26) = inf(sum(missR), 13);
%     missL = all(...
%         all(mb(:, [1:3, 6, 9:11, 14:15, 19, 22:24]) == 0, 2) &...
%         all(isnan(mb(:, [7, 8, 12, 20, 21, 25])), 2) &...
%         all(mb(:, [13, 26]) == 4, 2), 2);
%     mb(missL, :) = inf(sum(missL), size(mb, 2));
    
    % resample
    [mbr, tr] = resample(mb, t, fs);
    
    % convert validity codes back to original as well as possible by
    % rounding 
    mbr(:, 13) = round(mbr(:, 13));
    mbr((mbr(:, 13) > 4)) = 4;
    mbr(:, 26) = round(mbr(:, 26));
    mbr((mbr(:, 26) > 4)) = 4; 
    
    % replace originaly missing data in resampled data with nans -
    % separately for both eyes
    mbr(:, 1:13) =...
        replaceMissing(mb(:, 1:13), mbr(:, 1:13), t, tr, missTimeL);
    mbr(:, 14:26) =...
        replaceMissing(mb(:, 14:26), mbr(:, 14:26), t, tr, missTimeR);  
    
    % convert resampled time vectore (in seconds) back to timebuffer (in
    % microseconds)
    time_uS = tb(1, 1) + uint64(tr * 1e6);
    trigger = uint64(zeros(length(time_uS), 1));
    tbr = [time_uS, trigger];
    
end

function mbRep = replaceMissing(mb, mbr, t, tr, missTimes)

    mbRep = mbr;
    
    for m = 1:size(missTimes, 1)
        
        % convert times to samples
        s1RS = find(tr >= missTimes(m, 1), 1, 'first');
        s2RS = find(tr >= missTimes(m, 2), 1, 'first');
        
        % if we're on the first or last sample, the previous statements
        % will have returned empty. check for this
        if isempty(s1RS), s1RS = 1; end
        if isempty(s2RS), s2RS = size(mbr, 1); end

        % repeat first line of original data for each missing chunk
        s1 = find(t >= missTimes(m, 1), 1, 'first') - 1;
%         s2 = find(time >= missTimes(m, 2), 1, 'first');
        
        mbRep(s1RS:s2RS, :) =...
            repmat(mb(s1, :), [s2RS - s1RS + 1, 1]);
        
    end

end