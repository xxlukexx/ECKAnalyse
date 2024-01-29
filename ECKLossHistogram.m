function [countHist, timeHist, countBins, timeBins] =...
    ECKLossHistogram(mb, tb, eb, echo)

    if ~exist('echo', 'var') || isempty(echo)
        echo = true;
    end

    if echo, stat = ECKStatus('Calculating histograms...\n'); end
       
    countBins = logspace(1, 4, 100)';
    numBins = length(countBins);

    % preallocate output vars
    countHist = [];
    timeHist = [];
    timeBins = [];
         
    [countHist, timeHist, timeBins] =...
        doLossHistogram(mb, tb, eb, countBins);
    
    if echo, stat.Status = ''; end
        
end

function [hCount, hTime, binTimes] = doLossHistogram(mb, tb, eb, bins)
  
    % filter breaks
    [mb, tb] = etFilterOutEvents(mb, tb, eb, 'BREAKIMG_ONSET',...
        'BREAKIMG_OFFSET');

    % return missing data for left and right eyes
    eyeVal = all(mb(:, [13,26]) == 0, 2);
    
    % find contiguous runs of empty data (gaps)
    gaps = findcontig(eyeVal, 1);
    numGaps = size(gaps, 1);
    
    if numGaps > 1 && ~(all(all(mb == 0)) || all(all(tb == 0)))
    
        % convert gap sizes from samples to times
        gapTimes = zeros(numGaps, 1);
        for g = 1:numGaps  
            gapTimes(g) =...
                tb(gaps(g, 2)) - tb(gaps(g, 1));
        end

        % convert times from us to ms
        gapTimes = gapTimes / 1000;

        % make time histogram
        binTimes = bins;
        hTime = histc(gapTimes, binTimes);
        hTime = (hTime .* binTimes) / 1000;

        % make count histogram
        [hCount, ~] = histc(gapTimes, bins);
    
    else
        
        binTimes = bins;
        hCount = [];
        hTime = [];
    
    end

end