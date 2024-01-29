function ECKEventViewer(data, hParent)
    
    %% INIT VARS
    evSel = [];             % selection of events
    tabSel = [];            % selection of uitable cells
    lnkEvSel = [];          % selection of events in lstEvents
    lnkTaskSel = [];        % selection of tasks in lstTasks
    linksLoaded = false;    % saved links file loaded?
    links = {};             % cell array to store links
    linksDirty = false;     % flag to determine if links need saving
    
    %% DATA
    
    % check data
    dc = checkDataIn(data);
    numData = length(dc.Data);
    if ~dc.Data{1}.GazeLoaded
        gazeWasLoaded = true;
        dc.Data{1}.LoadGaze;
    else
        gazeWasLoaded = false;
    end

    % get list of tasks
    tasks = sort(dc.Tasks);

    % put event buffer into a grid that can be displayed by a uitable
    grid = etEventsToGrid(dc.Data{1}.EventBuffer);
    evSel = false(size(grid, 1), 1);
    
    % make empty column for links to tasks
    grid = [grid, cell(size(grid, 1), 1)];
    
    % colour code events
    [gridCol, maxLen] = etColourCodeEventsGrid(grid, evSel); 
    
    % make column headers (can differ due to interderminate number of data
    % cells)
    colHdrs = {'Local Time', 'Remote Time', 'Elapsed', 'Label'};
    numDataCells = size(gridCol, 2) - 5;
    if numDataCells > 0
        colHdrs = [colHdrs, repmat({'Data'}, [1, numDataCells])];
    end
    colHdrs = [colHdrs, 'Linked Task'];
    maxLen(end) = 10;
    
    % store total number of columns
    numCols = size(gridCol, 2);

    %% UI
    
    % if a parent handle (to e.g. figure, panel etc.) has not been
    % supplied, make a figure
    if ~exist('hParent', 'var') || isempty(hParent)
        fig = figure('NumberTitle','off',...
                    'Units', 'Normalized',...
                   'Menubar','none',...
                   'Toolbar','none',...
                   'Name', 'Event Viewer',...
                   'renderer', 'opengl');
    else
        fig = hParent;
    end
    
    % default height of a button
    btnHeight              =   1;
    
    % datasets list
    posLstDatasets          =   [0, 0, .2, .8];
    
    % events table
    posTabEvents            =   [0, .05, .8, .95];
    
    % events controls
    posPnlControls          =   [0, 0, .8, .05];
    eventsNumBtn            =   6;       
    eventsBtnW              =   1 / eventsNumBtn;
    posBtnSelectAll         =   [eventsBtnW * 0, 1 - btnHeight, eventsBtnW, btnHeight];
    posBtnSelectNone        =   [eventsBtnW * 1, 1 - btnHeight, eventsBtnW, btnHeight];
    posBtnSelectMatch       =   [eventsBtnW * 2, 1 - btnHeight, eventsBtnW, btnHeight];
    posBtnSelectPrefix      =   [eventsBtnW * 3, 1 - btnHeight, eventsBtnW, btnHeight];
    posBtnSelectPair        =   [eventsBtnW * 4, 1 - btnHeight, eventsBtnW, btnHeight];
    posBtnSelectAllPairs    =   [eventsBtnW * 5, 1 - btnHeight, eventsBtnW, btnHeight];
    
    % tasks panel 
    posPnlTasks             =   [.8, 0, .2, 1];
    posLstTasks             =   [0, .6, 1, .4];
    posLstEvents            =   [0, .2, 1, .4];
    
    % tasks controls
    posPnlTaskControls      =   [0, 0, 1, .2];
    taskControlsBtnRows     =   6;       
    taskControlsBtnCols     =   2;
    taskControlsBtnW        =   1 / taskControlsBtnCols;
    taskControlsBtnH        =   1 / taskControlsBtnRows;
    posBtnLoadLink          =   [taskControlsBtnW * 0, 1 - (taskControlsBtnH * 1), taskControlsBtnW, taskControlsBtnH];
    posBtnSaveLink          =   [taskControlsBtnW * 1, 1 - (taskControlsBtnH * 1), taskControlsBtnW, taskControlsBtnH];
    posBtnLink              =   [taskControlsBtnW * 0, 1 - (taskControlsBtnH * 2), taskControlsBtnW, taskControlsBtnH];
    posBtnUnlink             =   [taskControlsBtnW * 1, 1 - (taskControlsBtnH * 2), taskControlsBtnW, taskControlsBtnH];
    
    % event table
    tabEvents = uitable('Data', gridCol,...
        'CellSelectionCallback', @tabEvents_Select,... 
        'Parent', fig,...
        'Units', 'Normalized',...
        'RowName', [],...
        'ColumnName', colHdrs,...
        'ColumnWidth', num2cell(maxLen * 7),...
        'Position', posTabEvents);
    jSPTabEvents = findjobj(tabEvents);
    jTabEvents = jSPTabEvents.getViewport.getView;
    jTabEventsUpdating = false;
    
    % events controls
    pnlControls = uipanel('parent', fig,...
        'Units', 'normalized',...
        'Position', posPnlControls);
    
    btnSelectAll = uicontrol('parent', pnlControls,...
        'Style', 'PushButton',...
        'Units', 'normalized',...
        'Position', posBtnSelectAll,...
        'Callback', @btnSelectAll_Click,...
        'String', 'Select All');
    
    btnSelectNone = uicontrol('parent', pnlControls,...
        'Style', 'PushButton',...
        'Units', 'normalized',...
        'Position', posBtnSelectNone,...
        'Callback', @btnSelectNone_Click,...
        'String', 'Select None');
    
    btnSelectMatch = uicontrol('parent', pnlControls,...
        'Style', 'PushButton',...
        'Units', 'normalized',...
        'Position', posBtnSelectMatch,...
        'Callback', @btnSelectMatch_Click,...
        'Enable', 'off',...
        'String', 'Select Match');
    
    btnSelectPrefix = uicontrol('parent', pnlControls,...
        'Style', 'PushButton',...
        'Units', 'normalized',...
        'Position', posBtnSelectPrefix,...
        'Callback', @btnSelectPrefix_Click,...
        'Enable', 'off',...
        'String', 'Select Prefix');
    
    btnSelectPair = uicontrol('parent', pnlControls,...
        'Style', 'PushButton',...
        'Units', 'normalized',...
        'Position', posBtnSelectPair,...
        'Callback', @btnSelectPair_Click,...
        'Enable', 'off',...
        'String', 'Select Pairs');
    
    btnSelectAllPairs = uicontrol('parent', pnlControls,...
        'Style', 'PushButton',...
        'Units', 'normalized',...
        'Position', posBtnSelectAllPairs,...
        'Callback', @btnSelectAllPairs_Click,...
        'Enable', 'off',...
        'String', 'Select All Pairs');
    
    % tasks panel
    pnlTasks = uipanel('parent', fig,...
        'Units', 'normalized',...
        'Position', posPnlTasks);
    
    lstTasks = uicontrol('Style', 'ListBox',...
        'Parent', pnlTasks,...
        'Callback', @lstTasks_Select,...
        'Max', 20,...
        'Units', get(fig, 'Units'),...
        'Position', posLstTasks,...
        'FontS', 12,...
        'Value', [],...
        'String', tasks);  
    
    lstEvents = uicontrol('Style', 'ListBox',...
        'Parent', pnlTasks,...
        'Callback', @lstEvents_Select,...
        'Max', 20,...
        'Units', get(fig, 'Units'),...
        'Position', posLstEvents,...
        'FontS', 12,...
        'Enable', 'off',...
        'Value', [],...
        'String', '<No links loaded>'); 
    
    pnlTaskControls = uipanel('parent', pnlTasks,...
        'Units', 'normalized',...
        'Position', posPnlTaskControls);
    
    btnLoadLink = uicontrol('parent', pnlTaskControls,...
        'Style', 'PushButton',...
        'Units', 'normalized',...
        'Position', posBtnLoadLink,...
        'Callback', @btnLoadLink_Click,...
        'Enable', 'on',...
        'String', 'Load Links');
    
    btnSaveLink = uicontrol('parent', pnlTaskControls,...
        'Style', 'PushButton',...
        'Units', 'normalized',...
        'Position', posBtnSaveLink,...
        'Callback', @btnSaveLink_Click,...
        'Enable', 'off',...
        'String', 'Save Links');
    
    btnLink = uicontrol('parent', pnlTaskControls,...
        'Style', 'PushButton',...
        'Units', 'normalized',...
        'Position', posBtnLink,...
        'Callback', @btnLink_Click,...
        'Enable', 'off',...
        'String', '=> Link');
    
    btnUnlink = uicontrol('parent', pnlTaskControls,...
        'Style', 'PushButton',...
        'Units', 'normalized',...
        'Position', posBtnUnlink,...
        'Callback', @btnUnlink_Click,...
        'Enable', 'off',...
        'String', '<= Unlink');
    
    function lstTasks_Select(h, dat)
        
        lnkTaskSel = get(h, 'Value');
        updateLinks
        updateButtons
        
    end

    function tabEvents_Select(h, dat)
        
        tabSel = dat.Indices(:, 1);
        updateButtons
        
    end

    function btnSelectAll_Click(h, dat)
        
        evSel = true(size(grid, 1), 1);
        updateTable

    end

    function btnSelectNone_Click(h, dat)
        
        selectNone

    end

    function btnSelectMatch_Click(h, dat)
        
        if ~isempty(tabSel)
            
            % find events that match the currently selected event
            numSel = length(tabSel);
            found = [];
            for s = 1:numSel
                found = [found; find(strcmp(grid(:, 4), grid{tabSel(s), 4}))];
            end
            
            evSel(found) = true;
            updateTable
                       
        end
            
    end

    function btnSelectPrefix_Click(h, dat)
        
       if ~isempty(tabSel)
           
            % get event prefixes (e.g. GAP_XXX)
            selLab = etEventGridPrefixes(grid(tabSel, 4));
            [uLab, labIdx] = etEventGridPrefixes(grid(:, 4));

            % match selected event prefix to all prefixes
            numSel = length(selLab);
            found = [];
            for s = 1:numSel
                
                labMatch = find(strcmpi(uLab, selLab{s}));
                idxMatch = labIdx == labMatch;
                
                found = [found; find(idxMatch)];
                
            end
                           
            evSel(found) = true;
            updateTable
                       
       end
        
    end

    function lstEvents_Select(h, dat)
        
        lnkEvSel = get(h, 'Value');
        updateButtons
        
    end

    function btnLink_Click(h, dat)
        
        % collect grid-based and event-based selections
        sel = evSel;
        sel(tabSel) = true;
        
        if ~isempty(sel) && any(sel)
            
            numSel = sum(sel);
            eventsToLink = unique(grid(sel, 4));
            taskRep = repmat(tasks{lnkTaskSel}, [length(eventsToLink), 1]);
            links = [links; cellstr(taskRep), eventsToLink];
            removeDuplicateLinks
            updateLinks
            selectNone
            linksDirty = true;
            if ~linksLoaded, linksLoaded = true; end
            
        end
        
    end

    function btnUnlink_Click(h, dat)
        
        curTaskEvents = getSelLinkedEvents(lnkTaskSel);
        lstIdx = get(lstEvents, 'value');
        if ~isempty(lstIdx)
            linksToDelete = curTaskEvents(lstIdx);
            links(linksToDelete, :) = [];
            set(lstEvents, 'value', []);
            updateLinks
            updateButtons
            linksDirty = true;
        end
        
        
    end

    function btnLoadLink_Click(h, dat)
        
        loadLinks
        
    end

    function btnSaveLink_Click(h, dat)
        
        saveLinks
        
    end

    function updateTable
        
        % record current scrollbar pos
        caretPos = jSPTabEvents.getVerticalScrollBar.getValue;

        % colour code events
        gridCol = etColourCodeEventsGrid(grid, evSel); 
        
        % append links to tasks 
        for lnk = 1:size(links, 1)
            found = find(strcmpi(grid(:, 4), links{lnk, 2}));
            if ~isempty(found)
                
                str = [...
                    '<html><table border=0><TR><TC><TD width=100 bgcolor=#FFF380',...
                    '>', links{lnk, 1},...
                    '</TD></TC></TR></table></html>'];
            
                grid(found, end) = cellstr(repmat(str, [length(found), 1]));
                
            end
        end
        
        % update contents of table
        set(tabEvents, 'Data', gridCol);
        updateButtons
        
        % set scrollbar pos back 
        pause(.2)
        jSPTabEvents.getVerticalScrollBar.setValue(caretPos);
        
    end

    function updateButtons
        
        set(btnSelectAll, 'Enable', 'on');

        % enable buttons based on grid selection
        if isempty(tabSel)
            % if nothing is selected
            set(btnSelectMatch, 'Enable', 'off');
            set(btnSelectPrefix, 'Enable', 'off');
            set(btnSelectPair, 'Enable', 'off');
            set(btnSelectAllPairs, 'Enable', 'off');
        else
            set(btnSelectNone, 'Enable', 'on');
            set(btnSelectMatch, 'Enable', 'on');
            set(btnSelectPrefix, 'Enable', 'on');
            set(btnSelectPair, 'Enable', 'on');
            set(btnSelectAllPairs, 'Enable', 'on');
        end
        
        % enable buttons based on event selection
        if isempty(evSel) || all(~evSel)
            % if no events are selected
            set(btnSelectNone, 'Enable', 'off');
        else
            set(btnSelectNone, 'Enable', 'on');
        end
        
        % enable buttons based on either, AND a task being selected in
        % lstTasks
        if (~isempty(evSel) && any(evSel)) ||...
                ~isempty(tabSel) &&...
                ~isempty(lnkTaskSel)
                
            % if one or other is selected
            set(btnLink, 'Enable', 'on');
        else
            set(btnLink, 'Enable', 'off');
        end
        
        % enabled buttons based on lstEvents (link) list
        if isempty(lnkEvSel)
            % no events selected
            set(btnUnlink, 'Enable', 'off');
        else
            set(btnUnlink, 'Enable', 'on');
        end
        
        % save button
        if linksDirty
            set(btnSaveLink, 'Enable', 'on');
        else
            set(btnSaveLink, 'Enable', 'on');
        end
        
    end

    function updateLinks
        
        % disable lstEvents if no links exist
        if ~linksLoaded && isempty(links)
            set(lstEvents, 'String', '<no links loaded>');
            set(lstEvents, 'Enable', 'off');
            return
        end
        
        % display linked events in lstEvents, by reference to selected task
        % in lstTasks
        if ~isempty(lnkTaskSel)
            
            found = getSelLinkedEvents(lnkTaskSel);
            
            if ~isempty(found)
                set(lstEvents, 'String', links(found, 2));
                set(lstEvents, 'Enable', 'on');
            else
                set(lstEvents, 'String', '<none>');
                set(lstEvents, 'Enable', 'off');
            end
            
        else
            
            set(lstEvents, 'String', '<no tasks selected>');
            set(lstEvents, 'Enable', 'off');
            
        end
        
%         % append linked tasks to events table
%         for lnk = 1:size(links, 1)
%             found = find(strcmpi(grid(:, 4), links{lnk, 2}));
%             if ~isempty(found)
%                 grid(found, end) = cellstr(repmat(links{lnk, 1}, [length(found), 1]));
%             end
%         end
        updateTable
            
    end

    function removeDuplicateLinks
       
        newLinks = {};
        [uTasks, ~, uTaskIdx] = unique(links(:, 1));
        t = 1;
        
        while t <= length(uTasks)
            uEvents = unique(links(uTaskIdx == t, 2));
            repData = repmat(uTasks{t}, [length(uEvents), 1]);
            newLinks = [newLinks; cellstr(repData), uEvents];            
            t = t + 1;
        end
        
        links = newLinks;
            
    end

    function selectNone
        
        evSel = false(size(grid, 1), 1);
        updateTable
        
    end

    function evSelIdx = getSelLinkedEvents(taskSelIdx)

        % find linked events based on currently selected task
        selTask = tasks{lnkTaskSel};

        % find matching linked events (if any)
        evSelIdx = find(strcmpi(links(:, 1), selTask));
    
    end

    function loadLinks
        
        % prompt to save changes if necessary
        if linksDirty
            switch questdlg('Do you wish to save changes?')
                case 'Yes'
                    saveLinks
                case 'Cancel'
                    return
            end
        end
        
        % dialog
        [filename, pathname] = uigetfile('*.mat', 'Load');
        
        % deal with cancelled dialog
        if isnumeric(filename) && filename == 0
            return
        end
        
        % load 
        tmp = load(fullfile(pathname, filename));
        
        % check valid file
        if isfield(tmp, 'links') && iscell(tmp.links)
            links = tmp.links;
            updateTable
            updateButtons
            updateLinks
            linksDirty = false;
            linksLoaded = true;
        else
            errordlg('Not a valid links file.')
        end 
        
    end

    function saveLinks
        
        % dialog
        [filename, pathname] = uiputfile('links.mat', 'Save');
        
        % deal with cancelled dialog
        if isnumeric(filename) && filename == 0
            return
        end        
        
        save(fullfile(pathname, filename), 'links')
        
    end

%     if gazeWasLoaded
%         dc.Data{1}.ClearGaze
%         gazeWasLoaded = false;
%     end

end