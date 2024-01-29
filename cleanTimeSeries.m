function [sy, bestSpan] = cleanTimeSeries(x, y, varargin)
% sy = CLEANTIMESERIES(x, y) iteratively finds the best span to
% use with robust lowess smoothing to clean noisy time series data. Returns
% the data smoothed with the best span, and optionally a second output 
% bestSpan. 

    % parse inputs
    parser          = inputParser;
    addParameter(   parser, 'spanRange',        7:2:30,     @isnumeric  )
    addParameter(   parser, 'plotResult',       false,      @islogical  )
    addParameter(   parser, 'plotFilename',     [],         @ischar     )
    addParameter(   parser, 'removeNaN',        false,      @islogical  )
    addParameter(   parser, 'interpNaN',        false,      @islogical  )
    addParameter(   parser, 'interpMax',        inf,        @isnumeric  )
    addParameter(   parser, 'parallelProcess',  true,       @islogical  )
    parse(          parser, varargin{:})
    spanRange       = parser.Results.spanRange;
    plotResult      = parser.Results.plotResult;
    plotFilename    = parser.Results.plotFilename;
    removeNaN       = parser.Results.removeNaN;
    interpNaN       = parser.Results.interpNaN;
    interpMax       = parser.Results.interpMax;
    parallelProcess = parser.Results.parallelProcess;

    % check inputs 
    if ~isempty(plotFilename) && ~plotResult
        warning('Ignoring plotFilename parameter because plotResult was not set to true.')
    end
    
    if removeNaN && interpNaN
        error('Cannot remove and interpolate NaNs at the same time.')
    end
    
    if ~interpNaN && interpMax ~= inf
        warning('Ignoring interpMaxMs parameter as interpNaN was not set to true.')
    end
    
    if parallelProcess, parForArg = inf; else parForArg = 0; end
        
    % store sum squared errors
    sse = zeros(size(spanRange));
    
    % remove nans from x, y
    missing = isnan(y);
    xraw = x(~missing);
    yraw = y(~missing);
    
    % check length
    if length(yraw) < 2 || length(xraw) < 2
        sy = nan;
        bestSpan = nan;
        return
    end
    
    cp = cvpartition(length(yraw), 'k', 10);

    parfor (s = 1:length(spanRange), parForArg)
%     for s = 1:length(spanRange)
        
        fprintf('Validating span %d (%.1f%%)...\n', spanRange(s),...
            (s / length(spanRange)) * 100);
        
        % define anon func to compare test and training data
        f = @(train, test) norm(test(:, 2) - mySmooth(train, test(:, 1),...
            spanRange(s))) ^ 2;
        
        % cross validate, get all sse's and sum
        sse(s) = nansum(crossval(f, [xraw, yraw], 'partition', cp));

    end

    % find best span
    [~, minj] = min(sse);
    bestSpan = spanRange(minj);
    
    % final smooth using best span
    fprintf('Smoothing with best span %d...\n', bestSpan);
    sy = smooth(x, y, bestSpan, 'rlowess');
    
    % deal with NaNs
    if removeNaN
        sy(missing) = nan;
    elseif interpNaN
        % find length of nans
        if any(missing)
            % find runs, filter out runs above duration criterion
            ct = findcontig(missing, true);
            filt = ct(:, 3) <= interpMax;
            ct = ct(filt, :);
            % convert ct back to samples
            dontInterp = missing;
            for c = 1:size(ct, 1)
                dontInterp(ct(c, 1):ct(c, 2)) = false;
            end
            % interp
%             syi = interp1(x(~missing), sy(~missing), x(missing),...
%                 'method', 'spline');
            syi = interp1(x(~missing), sy(~missing), x(missing),...
                'spline');            
            sy(missing) = syi;
            sy(dontInterp) = nan;
        end
    end
        
    % optionally plot result
    if plotResult
        figure
        scatter(x, y, [], 'k')
        hold on
        plot(x, sy, 'r')
        if ~isempty(plotFilename)
            export_fig(gcf, plotFilename, '-r100')
            close all
        end
    end
    
    fprintf('Done.\n')

end

function ys = mySmooth(xy,xs,span)
%MYLOWESS Lowess smoothing, preserving x values
%   YS=MYLOWESS(XY,XS) returns the smoothed version of the x/y data in the
%   two-column matrix XY, but evaluates the smooth at XS and returns the
%   smoothed values in YS.  Any values outside the range of XY are taken to
%   be equal to the closest values.

    if nargin<3 || isempty(span)
        span = .3;
    end

    % Sort and get smoothed version of xy data
    xy = sortrows(xy);
    x1 = xy(:,1);
    y1 = xy(:,2);
    ys1 = smooth(x1,y1,span,'rlowess');

    % Remove repeats so we can interpolate
    t = diff(x1)==0;
    x1(t)=[]; ys1(t) = [];

    % Interpolate to evaluate this at the xs values
    ys = interp1(x1,ys1,xs,'linear',NaN);

    % Some of the original points may have x values outside the range of the
    % resampled data.  Those are now NaN because we could not interpolate them.
    % Replace NaN by the closest smoothed value.  This amounts to extending the
    % smooth curve using a horizontal line.
    if any(isnan(ys))
        ys(xs<x1(1)) = ys1(1);
        ys(xs>x1(end)) = ys1(end);
    end

end