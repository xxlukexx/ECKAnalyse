function ECKFixSplitSessions(dataPath, hParent)

    posControls = [];
    posList = [];
    posSummaries = [];

    % check args
    ECKTitle('Fix split sessions')
    stat = ECKStatus('Starting up...');
    
    if ~exist('dataPath', 'var') || isempty(dataPath)        
        dataPath = uigetdir(pwd, 'Select data folder');
    end
    
    if isempty(dataPath)
        return
    end
    
    dc = checkDataIn(dataPath);
    dc.FilterDisableAll;
    
    if getData == 0, return, end

    % draw UI
    if ~exist('hParent', 'var') || isempty(hParent)

        fig = figure('NumberTitle','off',...
                    'Units', 'Normalized',...
                    'Menubar','none',...
                    'Toolbar','none',...
                    'Name', 'Fix Split Sessions',...
                    'renderer', 'opengl',...
                    'ResizeFcn', @resize,...
                    'Visible', 'off');
                                
    else
        
        fig = hParent;
        
    end
           
    sizeControls
    
    pnlControls = uipanel('Units', get(fig, 'Units'),...
        'Position', posControls,...
        'BorderType', 'none');
    
    lstList = uicontrol('Style', 'ListBox',...
        'Callback', @selection,...
        'Max', 20,...
        'Units', get(fig, 'Units'),...
        'Position', posList,...
        'Value', [],...
        'String', dc.Participants);     
    
    pnlSummaries = uipanel('Units', get(fig, 'Units'),...
        'Position', posSummaries,...
        'BorderType', 'none');
    
    set(fig, 'visible', 'on');
    
    function numFound = getData
        
        % get data, identify splits
        stat.Status = sprintf('Searching for data...\n');
        if isempty(dc), dc = ECKDataContainer(dataPath); end
        tab = dc.Table;
        pids = tab(:, 2);
        [~, ~, dupIdx] = unique(pids);
        isSplit = detectSplitSessions(dupIdx);
        uIdx = unique(dupIdx);

        if all(~isSplit)
            numFound = 0;
            fprintf('No split sessions detected.')
            warndlg('No split sessions found. This tool will now quit.')
            return
        end

        % filter md to just retain split sessions
        md = dc.LegacyMetadata;
        md = md(isSplit, :);
        numFound = size(md, 1);
        
    end
    
    function selection(hObject, eventdata, handles)
        
        set(fig, 'Pointer', 'watch');

        sel = get(hObject, 'value');
        if ~isempty(sel)
            
            % clear previous children
            ch = get(pnlSummaries, 'Children');
            delete(ch);
            
            dc.FilterDisableAll;
            pids = dc.Participants;
            dc.FilterValue('PARTICIPANTID', pids{sel});
            summaries = summariseSession(dc);
            if ~isempty(summaries)
                doSummarise(summaries, dc.LegacyMetadata);
            end
        end
        
        set(fig, 'Pointer', 'arrow');
        
    end

    function sizeControls
        
        % figure
        posFig = get(fig, 'Position');

        w = 1;
        h = 1;
        
        % controls
        hCont = .08;
        
        % list
        wList = .15;
        
        posControls = [0, 0, w, hCont];
        posList = [0, hCont, wList, h - hCont];
        posSummaries = [wList, hCont, w - wList, h - hCont];
    
    end

    function resize(hObject, eventdata, handles)

        sizeControls
        set(pnlControls, 'Position', posControls)
        set(lstList, 'Position', posList)
        set(pnlSummaries, 'Position', posSummaries)
        
    end

    function doSummarise(summaries, metaData)
        
         numSum = size(summaries, 1);
         set(pnlSummaries, 'Units', 'Normalized');

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
                'Parent', pnlSummaries,...
                'Units', 'Normalized',...
                'RowName', [],...
                'ColumnName', [],...
                'ColumnWidth', {110, 200},...
                'Position', metaPos);

            tasks(s) = uitable('Data', summaries{s, 5}(2:end, :),...
                'Parent', pnlSummaries,...
                'Units', 'Normalized',...
                'RowName', [],...
                'ColumnName', {'Task', 'Num Trials'},...
                'ColumnWidth', {110, 70},...
                'Position', taskPos);

            checks(s) = uicontrol('Style', 'ToggleButton',...
                'Units', 'Normalized',...
                'String', 'Select',...
                'Parent', pnlSummaries,...
                'Position', checkPos);
         end

         % draw control buttons
         combPos = [0, 0, .2, .05];
         delPos = [.2, 0, .2, .05];

         comb = uicontrol('Style', 'PushButton',...
            'Units', 'Normalized',...
            'String', 'Combine',...
            'Parent', pnlSummaries,...
            'Callback', {@doCombine, checks, summaries, metaData},...
            'Position', combPos);

         del = uicontrol('Style', 'PushButton',...
            'Units', 'Normalized',...
            'String', 'Delete',...
            'Parent', pnlSummaries,...
            'Callback', {@doDelete, checks},...
            'Position', delPos);
        
    end
    
    function doCombine(hObject, eventdata, checks, summaries, metaData)
    
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
            
            combineSession(summaries(val, :), metaData(val, :))
            
            % refresh
            getData
            
            % clear previous children
            ch = get(pnlSummaries, 'Children');
            delete(ch);
            
            % remove processed entry
            tmpEntries = get(lstList, 'String');
            tmpSel = get(lstList, 'Value');
            tmpEntries(tmpSel) = [];
            set(lstList, 'String', tmpEntries);
            dc.Data(:) = [];
            set(lstList, 'Value', []);

        end
        
    end

    function doDelete(hObject, eventdata, checks)
        
        % check that at least two sessions have been selected
        numCheckButtons = size(checks, 1);
        val = false(1, numCheckButtons);
        for s = 1:size(checks, 1)
            val(s) = get(checks(s), 'value');
        end
        numSel = sum(val);
               
        questStr = sprintf('Delete %s sessions?', num2str(numSel));
        resp = questdlg(questStr, 'Combine', 'Yes', 'No', 'Yes');
        if strcmpi(resp, 'yes')     
            
            % loop through and delete
            for f = 1:length(val)
                if val(f)
                    [suc, msg] = rmdir(dc.Data{f}.SessionPath, 's');
                end
            end
            
            % refresh
            getData
            
            % clear previous children
            ch = get(pnlSummaries, 'Children');
            delete(ch);
            
            % remove processed entry
            tmpEntries = get(lstList, 'String');
            tmpSel = get(lstList, 'Value');
            tmpEntries(tmpSel) = [];
            set(lstList, 'String', tmpEntries);
            dc.Data(:) = [];
            set(lstList, 'Value', []);
        
        end
        
    end

end

