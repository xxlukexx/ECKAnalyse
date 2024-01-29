function exclude = checkExcludeIn(exclude)
    
    % check exclude is a struct, error otherwise
    if ~isstruct(exclude)
        error('Invalid extruct format - expected struct.')
    end
    
    % check whether it has the correct fields, otherwise make them
    if ~isfield(exclude, 'ids')
        exclude.ids = {};
    end
%     
%     if ~isfield(exclude, 'in')
%         exclude.in = [];
%     end
    
    if ~isfield(exclude, 'reason')
        exclude.reason = {};
    end
    
end