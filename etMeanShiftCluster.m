function out = etMeanShiftCluster(gaze, bandwidth)

    % remove missing
    missing                         = any(isnan(gaze), 2);
    gaze(missing, :)                = [];
    % get number of gaze points
    gNumPoints                      = size(gaze, 1);
    % cluster
    [cluster_centre, cluster_idx, cluster_members] =...
        HGMeanShiftCluster(gaze', bandwidth, 'gaussian');
    % validate clusters - must have > 1% of gaze samples
    clNumPoints                     = cellfun(@(x) size(x, 2), cluster_members);
    clPropPoints                    = clNumPoints ./ gNumPoints;
    clVal                           = clPropPoints >= 0.01;
    numClus                         = length(clVal);
    numValClus                      = sum(clVal);
    %store
    out.gaze                        = gaze;
    out.numGazePoints               = gNumPoints;
    out.numClusters                 = numClus;
    out.numValidClusters            = numValClus;
    out.cluster_centre              = cluster_centre;
    out.cluster_idx                 = cluster_idx;
    out.cluster_members             = cluster_members;
    out.cluster_validity            = clVal;
    out.cluster_propGaze            = clPropPoints;
    out.cluster_numGazePoints       = clNumPoints;
    
end