function dataOut = ECKDuplicateData(dataIn)

    if ~isa(dataIn, 'ECKData')
        error('Must pass an ECKData instance to this function.')
    end
    
    dataOut = ECKData;
    dataOut.Type = dataIn.Type;
    dataOut.ParticipantID = dataIn.ParticipantID;
    dataOut.TimePoint = dataIn.TimePoint;
    dataOut.Battery = dataIn.Battery;
    dataOut.SessionPath = dataIn.SessionPath;
    dataOut.CounterBalance = dataIn.CounterBalance;
    dataOut.Site = dataIn.Site;
    dataOut.Tracker = dataIn.Tracker;
    dataOut.Log = dataIn.Log;
    dataOut.MainBuffer = dataIn.MainBuffer;
    dataOut.TimeBuffer = dataIn.TimeBuffer;
    dataOut.EventBuffer = dataIn.EventBuffer;
    dataOut.Loaded = dataIn.Loaded;

end