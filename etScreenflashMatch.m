function [matchSF, sfEvents] = etScreenflashMatch(sf, data,...
    toleranceSecs, video)

    % takes a screenflash struct, and one ECKData, and attempts to match
    % the screenflash timestamps extracted from video (using
    % findScreenflash.m) with the screenflash markers in the data.
    % 
    % video is an optional input argument. If present, and if the number of
    % events does not match the number of detected screen flashes, it will
    % attempt to use the video duration to narrow down the selection 
    
    %% data wrangling
    
    % if 'toleranceSecs' input var is not present, use a default
    if ~exist('toleranceSecs', 'var') || isempty(toleranceSecs)
        fprintf('<strong>etScreenflashMatch: </strong>Using default value for toleranceSecs.\n')
        toleranceSecs = 1;
    end
    
    % check data
    if isa(data, 'ECKData') || isa(data, 'ECKDataContainer')
        dc = checkDataIn(data);
        sfEvents = etFilterEvents(dc.Data{1}.EventBuffer, 'SCREENFLASH_END'); 
    else
        sfEvents = data; 
    end
    sfEvents = etRemoveInvalidSFEvents(sfEvents);
    sfEvents = etSortSFEvents(sfEvents);
    
    % check sf
    sf = checkScreenflashIn(sf);
    
    % if screenflash was not found, give up
    if ~sf.found
        return
    end
    
    % sort sf 
    sf = sortSF(sf);
    
    % get number of screenflashes and make empty logical indexing var
    numEvents = size(sfEvents, 1);
    numSF = length(sf.sfTime);
    matchSF = false(1, numSF);
    
    %% check number of flashes/events
    
    % if either sf or events are missing, cannot match
    if numEvents == 0 || numSF == 0
        matchSF = false;
        return
    end
    
    % if one of each, assume this is a match and return
    if numEvents == 1 && numSF == 1
        matchSF = true;
        return
    end
    
    % calculate deltas between pairs of events, and offsets from first
    % event
    if numEvents > 1
        etDelta = double(sfEvents{2, 2} - sfEvents{1, 2}) / 1e6;
    else
        etDelta = [];
    end
    etOffset = double(cell2mat(sfEvents(:, 2)) - sfEvents{1, 2}) / 1e6;
    
    % calculate deltas between pairs of sfs, and offsets from first sf
    if numSF > 1
        sfDelta = [sf.sfTime(2:end) - sf.sfTime(1:end - 1)]';
    else 
        sfDelta = [];
    end
    sfOffset = [sf.sfTime - sf.sfTime(1)]';
    
    % calculate offset of each sf to the end of the video
    if exist('video', 'var') && ~isempty(video)
        info = mmfileinfo(video);                   % get video info
        dur = info.Duration;                        % video duration
        vidEndOffset = dur - sf.sfTime;              % pair deltas
    else 
        vidEndOffset = [];  
    end
    
    % depending upon number of events and sfs, try to match 
    if numEvents == numSF
        
        % if the numbers match, check that the difference between deltas is
        % below the tolerance threshold, if it is, they match

        % test against tolerance
        delta = abs(etDelta - sfDelta);
        tol = logical(delta <= toleranceSecs);

        % add entry for first screenflash back into match index. If the first
        % entry in tol is true (indicating that the first TWO screenflashes are
        % a pair), change this first entry to true;
        if tol(1)
            matchSF = [true, tol];
        else
            matchSF = [false, tol];
        end
        sfEvents = sfEvents(matchSF, :);
        
    elseif numSF == 1 && numEvents == 2 && exist('video', 'var')
        
        % only one sf but two events

        % find event that is closest to sf
        dist = etOffset - sfOffset;
        matchSF = dist == min(dist);

    elseif numSF == 2 && numEvents == 1

        % event missing in eye tracking data. If the lone available
        % event is in the first 5% of events, we can assume this is a
        % screenflash at the start. Likewise, if it is in the final 5%
        % of events, assume it is at the end. Since we have exactly two
        % flashes in the video, assume one is at the start and one at
        % the end

        atStart = sfEvents{1, 4} < .05 * size(dc.Data{1}.EventBuffer, 1);
        atEnd = sfEvents{1, 4} > .95 * size(dc.Data{1}.EventBuffer, 1);

        if atStart
            matchSF = [true; false];
        elseif atEnd
            matchSF = [false; true];
        end
        
    else 
        
%         % try to match on deltas
%         sfPoss = find(arrayfun(@(x) any((etDelta - x) < toleranceSecs), sfDelta));
%         if length(sfPoss) > 1, sfPoss = sfPoss(1); end
%         
%         deltaDiff = etDelta - sfDelta;
%         deltaTol = deltaDiff <= toleranceSecs;
%         if any(deltaTol)
                
            
            
        fprintf(2, 'NOT IMPLEMENTED!')
        return

    end
    
end