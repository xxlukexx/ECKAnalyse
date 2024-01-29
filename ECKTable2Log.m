function lg = ECKTable2Log(tab, funName)

    if ~exist('tab', 'var') || isempty(tab)
        error('Must supply a log-as-a-table or cell array of logs-as-a-table')
    end
    
    if ~exist('funName', 'var') || isempty(funName)
        error('Must supply function name or names.')
    end

    if ~iscell(tab)
        tab = {tab};
    end
    if ~iscell(funName)
        funName = {funName};
    end
    
    numLogs = length(tab);
    
    if length(funName) ~= numLogs
        error('Must supply one function name for each log.')
    end
    
    lg = struct;
    lg.FunName = funName;
    for i = 1:numLogs
        lg.Headings{i} = tab{i}.Properties.VariableNames;
        lg.Data{i} = table2cell(tab{i});
        lg.Table{i} = [lg.Headings{i}; lg.Data{i}];
    end
    
end