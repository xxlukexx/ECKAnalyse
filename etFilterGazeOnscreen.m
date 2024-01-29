function [dataOut] = etFilterGazeOnscreen(data)

    % is input data a matrix of gaze data (main buffer), or an ECKData or
    % ECKDataContainer object?
    if isnumeric(data) && size(data, 2) >= 26 
        numData = 1;
        type = 1;                   % 1 = mainBuffer, 2 = ECKData/Container
        mb = data;
    else
        dc = checkDataIn(data);
        numData = dc.NumData;
        type = 2;
    end

    % loop through datasets...
    for d = 1:numData

        % if data is ECKData/Container, get main buffer
        if type == 2, mb = dc.Data{d}.MainBuffer; end
        
        mb(mb(:, 7) < 0 | mb(:, 7) > 1, 7) = nan;
        mb(mb(:, 8) < 0 | mb(:, 8) > 1, 8) = nan;
        mb(mb(:, 20) < 0 | mb(:, 20) > 1, 20) = nan;
        mb(mb(:, 21) < 0 | mb(:, 21) > 1, 21) = nan;
        mb(mb(:, 12) == -1, 12) = nan;
        mb(mb(:, 25) == -1, 25) = nan;

        if type == 2, dc.Data{d}.MainBuffer = mb; end

    end
    
    % if using a DC, make an output var
    switch type
        case 1
            dataOut = mb;
        case 2
            dataOut = dc;
    end

end