

function [dataOut, flags] = etInterpBuffer(varargin)

% if only one input arguments, then assume this is a cfg struct
if nargin == 1 
    if isstruct(varargin{1})
        cfg = structFieldsToLowercase(varargin{1});
    else
        error('Input arguments must be either 1) cfg struct; or 2) mainBuffer, timeBuffer, maxMs.')
    end
else
    if nargin >= 3
        cfg.mainbuffer = varargin{1};
        cfg.timebuffer = varargin{2};
        cfg.maxms = varargin{3};
    end
    if nargin >= 4
        cfg.dontfilter = varargin{4};
    end
end

if ~isfield(cfg, 'dontfilter') || isempty(cfg.dontfilter)
    cfg.dontfilter = false;
end

if ~isfield(cfg, 'makeplot') || isempty(cfg.makeplot)
    cfg.makeplot = false;
end

if ~isfield(cfg, 'maxslope') || isempty(cfg.maxSlope)
    cfg.maxSlope = .05;
end

flags = false(size(cfg.mainbuffer, 1), 6);

mb = cfg.mainbuffer; clear mainBuffer;
tb = cfg.timebuffer; clear timeBuffer;

% get rid of invalid/offscreen data
if ~cfg.dontfilter
    mb = etFilterGazeOnscreen(mb);
end

% get timing data on buffer
[~, msPerS] = etDetermineSampleRate(tb);
maxSamp = round(cfg.maxms / msPerS / 1000);

% get gaze data
lx = mb(:, 7);
ly = mb(:, 8);
lp = mb(:, 12);
rx = mb(:, 20);
ry = mb(:, 21);
rp = mb(:, 25);

% do interpolation
[lx_int, lx_idx] = doInterp(lx);
[ly_int, ly_idx] = doInterp(ly);
[lp_int, lp_idx] = doInterp(lp);
[rx_int, rx_idx] = doInterp(rx);
[ry_int, ry_idx] = doInterp(ry);
[rp_int, rp_idx] = doInterp(rp);

% store samples that were interpolated in flags output var
flags = any([lx_idx, ly_idx, lp_idx, rx_idx, ry_idx, rp_idx], 1);

% store in buffer
dataOut = mb;
dataOut(:, [7:8, 12, 20:21, 25]) =...
    [lx_int, ly_int, lp_int, rx_int, ry_int, rp_int];

% plot (if requested)
if cfg.makeplot
    figure('name', 'Interpolation results')
    t = double(tb(:, 1) - tb(1, 1)) / 1000;
    
    spx = subplot(2, 1, 1);
    hold(spx, 'on')
    title('X')
    plot(t, lx_int, '-r', 'linewidth', 2)
    plot(t, lx, '-k')
    xlabel('Time (ms)')
    ylabel('Point of gaze')
    ylim([0, 1])
    
    spx = subplot(2, 1, 2);
    hold(spx, 'on')
    title('Y')
    plot(t, ly_int, '-r', 'linewidth', 2)
    plot(t, ly, '-k')
    xlabel('Time (ms)')
    ylabel('Point of gaze')
    ylim([0, 1])
end

    function [x_out, x_idx] = doInterp(x)
        
        % find nans
        x_nan = isnan(x);

        % interpolate
        t = 1:numel(x);
        if sum(x_nan) < length(x_nan) - 2
            xi = interp1(t(~x_nan), x(~x_nan), t, 'linear'); 
        else
            xi = x;
        end
        
        % get indices of interpolated samples
        [x_idx, ct] = etInterp_makeIdx(xi, x_nan, maxSamp);
        if ~isempty(ct)
            ct_norm = ct / max(ct(:));
            xi_norm = xi / max(xi(:));
        
            % find slopes of interpolated sections, reject if >.5
            for c = 1:size(ct, 1)
                s1 = ct(c, 1);
                s2 = ct(c, 2);
                tLen = ct_norm(c, 2) - ct_norm(c, 1);
                xLen = xi_norm(s2) - xi_norm(s1);
                slope = abs(xLen / tLen);
                if slope > .75, x_idx(s1:s2) = false; end
            end
        end
        
        % replace interpolated data where the number of missing samples is
        % greater than the maximum specified
        x_out = x;
        x_out(x_idx) = xi(x_idx);      
        
    end

    function [idx, ct] = etInterp_makeIdx(x, xnan, maxSamp)
        
        % default output 
        idx = false(1, length(x));

        % find contigous runs of nans, measure length of each
        ct = findcontig(xnan, 1);

        % if none found, return
        if isempty(ct)
            return
        else
            % select those runs that are shorter than the maximum length that
            % we'll interpolate for (default is 150ms)
            ct = ct(ct(:, 3) <= maxSamp, :);
            
            % loop through all valid interpolated sections (i.e. missing
            % data was less than criterion) and mark these as valid
            for i = 1:size(ct, 1)
                idx(ct(i, 1):ct(i, 2)) = true;
            end

            % if none found, return empty
            if isempty(ct), idx = []; end

            % otherwise loop through all segments that are short enough to
            % interpolate. Check that the slope of each segment doesn't exceed
            % maxSlope (default .1)
            for e = 1:size(ct, 1)

                if x(ct(e, 2)) - x(ct(e, 1)) <= cfg.maxSlope
                    idx(ct(e, 1):ct(e, 2)) = true;
                end

            end
        end
    end

end