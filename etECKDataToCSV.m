function etECKDataToCSV(data, filePath)

    dc = checkDataIn(data);
    numData = length(dc.Data);
    
    parfor d = 1:numData
    
        filename_gaze = [filePath, filesep, dc.Data{d}.ParticipantID, '_gazetime.csv'];
        filename_events = [filePath, filesep, dc.Data{d}.ParticipantID, '_events.csv'];

        ECKSaveETGazeTime(filename_gaze, dc.Data{d}.MainBuffer, dc.Data{d}.TimeBuffer);
        ECKSaveETEvents(filename_events, dc.Data{d}.EventBuffer);
        
    end

end