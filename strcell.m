function [code] = strcell(in)

    numIdx = cellfun(@isnumeric, in);
    charIdx = cellfun(@ischar, in);
    otherIdx = ~numIdx & ~charIdx;
    
    code = repmat(cellstr(''), size(in, 1), size(in, 2));

    code(numIdx) = cellfun(@num2str, in(numIdx), 'un', 0);
    code(charIdx) = in(charIdx);
    code = strjoin(reshape(code, 1, []));
    
end