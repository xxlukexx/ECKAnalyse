function [valOut] = combineParticipantTrialValidity(val1, val2)

    if size(val1) ~= size(val2)
        error('Validities cannot be combined unless both input arrays have the same shape.')
    end

    for curP = 1:lenght(val1)

end