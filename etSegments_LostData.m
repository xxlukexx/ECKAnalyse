function propLost = etSegments_LostData(data)

    dc = checkDataIn(data);

    % get number of segments
    numSegs = zeros(dc.NumData, 1);
    for d = 1:dc.NumData
        numSegs(d) = dc.Data{d}.NumSegments;
    end  
    maxSegs = max(numSegs);
    
    % read off prop lost data for each ID, and for each seg
    propLost = nan(dc.NumData, maxSegs);
    for d = 1:dc.NumData
        for s = 1:dc.Data{d}.NumSegments
            mb = dc.Data{d}.Segments{s}.MainBuffer;
            lostSeries = ...   
                mb(:, 7) == -1 | isnan(mb(:, 7)) &...
                mb(:, 8) == -1 | isnan(mb(:, 8)) &...
                mb(:, 20) == -1 | isnan(mb(:, 2)) &...
                mb(:, 21) == -1 | isnan(mb(:, 21));
            propLost(d, s) = sum(lostSeries) / length(lostSeries);
        end
    end     

end