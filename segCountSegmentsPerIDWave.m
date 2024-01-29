function [seg, sig] = segCountSegmentsPerIDWave(seg)
% counts unique ID x wave (time point) combinations, to identify individual
% sessions. Creates a new field in the seg struct, segNumber. For each
% occurrence of each id x wave combo, segNumber is incremented. Effectively
% this adds a trial/block number to each seg entry.

    sig = cellfun(@(id, tp) sprintf('%s#%s', id, tp), seg.ids,...
        seg.timePoints, 'UniformOutput', false);
    [u, i, s] = unique(sig);
    
    % loop through one sig at a time...
    seg.segNum = nan(1, seg.numIDs);
    for d = 1:length(i)

        % find indices of all matching sigs
        idx = find(s == d);
        
        for dd = 1:length(idx)
            seg.segNum(idx(dd)) = dd;
        end

    end

end