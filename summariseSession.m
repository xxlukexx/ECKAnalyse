function [table] = summariseSession(dataIn)
              
    % accept either a file path (char) or metadata (cell array) input
    if ischar(dataIn)
        % load data from participant folder
%         md = etLoadMetadata(dataIn, false);
        dc = ECKDataContainer(dataIn);
    else
        dc = checkDataIn(dataIn);
    end
    
    % check number of participants that have been loaded
    uPID = dc.Participants;
    if length(uPID) ~= 1
        fprintf(2, 'The folder you selected has multiple participants in it. Please select only one participant folder.\n')
        table = {};
        return
    end

    % get metadata
    numSes = dc.NumData;
    PID = dc.Data{1}.ParticipantID;
    TP = dc.Data{1}.TimePoint;
    
    % extract session time and dates
    dateTime = {};
    comp = {};
    for d = 1:numSes
        fullPath = dc.Data{d}.SessionPath;
        parts = strsplit(fullPath, filesep);
        try
            dateTimeNum = datenum(parts{end}, 'dd_mmm_yyyy HH.MM.SS');
            dateTime = [dateTime; datestr(dateTimeNum)];
        catch ERR
            dateTime = [dateTime; 'INVALID DATE'];
        end
        [tmp, ~] = etCompletenessSummary(dc.Data{d});
        comp = [comp; {tmp}];
    end

    % build table with ID, timepoint and session path
    md = dc.LegacyMetadata;
    table = [md(:, 1:2), md(:, 4), dateTime, comp];

end