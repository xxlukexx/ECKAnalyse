% tab = ETTABULATE(seg) converts the format of the data in seg to a table,
% containing variables for ID, timepoint, left/right [x, y] coords, valid
% and present flags, and a time vector in seconds
    
function [t, lx, ly, rx, ry, missingLeft, missingRight, notPresent, id, tp, lp, rp] =...
    etTabulateSeg(seg, maxDur)

    if ~exist('maxDur', 'var') || isempty(maxDur)
        maxDur = inf;
    end

% for each subject, calculate the length of eye tracker data in number of
% samples

    % get number of subjects
    numSubs = seg.numIDs;
    
%     % calculate length of data, per-subject
%     lens = cellfun(@(x) size(x, 1), seg.mainBuffer);
    
    % calculate duration for each subject
    ts = cellfun(@etTimeBuffer2Secs, seg.timeBuffer, 'UniformOutput', false);
    
    % find sample in time vector for each sub that represents that max
    % duration
    lens = cellfun(@(x) find(x <= maxDur, 1, 'last'), ts);
    
    % find length of longest subject's data
    max_len = max(lens);
    
% preallocate left/right [x, y] and time vector. Inf values means "not
% present" 

    lx = inf(max_len, numSubs);    
    ly = inf(max_len, numSubs);   
    rx = inf(max_len, numSubs);  
    ry = inf(max_len, numSubs);   
    lp = inf(max_len, numSubs);  
    rp = inf(max_len, numSubs);       
    t = inf(max_len, numSubs);   
    id = cell(numSubs, 1);
    tp = cell(numSubs, 1);
    
% loop though each segment, and extract the left/right [x, y] coords and
% time vector. The resulting [x, y] coords are in [sample x subject]
% matrices

    for sub = 1:numSubs
        
        % extract time vectors
        t(1:lens(sub), sub) =...
            etTimeBuffer2Secs(seg.timeBuffer{sub}(1:lens(sub), :));    
        
%         % query time vector for max duration
%         s2 = find(t <= maxDur, 1, 'last');
%         t = t(1:s2);
        
        % extract left/right [x, y] coords
        lx(1:lens(sub), sub) = seg.mainBuffer{sub}(1:lens(sub), 7);
        ly(1:lens(sub), sub) = seg.mainBuffer{sub}(1:lens(sub), 8);
        rx(1:lens(sub), sub) = seg.mainBuffer{sub}(1:lens(sub), 20);
        ry(1:lens(sub), sub) = seg.mainBuffer{sub}(1:lens(sub), 21);
        lp(1:lens(sub), sub) = seg.mainBuffer{sub}(1:lens(sub), 12);
        rp(1:lens(sub), sub) = seg.mainBuffer{sub}(1:lens(sub), 25);
        
        % extract ID and timepoint
        id{sub} = seg.ids{sub};
        tp{sub} = seg.timePoints{sub};
        
    end

% find missing data, defined as no sample in either the left OR the right
% eye

    missingLeft = isnan(lx) | isnan(ly);
    missingRight = isnan(rx) | isnan(ry);
    
% find not present data
    
    % now that lx, ly, rx, ry have been filled in with data, form a
    % notPresent flag vector for each subject indicating that there was no
    % gaze data for these samples. This is done so that the matrix holding
    % all subjects' data (which is numSamples tall) is the same size for
    % everyone, but where some subjects have more data than others, we
    % record not present data in the notPresent flag vector. Note that
    % "not present" and "missing" are different - "missing" means that
    % there could have been valid data for that sample, but that the eye
    % tracker didn't see the eyes. "no present" means that no data was
    % present for those samples. Both types of data are excluded from AOI
    % analyses, but for different reasons
    notPresent = lx == inf | ly == inf | rx == inf | ry == inf;
    
    % not set all of the infs that were in the lx, ly, rx, ry and time
    % vector variables to nan. Internally these now look identical to
    % missing data, but the notPresent and missing variables code for the
    % source of data loss 
    lx(notPresent) = nan;
    ly(notPresent) = nan;
    rx(notPresent) = nan;
    ry(notPresent) = nan;
    lp(notPresent) = nan;
    rp(notPresent) = nan;
    t(notPresent) = nan;
    
% form final time vector from each subject's time vectors

    % since time vectors may differ slightly, for each sample of data, take
    % the mode time value
    t = nanmedian(t, 2);
    
end

