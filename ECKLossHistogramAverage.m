function [meanCount, meanTime, sdCount, sdTime] =...
    ECKLossHistogramAverage(countHist, timeHist)

    if ~all(cellfun(@length, countHist) == length(countHist{1})) ||...
            ~all(cellfun(@length, timeHist) == length(countHist{1}))
        error('All histograms must have same number of bin.')
    end
    
    allCount = cell2mat(countHist);
    allTime = cell2mat(timeHist);
    
    meanCount = mean(allCount, 2);
    meanTime = mean(allTime, 2);
    sdCount = std(allCount, 0, 2);
    sdTime = std(allTime, 0, 2);
        
end
    
    