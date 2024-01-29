function [bufferOut] = etCombineSortEvents(buffersIn)

    if ~iscell(buffersIn) || size(buffersIn, 1) > 1
        error('Event buffers must be passed as a single-row cell array.')
    end
    
    bufferOut = [];
    
    for b = 1:size(buffersIn, 2)
        if ~isempty(buffersIn{b})
            switch isempty(bufferOut)
                case true
                    bufferOut = buffersIn{b};
                case false
                    bufferOut = [bufferOut; buffersIn{b}];
            end
        end
    end
    
    if ~isempty(bufferOut)
        
        % remove any non-int64s
        idx = cellfun(@(x) ~isa(x, 'int64') & ~isa(x, 'uint64'), bufferOut(:, 1));
        bufferOut(idx, :) = [];

        [~, reOrder] = sort(cell2mat(bufferOut(:, 2)));
        bufferOut = bufferOut(reOrder, :);
        
    end

end