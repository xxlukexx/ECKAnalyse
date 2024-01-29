function inAOI = aoiInterp(inAOI, missing, time, maxMs)

%     figure
%     subplot(2, 1, 1)
%     bar(inAOI, 'facealpha', .3, 'edgecolor', 'none', 'barwidth', 1)
%     hold on
%     bar(missing, 'facealpha', .3, 'edgecolor', 'none', 'facecolor', 'r', 'barwidth', 1)
%     fprintf('Number of looks to AOI 1 BEFORE: %d\n',...
%         size(findcontig(inAOI(:, 1), true), 1));





    if ~exist('maxMs', 'var')
        maxMs = 150;
    end
    
    numAOIs = size(inAOI, 2);    
    % find runs of missing, convert from samples to time
    ctm                     = findcontig2(missing | all(~inAOI, 2), true);
    if isempty(ctm), return, end
    ctm(:, 2)               = ctm(:, 2) + 1;
    outOfBounds             = ctm(:, 2) > length(time);
    ctm(outOfBounds, 2)     = length(time);
    ctm_time                = time(ctm(:, 1:2));
    if size(ctm, 1) > 1 && size(ctm, 2) == 1
        ctm = ctm';
    end
%     if size(ctm, 1) == 1, ctm_time = ctm_time'; end
    dur                     = ctm_time(:, 2) - ctm_time(:, 1);
    
    % remove gaps longer than criterion 
    tooLong                 = dur > maxMs;
    ctm(tooLong, :)         = [];
    ctm_time(tooLong, :)    = [];
    dur(tooLong)            = [];
    
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
        check2 = inAOI(e2(e) - 1, :);
        
        % check state is valid 
        val(e, :) = sum([check1; check2], 1) == 2;
        
        for a = 1:numAOIs
            if val(e, a)
                inAOI(ctm(e, 1):ctm(e, 2) - 1, a) = true;
                missing(ctm(e, 1):ctm(e, 2)) = false;
            end        
        end
        
    end

%     subplot(2, 1, 2)
%     bar(inAOI, 'facealpha', .3, 'edgecolor', 'none', 'barwidth', 1)
%     hold on
%     bar(missing, 'facealpha', .3, 'edgecolor', 'none', 'facecolor', 'r', 'barwidth', 1)
%         fprintf('Number of looks to AOI 1 AFRER: %d\n',...
%         size(findcontig(inAOI(:, 1), true), 1));
    
%     
%     
%     % if no gaps, or all gaps, don't interpolate
%     if all(inAOI) || all(~inAOI), return, end
%     
%     % if all missing, or none missing, return
%     if all(missing) || all(~missing), return, end
%     
%     % find contiguous runs of samples not in AOI (i.e. gaps)
%     ct = findcontig2(~inAOI & missing, false);
%     
%     % convert from samples to time
%     ct_time = time(ct(:, 1:2));
%     if size(ct, 1), ct_time = ct_time'; end
% 
%     % find the duration of each gap
%     ct_dur = ct_time(:, 2) - ct_time(:, 1);
%     
%     % find those that are less than criterion
%     toInterp = ct_dur <= maxMs;
%     
%     % filter out non-interpolable gaps
%     ct(~toInterp, :) = [];
%     
%     % now fill any gaps less than criterion with 1s
%     for i = 1:size(ct, 1)
%         inAOI(ct(i, 1):ct(i, 2)) = true;
%     end

end