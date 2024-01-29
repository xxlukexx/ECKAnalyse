function [gaps, numGaps, propMissing] = etMeasureGaps(x, y, t)
% gaps = ETMEASUREGAPS(x, y) measures the length of each gap (comprised of
% samples of missing data) in eye tracking coordinates x and y. Missing
% samples must be NaNs. 
%
% gaps = ETMEASUREGAPS(x, y, t) uses vector of timestamps t to return gap
% metrics in the same units as t. If t is not specified, then units will
% default to samples. 
%
% Version 0.1 20180130
%   

    % if no time units specified, use samples
    if ~exist('t', 'var') || isempty(t)
        t = 1:length(x);
        if isrow(t) && ~isrow(x), t = t'; end
        convertUnits = false;
    else
        convertUnits = true;
    end
    
    % check input args
    if ~isvector(x) || ~isnumeric(x) || ~isvector(y) || ~isnumeric(y) ||...
            ~isvector(t) || ~isnumeric(t)
        error('All inputs must be numeric vectors.')
    end
    
    if ~isequal(size(x), size(y), size(t))
        error('All inputs must be the same size and shape.')
    end
    
    % defaults
    gaps = [];
    numGaps = 0;
    propMissing = 0;

    % logical vector of missing data
    missing = isnan(x) & isnan(y);
    
    % check that there is some missing data
    if ~any(missing)
        return
    end
    
    % find contiguous runs of missing data
    ct = findcontig2(missing); 
    
    % convert to time units
    if convertUnits
        onset = t(ct(:, 1));
        offSetIdx = ct(:, 2) + 1;
        outOfRange = offSetIdx > length(t);
        if any(outOfRange)
            offSetIdx(outOfRange) = [];
            onset(outOfRange) = [];
        end
        offset = t(offSetIdx);
        if isempty(onset), return, end
        gaps = offset - onset;
    else
        gaps = ct(:, 3);
    end
    
    % metrics
    numGaps = length(gaps);
    propMissing = sum(missing) / length(missing);
    
end