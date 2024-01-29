function dataOut = etAverageEyes(data)

    % is input data a matrix of gaze data (main buffer), or an ECKData or
    % ECKDataContainer object?
    if isnumeric(data) && size(data, 2) >= 26 && size(data, 1) > 0
        numData = 1;
        type = 1;                   % 1 = mainBuffer, 2 = ECKData/Container
        mainBuffer = data;
    else
        dc = checkDataIn(data);
        numData = dc.NumData;
        type = 2;
    end

    % loop through datasets...
    for d = 1:numData

        % if data is ECKData/Container, get main buffer
        if type == 2, mainBuffer = dc.Data{d}.MainBuffer; end

        % average
        mainBuffer = etAverageEyeBuffer(mainBuffer);
        
        % store in DC (if necessary)
        if type == 2, dc.Data{d}.MainBuffer = mainBuffer; end

    end
    
    % if using a DC, make an output var
    switch type
        case 1
            dataOut = mainBuffer;
        case 2
            dataOut = dc;
    end

end