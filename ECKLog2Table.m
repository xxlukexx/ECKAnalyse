function [tab, tasks] = ECKLog2Table(lg, funName)

    % check to see if log data is a struct with just .Table and .FunName
    % fields, if so, recreate .Headings and .Data from .Table
    if isstruct(lg) && isfield(lg, 'FunName') && (~isfield(lg, 'Data') ||...
            ~isfield(lg, 'Headings'))
        lg.Headings = cellfun(@(x) x(1, :), lg.Table,...
            'UniformOutput', false);
        lg.Data = cellfun(@(x) x(2:end, :), lg.Table,...
            'UniformOutput', false);
    end
    
    if ~isstruct(lg) || ~isfield(lg, 'FunName') || ~isfield(lg, 'Data') ||...
            ~isfield(lg, 'Headings')
        error('Invalid log format.')
    end
    
    if ~exist('funName', 'var')
        funName = [];
    end
    
    % if function name has been specified, filter the log for just this
    % function
    if ~isempty(funName)
        idx = strcmp(lg.FunName, funName);
        if ~any(idx)
            error('Log %s not found', funName)
        else
            lg.FunName(~idx) = [];
            lg.Table(~idx) = [];
            lg.Headings(~idx) = [];
            lg.Data(~idx) = [];
        end
    end
    
    num = length(lg.FunName);
    tab = cell(num, 1);
    tasks = cell(num, 1);
    
    for l = 1:num
        hdr = fixTableVariableNames(lg.Headings{l});
%         hdr = cellfun(@matlab.lang.makeValidName, lg.Headings{l}, 'uniform', false);
        tab{l} = cell2table(lg.Data{l}, 'VariableNames', hdr);
        tasks{l} = lg.FunName{l};
    end
    
    if num == 1, tab = tab{:}; end
    
end