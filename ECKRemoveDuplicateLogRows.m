function lg = ECKRemoveDuplicateLogRows(lg)

    if ~isfield(lg, 'FunName')
        error('Invalid log format')
    end
    
    tmp = ECKLog2Table(lg);
    if ~iscell(tmp), tmp = {tmp}; end
    
    n = length(lg.FunName);
    for i = 1:n
        
        [has, idx] = findDuplicateTableRows(tmp{i});
        if has
            lg.Data{i}(idx, :) = [];
            lg.Table = [lg.Headings; lg.Data];
        end
        
    end
    
end
