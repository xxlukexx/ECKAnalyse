function [varargout] = etAverageEyeBuffer(mainBuffer)

    mainBufferOut = mainBuffer;
    
    % extract x, y, pupil data for L and R eyes
    lx = mainBuffer(:, 7);
    ly = mainBuffer(:, 8);
    rx = mainBuffer(:, 20);
    ry = mainBuffer(:, 21);
    lp = mainBuffer(:, 12);
    rp = mainBuffer(:, 25);
    
    % find missing data for each
    lx_nan = isnan(lx);
    ly_nan = isnan(ly);
    rx_nan = isnan(rx);
    ry_nan = isnan(ry);
    lp_nan = isnan(lp);
    rp_nan = isnan(rp);
    
    % find missing data in one eye that can be replaced with present data
    % for the sample samples in the other eye
    lx_miss = lx_nan & ~rx_nan;
    rx_miss = rx_nan & ~lx_nan;
    ly_miss = ly_nan & ~ry_nan;
    ry_miss = ry_nan & ~ly_nan;
    lp_miss = lp_nan & ~rp_nan;
    rp_miss = rp_nan & ~lp_nan;    
    
    % replace where possible
    lx(lx_miss) = rx(lx_miss);
    rx(rx_miss) = lx(rx_miss);
    ly(ly_miss) = ry(ly_miss);
    ry(ry_miss) = ly(ry_miss);
    lp(lp_miss) = rp(lp_miss);
    rp(rp_miss) = lp(rp_miss);
    
    % average everywhere else
    x = mean([lx, rx], 2);
    y = mean([ly, ry], 2);
    p = mean([lp, rp], 2);  

    mainBufferOut(:, [7, 20]) = repmat(x, 1, 2);
    mainBufferOut(:, [8, 21]) = repmat(y, 1, 2);
    mainBufferOut(:, [12, 25]) = repmat(p, 1, 2);
    
    if nargout == 1
        % return whole buffer
        varargout = {mainBufferOut};
    elseif nargout == 3
        % return x, y, pupil
        varargout = {x, y, p};
    end
    
end