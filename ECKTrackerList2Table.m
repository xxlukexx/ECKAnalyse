function list = ECKTrackerList2Table(tracker, listIdx)

    if exist('listIdx', 'var')
        % filter for only wanted list indices
        tracker.ListName = tracker.ListName(listIdx);
        tracker.ListValues = tracker.ListValues(listIdx);
        tracker.ListVarNames = tracker.ListVarNames(listIdx);
    end
    numLists = length(tracker.ListName);
    list = cell(numLists, 1);
    
    for l = 1:numLists
        list{l} = cell2table(tracker.ListValues{l}, 'VariableNames',...
            fixTableVariableNames(tracker.ListVarNames{l}));
    end
    
    if numLists == 1
        list = list{1};
    end

end