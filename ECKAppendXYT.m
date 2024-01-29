function data = ECKAppendXYT(data)
    
    numSegs = length(data.Segments);
    for s = 1:numSegs
        seg = data.Segments(s);
        [xy, t] = teConvertGaze(seg.MainBuffer, seg.TimeBuffer,...
            'tobiiAnalytics', 'xyt');
        data.Segments(s).x = xy(:, 1);
        data.Segments(s).y = xy(:, 2);
        data.Segments(s).t = t;
    end

end