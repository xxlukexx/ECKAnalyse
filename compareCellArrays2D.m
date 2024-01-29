function [rowComp] = compareCellArrays2D(cellA, cellB)

    if all(size(cellA) ~= size(cellB))
        error('Cell arrays must be the same size.')
    end
    
    comp = zeros(size(cellA));
    
    for r = 1:size(cellA, 1)
        for c = 1:size(cellA, 2)
            

end