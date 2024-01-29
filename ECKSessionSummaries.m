function updateNeeded = ECKSessionSummaries(summaries, metaData, panel)

     updateNeeded = false;
    
     numSum = size(summaries, 1);
     set(panel, 'Units', 'Normalized');
     
     meta = zeros(numSum);
     tasks = zeros(numSum);
     checks = zeros(numSum);
     
     % loop through and draw summary controls for each session
     for s = 1:numSum
         
        x = (1 / numSum) * (s - 1);
        w = (1 / numSum);
        
        metaPos = [x, .85, w, .15];
        taskPos = [x, .1, w, .75];
        checkPos = [x, .05, w, .05];
        
        metaD = [{'ID', 'TimePoint', 'Path', 'Date/Time'}; summaries(s, 1:4)]';
        
        meta(s) = uitable('Data', metaD,...
            'Parent', panel,...
            'Units', 'Normalized',...
            'RowName', [],...
            'ColumnName', [],...
            'ColumnWidth', {110, 200},...
            'Position', metaPos);
        
        tasks(s) = uitable('Data', summaries{s, 5}(2:end, :),...
            'Parent', panel,...
            'Units', 'Normalized',...
            'RowName', [],...
            'ColumnName', {'Task', 'Num Trials'},...
            'ColumnWidth', {110, 70},...
            'Position', taskPos);
        
        checks(s) = uicontrol('Style', 'ToggleButton',...
            'Units', 'Normalized',...
            'String', 'Select',...
            'Parent', panel,...
            'Position', checkPos);
     end
     
     % draw control buttons
     combPos = [0, 0, .2, .05];
     delPos = [.2, 0, .2, .05];
     
     comb = uicontrol('Style', 'PushButton',...
        'Units', 'Normalized',...
        'String', 'Combine',...
        'Parent', panel,...
        'Callback', @doCombine,...
        'Position', combPos);
     
     del = uicontrol('Style', 'PushButton',...
        'Units', 'Normalized',...
        'String', 'Delete',...
        'Parent', panel,...
        'Callback', @doDelete,...
        'Position', delPos);
    
    function doCombine(hObject, eventdata, handles)
    
        % check that at least two sessions have been selected
        numCheckButtons = size(checks, 1);
        val = false(1, numCheckButtons);
        for s = 1:size(checks, 1)
            val(s) = get(checks(s), 'value');
        end
        numSel = sum(val);
        if numSel < 2
            errordlg('Must select at least two sessions to combine.')
        end
               
        questStr = sprintf('Combine %s sessions?', num2str(numSel));
        resp = questdlg(questStr, 'Combine', 'Yes', 'No', 'Yes');
        if strcmpi(resp, 'yes')
            updateNeeded = true;
            combineSession(summaries(val, :), metaData(val, :))
        end
        
    end

    function doDelete(hObject, eventdata, handles)
    end

end