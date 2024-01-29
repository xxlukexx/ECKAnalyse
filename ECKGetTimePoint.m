function tp = ECKGetTimePoint(path_session)
    if ~isSessionFolder(path_session)
        tp = nan;
        return
    else
        try
            file = findFilename('tempData', path_session);
            tmp = load(file);
            col_tp = cellfun(@(x) strcmpi(x, 'TimePoint'), tmp.tempData.Headings, 'uniform', false);
            shortList = cellfun(@any, col_tp);
            if any(shortList)
                taskIdx = find(shortList, 1);
                col = col_tp{taskIdx};
                tp = tmp.tempData.Data{taskIdx}{1, col};
            else
                data = ECKData;
                data.Load(path_session);
                tp = data.TimePoint;
            end
        catch ERR
            tp = -1;
        end
    end
end