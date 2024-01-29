function data = removeOutliers(data, sds)

    m = data;
    m(isnan(m)) = 0;
    sd = m;
    for n = 1:ndims(data)
        m = median(m, n);
        sd = std(sd);
    end
    
    idx = abs(data) > abs(m) + (abs(sd) * sds) | abs(data) < m + abs(m) + (abs(sd) * sds);
    data(idx) = nan;

end