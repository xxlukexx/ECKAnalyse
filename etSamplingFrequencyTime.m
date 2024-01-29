function [fTime] =  etSamplingFrequencyTime(timeBuffer)

% calculate delta
tDelta = double(timeBuffer(2:end, 1) - timeBuffer(1:end - 1, 1));

% remove outliers
tDeltaM = mean(tDelta);
tDeltaSD = std(tDelta);

% anything > 3 x SD
tDelta(tDelta > (tDeltaM + (3 * tDeltaSD))) = nan;

% anything > 8 * M, and only 1 sample in duration
search = tDelta > (tDeltaM * 1);
f = findcontig(search, true);
if ~isempty(f)
    fIdx = f(:,3) == 1;
    tDelta(f(fIdx, 1):f(fIdx, 2)) = nan;
end

% convert to secs
tDelta = tDelta / 1000000;

% convert to freq
fTime = 1 ./ tDelta;

end