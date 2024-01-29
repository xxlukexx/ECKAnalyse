function mainBufferOut = etSmoothBuffer(mainBuffer, windowWidth, method)

    if ~exist('windowWidth', 'var') || isempty(windowWidth)
        windowWidth = 5;
    end
    
    if ~exist('method', 'var') || isempty(method)
        method = @medfilt1;
    else
        method = @smooth;
    end

    mainBufferOut = mainBuffer;
    
%     mainBufferOut(:, 7) = medfilt1(mainBuffer(:, 7), windowWidth);
%     mainBufferOut(:, 8) = medfilt1(mainBuffer(:, 8), windowWidth);
%     mainBufferOut(:, 20) = medfilt1(mainBuffer(:, 20), windowWidth);
%     mainBufferOut(:, 21) = medfilt1(mainBuffer(:, 21), windowWidth);
%     mainBufferOut(:, 12) = medfilt1(mainBuffer(:, 12), windowWidth);
%     mainBufferOut(:, 25) = medfilt1(mainBuffer(:, 25), windowWidth);
    
    mainBufferOut(:, 7) = feval(method, mainBuffer(:, 7), windowWidth);
    mainBufferOut(:, 8) = feval(method, mainBuffer(:, 8), windowWidth);
    mainBufferOut(:, 20) = feval(method, mainBuffer(:, 20), windowWidth);
    mainBufferOut(:, 21) = feval(method, mainBuffer(:, 21), windowWidth);
    mainBufferOut(:, 12) = feval(method, mainBuffer(:, 12), windowWidth);
    mainBufferOut(:, 25) = feval(method, mainBuffer(:, 25), windowWidth);
    
end