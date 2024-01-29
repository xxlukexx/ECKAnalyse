function [sampleOut] = etTimeToSample(timeBuffer, timeStamp)

% remove any trailing zeros from the timeBuffer
if timeBuffer(end, 1) == 0, timeBuffer = timeBuffer(1:end - 1, :); end

sampleOut = zeros(size(timeStamp));

    for curRow = 1:size(timeStamp, 1)

        for curCol = 1:size(timeStamp, 2)

            if uint64(timeStamp) > timeBuffer(end, 1)
                sampleOut(curRow, curCol) = size(timeBuffer, 1);
            else
                sampleOut(curRow, curCol) = find(timeBuffer(:,1) >=...
                    timeStamp(curRow, curCol), 1,'first');
            end

        end

    end

end