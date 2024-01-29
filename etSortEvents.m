function [eventBufferOut] = etSortEvents(eventBuffer)
    
    if isempty(eventBuffer)
        warning('Event buffer empty, cannot sort.')
        eventBufferOut = eventBuffer;
    else
        [~, sortOrd] = sort(cell2mat(eventBuffer(:, 2)));
        eventBufferOut = eventBuffer(sortOrd, :);
    end
    
end