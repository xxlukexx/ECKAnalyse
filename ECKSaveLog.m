function suc = ECKSaveLog(logPath, logData, cmdEcho)
    
    suc = false;
    
    if ~exist('cmdEcho', 'var') || isempty(cmdEcho)
        cmdEcho = true;
    end

    if cmdEcho, fprintf('\n<strong>Saving experimental log files:</strong>\n\n'); end
    
    % check that some log data exists
    if size(logData.FunName,2)==0 
        warning('No data has been logged. Save failed.')
        return
    end

    numLogs = size(logData.FunName,2);
    
    % convert to Matlab table
    lg = ECKLog2Table(logData); 
    if numLogs == 1
        lg = {lg};
    end
    
    for curLog = 1:numLogs

        curName = logData.FunName{1,curLog};
        curTable = logData.Table{curLog};

%         tab = cell2table(curTable(2:end, :), 'VariableNames', curTable(1, :));
        curFile = strcat(logPath, '/', curName, '.csv');
%         csvwritecell(curFile, curTable, cmdEcho);
        writetable(lg{curLog}, curFile);

    end
    
    suc = true;

end