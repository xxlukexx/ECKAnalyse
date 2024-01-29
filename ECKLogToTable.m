function tab = ECKLogToTable(lg)

    if ~isstruct(lg) || ~isfield(lg, 'FunName') || ~isfield(lg, 'Data') ||...
            ~isfield(lg, 'Headings')
        error('Invalid log format.')
    end

    numLogs = length(lg.FunName);
    tab = cell(numLogs, 1);
    for l = 1:numLogs
        tab{l} = cell2table(lg.Data{l}, 'VariableNames',...
            fixTableVariableNames(lg.Headings{l}));
    end
    
    if length(tab) == 1
        tab = tab{1};
    end
    
end