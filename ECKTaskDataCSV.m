function ECKTaskDataCSV(data, taskName, fileName)

    dc = checkDataIn(data);
    
    [hdr, dta] = etCollateTask(dc, taskName);
    
    if isempty(hdr)
        fprintf('Task not found. Available tasks are:\n\n')
        disp(etListTasks(dc));
        return
    end
    
    if isempty(dta)
        fprintf('Task found, but no data returned.\n')
        return
    end
    
    % write to Excel if possible, otherwise to csv
    [pth, fil, ext] = fileparts(fileName);
    format = ext(2:end);
    try
        test = table;
        clear test
    catch ERR
        if strcmpi(ERR.message, 'Undefined function or variable ''table''.')
            format = 'csv';
        else 
            rethrow ERR
        end
    end
    
    switch format
        case 'csv'
%             fileName = fullfile(pth, [fileName, '.csv']);
            csvwritecell(fileName, [hdr; dta]);
        case 'xlsx'
            hdr = fixTableVariableNames(hdr);
            tab = cell2table(dta, 'variablenames', hdr);
            fileName = fullfile(pth, [fil, '.xlsx']);
            writetable(tab, fileName)
    end
    
end