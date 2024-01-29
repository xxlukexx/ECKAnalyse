function val = ECKStruct2ECKData(in)
    val = ECKData;
    val.Type = 'ET';           % temporary - only support ET for now
    val.ParticipantID = in.ParticipantID;
    val.TimePoint = in.Schedule;
    val.Battery = in.Battery;
    val.CounterBalance = in.CounterBalance;
    val.Site = in.Site;
    val.Log = in.Log;
    if isfield(in, 'MainBuffer')
        val.MainBuffer = in.MainBuffer;
    end
    if isfield(in, 'TimeBuffer')
        val.TimeBuffer = in.TimeBuffer;
    end
    if isfield(in, 'EventBuffer')
        val.EventBuffer = in.EventBuffer;
    end
    if isfield(in, 'FixationBuffer')
        val.FixationBuffer = in.FixationBuffer;
    end
    if isfield(in, 'ExtraData')
        val.ExtraData = in.ExtraData;
    end
    if isfield(in, 'Segments')
        val.Segments.Segment = in.Segments;
        val.Segments.JobLabel = in.JobLabel;
    else
        val.Segments = [];
    end
end