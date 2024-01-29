function seg = etFilterSeg(seg, field, fun)

    idx = fun(seg.(field));
    fnames = fieldnames(seg);
    dontFilter = ismember(fnames, {'cfg', 'numIDs'});
    lens = structfun(@length, seg);
    dontFilter = dontFilter | lens ~= seg.numIDs;
    fnames(dontFilter) = [];
    for f = 1:length(fnames)
        seg.(fnames{f}) = seg.(fnames{f})(idx);
    end
    seg.numIDs = length(seg.(fnames{1}));
    
end