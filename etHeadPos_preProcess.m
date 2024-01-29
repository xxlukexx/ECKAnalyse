function [suc, oc, x, y, z, bestSpanX, bestSpanY, bestSpanZ, duration] =...
    etHeadPos_preProcess(varargin)

%mb = [x, y, z] = ETHEADPOS_PREPROCESS(mb, tb) applies a standard set of
%preprocessing operations to head position data. mb is a TaskEngine main 
%main buffer, tb is a time buffer. The following operations are applied, in
%order:
%
%   1. Missing and monocular samples (where only one eye is visible) are
%   discarded (set to NaNs). 
%
%   2. Left and right eyes are averaged. 
%
%   3. Samples with a velocity change from the preceeding sample that
%   exceds a default criterion of 350 metres/sec are assumed to be noisy
%   outliers and are excluded. 
%
%   4. Data are cleaned using robust local regression estimation (rloess).
%   The span for the rloess algorithm is estimated from the data, by using
%   a range of spans from 7 to 30. For each span, 5% of the data is
%   partitioned, smoothed using rloess, and the sum of squared errors is
%   compared to the original data. The span with the lose SSE is used as
%   the best span. This is done idependently on the x, y and z axes, as
%   noisiness can vary between these axes. 
%
%mb = [x, y, z, bestSpanX, bestSpanY, bestSpanZ] =...
%   ETHEADPOS_PREPROCESS(mb, tb) also returns the best span value for each
%   of the axee. 
%
%mb = [x, y, z] = ETHEADPOS_PREPROCESS(file_in) loads data in TaskEngine
%preprocessed format found in file_in and proceeds as normal from here. Use
%this when running batch processes in parallel (e.g. using feval) to
%prevent from running out of memory. 
    
    % defaults
    suc = false;
    oc = 'unknown error';
    x = nan;
    y = nan;
    z = nan;
    bestSpanX = nan;
    bestSpanY = nan;
    bestSpanZ = nan;    
    duration = 0;
    
    tic
    
    try

        % check input args
        if nargin == 2
            % mb and tb
            mb = varargin{1};
            tb = varargin{2};
            parallelProcess = true;
        elseif nargin == 1
            % file path
            file_in = varargin{1};
            if ~exist(file_in, 'file')
                error('File %s not found.', file_in)
            end
            tmp = load(file_in);
            mb = tmp.data.MainBuffer;
            tb = tmp.data.TimeBuffer;
            clear tmp
            parallelProcess = false;        
            warning('Currently disabling parallel processing of spans when using file_in mode.')
        else
            suc = false; 
            oc = 'Input arguments must be either (mb, tb) or file_in - see help for more details.';
            return
        end
                
        % average eyes, remove missing
%         [mb, tb] = etPreprocess(mb, 'removemissing', true, 'binocularonly', true,...
%             'averageeyes', true, 'resampleFs', 30, 'timebuffer', tb);
        mb = etPreprocess(mb, 'removemissing', true, 'binocularonly', true,...
            'averageeyes', true);
        [mb, tb] = etResample(mb, tb, 30);
        
        % detect and remove duplicate timestamps
        [~, tb_i, ~] = unique(tb(:, 1));
        tb = tb(tb_i, :);
        mb = mb(tb_i, :);

        % extract head pos coords
        [x, y, z] = etHeadPos_getCoords(mb); 
        
        % check data quantity
        len_x = ~isnan(x);
        len_y = ~isnan(y);
        len_z = ~isnan(z);
        if sum(len_x) < 2 || sum(len_y) < 2 || sum(len_z) < 2
            suc = false;
            oc = 'valid data <2 samples';
        end

        % make time vector
        t = etTimeBuffer2Secs(tb);
        duration = t(end);

        % calculate intersample delta
        xd = delta(x);
        yd = delta(y);
        zd = delta(z);

        % find absolute outliers > 350 m/s, mark neighbouring samples
%         xol = growidx(abs(xd) > (700 / 1000), 1);
%         yol = growidx(abs(yd) > (700 / 1000), 1);
%         zol = growidx(abs(zd) > (700 / 1000), 1);   
%         xol = abs(xd) > (350 / 1000);
%         yol = abs(yd) > (350 / 1000);
%         zol = abs(zd) > (350 / 1000); 
%         x(xol) = nan;
%         y(yol) = nan;
%         z(zol) = nan;

        % smooth
        sr = etDetermineSampleRate(tb);
        interpMaxMs = 3000;
        interpMaxSamp = round((interpMaxMs / 1000) * sr);
    
        [x, bestSpanX] = cleanTimeSeries(t, x, 'plotResult', true, 'interpNaN', true,...
            'interpMax', interpMaxSamp, 'parallelProcess', parallelProcess);    
        [y, bestSpanY] = cleanTimeSeries(t, y, 'plotResult', true, 'interpNaN', true,...
            'interpMax', interpMaxSamp, 'parallelProcess', parallelProcess);    
        [z, bestSpanZ] = cleanTimeSeries(t, z, 'plotResult', true, 'interpNaN', true,...
            'interpMax', interpMaxSamp, 'parallelProcess', parallelProcess); 
        
        suc = true;
        oc = 'completed successfully';
        
    catch ERR

        suc = false;
        oc = ERR.message;
        
    end
    
end