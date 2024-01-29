function [validCount, validProp, validIndex] = etCountValidSamples(data, inv)

% if no invalid data value is passed, assume -1
if ~exist('inv', 'var') || isempty(inv)
    inv = -1;
end

validIndex = data ~= inv;
validCount = sum(validIndex);
validProp = validCount / size(data, 1);

end