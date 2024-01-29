function [eyeValSeries, timeSeriesS] = etEyeValiditySeries(mb, tb, binWidthS)

    % if not bin width supplied, default to 5s
    if ~exist('binWidthS', 'var') || isempty(binWidthS)
        binWidthS = 15;
    end
    
    if ~isa(binWidthS, 'uint64')
        binWidthS = uint64(binWidthS);
    end
    
    if isempty(mb) || isempty(tb) || all(all(mb == 0)) || all(all(tb == 0))
        eyeValSeries = [];
        timeSeriesS = [];
        return
    end
    
    % work out number of bins and preallocate output var
    duration = tb(end, 1) - tb(1, 1);
    binWidthMicS = binWidthS * 1000000;
    numBins = floor(duration / binWidthMicS);
    
    % check duration is not longer than four hours
    if duration > 4 * 60 * 60 * 1000000
        eyeValSeries = [];
        timeSeriesS = [];
        fprintf('<strong>eyEyeValiditySeries:</strong> Long (>4 hrs) session, not computing.\n')
        return
    end
    
    if numBins == 0
        eyeValSeries = [];
        timeSeriesS = [];
        return
    end
    
    eyeValSeries = zeros(1, numBins);
    timeSeriesS = zeros(1, numBins);
    binStartTime = tb(1, 1);
    binEndTime = binStartTime + uint64(binWidthMicS);
    
    for bin = 1:numBins
        
        s1 = etTimeToSample(tb, binStartTime);
        s2 = etTimeToSample(tb, binEndTime);
        mb_avg = etAverageEyeBuffer(mb(s1:s2, :));
%         
%         eyeValL = mb_avg(:, 13);
%         eyeValR = mb_avg(:, 26);
        
        gx = mb_avg(:, 7);
        gy = mb_avg(:, 8);
        val = gx >= 0 & gx <= 1 & gy >= 0 & gy <= 1;
        eyeValSeries(bin) = mean(val);
%         eyeValSeries(1, bin) = mean(eyeValL == 4 & eyeValR == 4);
%         eyeValSeries(3, bin) = mean(eyeValL == 0 & eyeValR == 0);
%         eyeValSeries(2, bin) = mean(eyeValL ~= 4 & eyeValR ~= 4 & eyeValL ~= eyeValR);
        timeSeriesS(bin) = binStartTime;
        
        binStartTime = binStartTime + binWidthMicS;
        binEndTime = binEndTime + binWidthMicS;
        
    end
    
    timeSeriesS = (timeSeriesS - timeSeriesS(1)) / 1000000;
    
end