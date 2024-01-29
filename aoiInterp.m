function [inAOI, missing] = aoiInterp(inAOI, missing, time, varargin)

    % if all in, or all out, return
    if all(inAOI(:)) || ~any(inAOI(:))
        return
    end

    if ~exist('maxMs', 'var')
        maxMs = 150;
    end
    
    numAOIs = size(inAOI, 2);    
    outOfAOI                = all(~inAOI, 2);
    % find runs of missing or out-of-AOI samples
    ctm                     = findcontig2(missing | outOfAOI, true);
    if isempty(ctm), return, end
    % convert to ms
    [ctm_time, ctm]         = contig2time(ctm, time);
    ctm_time                = ctm_time * 1000;
    % remove gaps longer than criterion 
    tooLong                 = ctm_time(:, 3) > maxMs;
    ctm(tooLong, :)         = [];
    ctm_time(tooLong, :)    = [];
    dur                     = ctm_time(:, 3);
    
    % find samples on either side of the edges of missing data
    e1                      = ctm(:, 1) - 1;
    e2                      = ctm(:, 2) + 1;
    
    % remove out of bounds 
    outOfBounds             = e1 == 0 | e2 > size(inAOI, 1);
    e1(outOfBounds)         = [];
    e2(outOfBounds)         = [];
    ctm(outOfBounds, :)     = [];
    ctm_time(outOfBounds, :)= [];
    dur(outOfBounds)        = [];
    
    % check each edge and flag whether a) gaze was in an AOI at both edges,
    % and b) gaze was in the SAME AOI at both edges
    val = false(length(dur), numAOIs);
    for e = 1:length(e1)

        % get state of all AOIs at edge samples
        check1 = inAOI(e1(e), :);
        check2 = inAOI(e2(e), :);
        
        % check state is valid 
        val(e, :) = sum([check1; check2], 1) == 2;
        
        % fill in gaps
        for a = 1:numAOIs
            if val(e, a)
                inAOI(ctm(e, 1):ctm(e, 2), a) = true;
                missing(ctm(e, 1):ctm(e, 2)) = false;
            end        
        end
        
    end

end