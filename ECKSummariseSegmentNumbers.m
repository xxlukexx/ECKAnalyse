function [labels, subjectCount, subjectIDs, idx] =...
    ECKSummariseSegmentNumbers(data)

    % Summarises segment additional data (.AddData) by number of subjects
    %
    % lables - unique list of labels found in the segments
    % subjectCount - the number of subjects with data for a particular
    % subjectIDs - list of IDs for each entry in labels
    
    dc = checkDataIn(data);
    
    %% get list of all add labels
    allHdr = {'DataSet', 'ID', 'TimePoint', 'Battery', 'Counterbalance',...
        'AddData'};
    allLabels = {};
    
    for d = 1:dc.NumData
    
        % loop through all segmentation jobs
        numJobs = length(dc.Data{d}.Segments);
        for j = 1:numJobs
            
            % loop through all segments
            numSegs = length(dc.Data{d}.Segments(j).Segment);
            for s = 1:numSegs
        
                allLabels(end + 1, :) = {...
                    d,...
                    dc.Data{d}.ParticipantID,...
                    dc.Data{d}.TimePoint,...
                    dc.Data{d}.Battery,...
                    dc.Data{d}.CounterBalance,...
                    dc.Data{d}.Segments(j).Segment(s).AddData{1, 2},...
                    };
                
            end
            
        end
        
    end
    
    % store unique labels
    [labels, ~, labelIdx]= unique(allLabels(:, 6));
    
    %% count by ID
    [ids, ~, idIdx] = unique(allLabels(:, 2));
    tmp = tabulate(labelIdx);
    subjectCount = [labels(tmp(:, 1)), num2cell(tmp(:, 2)),...
        num2cell(tmp(:, 2) ./ size(ids, 1) * 100)];
    
    
    %% list subject IDs
    
    warning('Listing subject IDs not implemented.')
    subjectIDs = [];
                    
end