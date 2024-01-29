function [x, y, z, bestSpanX, bestSpanY, bestSpanZ] =...
    etHeadPos_preProcess_par(file_in)

    tmp = load(file_in);
    mb = tmp.data.MainBuffer;
    tb = tmp.data.TimeBuffer;
    parallelProcess = false;
    
    [x, y, z, bestSpanX, bestSpanY, bestSpanZ] = etHeadPos_preProcess(mb, tb);

   % average eyes, remove missing
    mb = etPreprocess(mb, 'removemissing', true, 'binocularonly', true,...
        'averageeyes', true);
    
    % extract head pos coords
    [x, y, z] = etHeadPos_getCoords(mb); 
    
    % make time vector
    t = etTimeBuffer2Secs(tb);
    
    % calculate intersample delta
    xd = delta(x);
    yd = delta(y);
    zd = delta(z);
    
    % find absolute outliers > 350 m/s, mark neighbouring samples
    xol = growidx(abs(xd) > (350 / 1000), 1);
    yol = growidx(abs(yd) > (350 / 1000), 1);
    zol = growidx(abs(zd) > (350 / 1000), 1);
    
    x(xol) = nan;
    y(yol) = nan;
    z(zol) = nan;

    % smooth
    sr = etDetermineSampleRate(tb);
    interpMaxMs = 1000;
    interpMaxSamp = round((interpMaxMs / 1000) * sr);
    
    [x, bestSpanX] = cleanTimeSeries(t, x, 'plotResult', false, 'interpNaN', true,...
        'interpMax', interpMaxSamp, 'parallelProcess', false);    
    [y, bestSpanY] = cleanTimeSeries(t, y, 'plotResult', false, 'interpNaN', true,...
        'interpMax', interpMaxSamp, 'parallelProcess', false);    
    [z, bestSpanZ] = cleanTimeSeries(t, z, 'plotResult', false, 'interpNaN', true,...
        'interpMax', interpMaxSamp, 'parallelProcess', false);    

end