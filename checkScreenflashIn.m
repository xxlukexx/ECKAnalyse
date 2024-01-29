function [sf, result] = checkScreenflashIn(sfIn)

    sf = []; result = [];
    
    % if sf is a char, treat it as a path and try to load sf data, if it is
    % a struct, assume it is the sf data itself
    if ischar(sfIn)
        if exist(sfIn, 'file')
            sf = load(sfIn);
        else
            result =...
                'sf argument was a char but not a valid path to a .mat file.';
        end
    elseif isstruct(sfIn)
        if ~isfield(sfIn, 'sfTime') || ~isfield(sfIn, 'sfFrame')
            result = 'A struct was loaded but did not contain sf fields.';
        else
            sf = sfIn;
        end
    else
        result = 'sf argument was not char or valid sf struct';
    end    

end