function [grid] = etEventsToGrid(eventBuffer)
    
    if ~exist('eventBuffer', 'var')
        error('Must pass an event buffer to this function.')
    end
    
    if isempty(eventBuffer)
        fprintf('<EMPTY?>\n')
        varargout{1} = '';
        return
    end
    
    wb = waitbar(0, 'Processing events');
    
    % find max number of data cells
    cellIdx = cellfun(@iscell, eventBuffer(:, 3));
    maxCell = max(cell2mat(cellfun(@(x) size(x, 2),...
        eventBuffer(cellIdx, 3), 'uniform', 0)));

    % headers and timestamps
    grid = cell(size(eventBuffer, 1), 3 + maxCell);
    grid(:, 1:2) = eventBuffer(:, 1:2);
    
    % calculate elapsed time
    timeS = double((cell2mat(eventBuffer(:, 2))) - eventBuffer{1, 2}) / 1000000;
    secsInDay = 60 * 60 * 24;
    timeProp = timeS / secsInDay;
    grid(:, 3) = cellstr(datestr(timeProp, 'HH:MM:SS.FFF'));
    
    for e = 1:size(eventBuffer, 1)
                
        ev = eventBuffer{e, 3};
        if ischar(ev) || isnumeric(ev)
            grid{e, 4} = ev;
        elseif iscell(ev)
            grid(e, 4:4 + length(ev) - 1) = ev;
        else
            grid{e, 4} = '<UNKOWN DATA TYPE>';
        end  
    end
    
    wb = waitbar(.5, wb, 'Processing events');
    
    % remove nested grid data (cells with internal sizes > 1, 1) and
    % replace with string representation - to allow for use with uitable
    for r = 1:size(grid, 1)
        for c = 4:size(grid, 2)
            if isnumeric(grid{r, c}) && any(size(grid{r, c}) > 1)
                grid{r, c} = num2str(grid{r, c});
            end
        end
    end
       
    close(wb)

end
    