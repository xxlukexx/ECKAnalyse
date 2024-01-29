function [eventOut] = etTimeToEvent(eventBuffer, timeStamp)

if isempty(eventBuffer), eventOut = {}; return, end

eventOut = zeros(size(timeStamp));
eventTimes = uint64(cell2mat(eventBuffer(:, 2)));

    for curRow = 1:size(timeStamp, 1)

        for curCol = 1:size(timeStamp, 2)

            if uint64(timeStamp) > eventTimes(end, 1)
                eventOut(curRow, curCol) = size(eventTimes, 1);
            else
                eventOut(curRow, curCol) = find(eventTimes(:,1) >=...
                    timeStamp(curRow, curCol), 1,'first');
            end

        end

    end

end