function [gazeChunk, timeChunk, eventChunk, s1, s2] = etGetGazeByTime(...
    mainBuffer, timeBuffer, eventBuffer, startTime, endTime)

    s1              =   etTimeToSample(timeBuffer, startTime);
    s2              =   etTimeToSample(timeBuffer, endTime);

    e1              =   etTimeToEvent(eventBuffer, startTime);
    e2              =   etTimeToEvent(eventBuffer, endTime);

    gazeChunk = {[]};
    timeChunk = {[]};
    eventChunk = {[]};
    
    for curSeg = 1:size(s1, 1)

        gazeChunk{curSeg} =   mainBuffer(s1(curSeg):s2(curSeg), :);
        timeChunk{curSeg} =   timeBuffer(s1(curSeg):s2(curSeg), :);
        if ~isempty(eventBuffer)
            eventChunk{curSeg}=   eventBuffer(e1(curSeg):e2(curSeg), :);
        end

    end

end