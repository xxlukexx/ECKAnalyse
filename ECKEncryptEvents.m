function ECKEncryptEvents(data, hParent)

    %% DATA
    
    dc = checkDataIn(data);
    
    
    %% INIT VARS

    links = [];
    
    %% UI
    
    % if a parent handle (to e.g. figure, panel etc.) has not been
    % supplied, make a figure
    if ~exist('hParent', 'var') || isempty(hParent)
        fig = figure('NumberTitle','off',...
                    'Units', 'Normalized',...
                   'Menubar','none',...
                   'Toolbar','none',...
                   'Name', 'Encrypt Events',...
                   'renderer', 'opengl');
    else
        fig = hParent;
    end
       
    % default height of a button
    btnHeight               =   1;
    nBtns                   =   6;
    btnWidth                =   1 / nBtns;
    
    % datasets table
    posTabDatasets          =   [0, .1, .5, .9];
    
    % trial list
    posLstTasks            =   [.5, .1, .5, .9];         
    
    % controls panel
    posPnlControls          =   [0, 0, 1, .1];
    posBtnEncrypt           =   [0 * btnWidth, 0, btnWidth, btnHeight];
    posBtnDecrypt           =   [1 * btnWidth, 0, btnWidth, btnHeight];
    posBtnLoadLinks         =   [2 * btnWidth, 0, btnWidth, btnHeight];
    posBtnLoadTasks        =   [3 * btnWidth, 0, btnWidth, btnHeight];

    % controls
    tabData = dc.Table;
    tabData = [tabData(:, [2, 4]), num2cell(true(length(dc.Data), 1))];
    tabDatasets = uitable('Data', tabData,...
        'Parent', fig,...
        'Units', 'Normalized',...
        'RowName', [],...
        'ColumnName', {'ID', 'Timepoint', 'Encrypt?'},...
        'ColumnEditable', [false, false, true],...
        'ColumnWidth', 'auto',...
        'Position', posTabDatasets);
%         'CellSelectionCallback', @tabDatasets_Select,... 

    tasks = dc.Tasks;
    numTasks = length(tasks);
    lstTasks = uicontrol('Style', 'ListBox',...
        'Units', 'Normalized',...
        'Position', posLstTasks,...
        'Max', 20,...
        'Value', 1:numTasks,...
        'String', tasks);
    
    pnlControls = uipanel('parent', fig,...
        'Units', 'normalized',...
        'Position', posPnlControls);

    btnEncrypt = uicontrol('parent', pnlControls,...
        'Style', 'PushButton',...
        'Units', 'normalized',...
        'Position', posBtnEncrypt,...
        'Callback', @btnEncrypt_Click,...
        'String', 'Encrypt');

    btnDecrypt = uicontrol('parent', pnlControls,...
        'Style', 'PushButton',...
        'Units', 'normalized',...
        'Position', posBtnDecrypt,...
        'Callback', @btnDecrypt_Click,...
        'String', 'Decrypt');
    
    btnLoadLinks = uicontrol('parent', pnlControls,...
        'Style', 'PushButton',...
        'Units', 'normalized',...
        'Position', posBtnLoadLinks,...
        'Callback', @btnLoadLinks_Click,...
        'String', 'Load links');
    
    btnLoadTasks = uicontrol('parent', pnlControls,...
        'Style', 'PushButton',...
        'Units', 'normalized',...
        'Position', posBtnLoadTasks,...
        'Callback', @btnLoadTasks_Click,...
        'String', 'Load tasks');
    
    function btnEncrypt_Click(h, dat)
        
        tmpTabData = get(tabDatasets, 'Data');
        sel = cell2mat(tmpTabData(:, 3));
        if ~any(sel)
            errordlg('No datasets selected.')
        end
        
        if isempty(links)
            errordlg('No links loaded. Must load links first.')
            return
        end
        
        % get selected tasks
        selTasks = tasks(get(lstTasks, 'value'));
        if isempty(selTasks)
            errordlg('No tasks are selected for encryption.')
            return
        end
        
        % get encryption key
        key = inputdlg('Enter encryption key. Without this key, it will not be possible to decrypt these events.');
        if isempty(key)
            return
        end
        
        % get path of first dataset to use as starting point in file
        % dialog
        tmpTab = dc.Table;
        dataPath = tmpTab{1, 5};
        
        % get output path
        outPath = uigetdir(dataPath, 'Select output folder for encrypted data.');
        
        % encrypt
        wb = waitbar(0, 'Encrypting events...');
        dc_enc = ECKDuplicateDC(dc);
        for d = 1:length(sel)
            
            wb = waitbar(d / length(sel), wb,...
                sprintf('Encrypting events...(%d of %d)...', d, length(sel)));

            if sel(d)
                eb = dc.Data{d}.EventBuffer;
                if ~isempty(eb)
                    eb_enc = etEncryptEvents(eb, links, selTasks, cell2mat(key));
                    dc_enc.Data{d}.EventBuffer = eb_enc;
                    dc_enc.Data{d}.Save(outPath);
                end
            end
                            
        end
        
        close(wb);

    end

    function btnLoadLinks_Click(h, dat)
        
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
            msgbox('Links loaded successfully.')
        else
            errordlg('Not a valid links file.')
        end 
        
    end

    function btnLoadTasks_Click(h, dat)
        
        % dialog
        [filename, pathname] = uigetfile('*.mat', 'Load');
        
        % deal with cancelled dialog
        if isnumeric(filename) && filename == 0
            return
        end
        
        % load 
        tmp = load(fullfile(pathname, filename));
        
        % check valid file
        if isfield(tmp, 'tasks') && iscell(tmp.tasks)
            tasks = tmp.tasks;
            msgbox('Tasks loaded successfully.')
        else
            errordlg('Not a valid tasks file.')
        end 
        
        set(lstTasks, 'String', tasks);
        set(lstTasks, 'Value', 1:length(tasks));
        
    end
%     % datasets list
%     posLstDatasets          =   [0, 0, .2, .8];
%     
%     % events table
%     posTabEvents            =   [0, .05, .8, .95];
%     
%     % events controls
%     posPnlControls          =   [0, 0, .8, .05];
%     eventsNumBtn            =   6;       
%     eventsBtnW              =   1 / eventsNumBtn;
%     posBtnSelectAll         =   [eventsBtnW * 0, 1 - btnHeight, eventsBtnW, btnHeight];
%     posBtnSelectNone        =   [eventsBtnW * 1, 1 - btnHeight, eventsBtnW, btnHeight];
%     posBtnSelectMatch       =   [eventsBtnW * 2, 1 - btnHeight, eventsBtnW, btnHeight];
%     posBtnSelectPrefix      =   [eventsBtnW * 3, 1 - btnHeight, eventsBtnW, btnHeight];
%     posBtnSelectPair        =   [eventsBtnW * 4, 1 - btnHeight, eventsBtnW, btnHeight];
%     posBtnSelectAllPairs    =   [eventsBtnW * 5, 1 - btnHeight, eventsBtnW, btnHeight];
%     
%     % tasks panel 
%     posPnlTasks             =   [.8, 0, .2, 1];
%     posLstTasks             =   [0, .6, 1, .4];
%     posLstEvents            =   [0, .2, 1, .4];
%     
%     % tasks controls
%     posPnlTaskControls      =   [0, 0, 1, .2];
%     taskControlsBtnRows     =   6;       
%     taskControlsBtnCols     =   2;
%     taskControlsBtnW        =   1 / taskControlsBtnCols;
%     taskControlsBtnH        =   1 / taskControlsBtnRows;
%     posBtnLoadLink          =   [taskControlsBtnW * 0, 1 - (taskControlsBtnH * 1), taskControlsBtnW, taskControlsBtnH];
%     posBtnSaveLink          =   [taskControlsBtnW * 1, 1 - (taskControlsBtnH * 1), taskControlsBtnW, taskControlsBtnH];
%     posBtnLink              =   [taskControlsBtnW * 0, 1 - (taskControlsBtnH * 2), taskControlsBtnW, taskControlsBtnH];
%     posBtnUnlink             =   [taskControlsBtnW * 1, 1 - (taskControlsBtnH * 2), taskControlsBtnW, taskControlsBtnH];
%     
%     % event table
%     tabEvents = uitable('Data', gridCol,...
%         'CellSelectionCallback', @tabEvents_Select,... 
%         'Parent', fig,...
%         'Units', 'Normalized',...
%         'RowName', [],...
%         'ColumnName', colHdrs,...
%         'ColumnWidth', num2cell(maxLen * 7),...
%         'Position', posTabEvents);
%     jSPTabEvents = findjobj(tabEvents);
%     jTabEvents = jSPTabEvents.getViewport.getView;
%     jTabEventsUpdating = false;
%     
%     % events controls
%     pnlControls = uipanel('parent', fig,...
%         'Units', 'normalized',...
%         'Position', posPnlControls);
%     
%     btnSelectAll = uicontrol('parent', pnlControls,...
%         'Style', 'PushButton',...
%         'Units', 'normalized',...
%         'Position', posBtnSelectAll,...
%         'Callback', @btnSelectAll_Click,...
%         'String', 'Select All');
%     
%     btnSelectNone = uicontrol('parent', pnlControls,...
%         'Style', 'PushButton',...
%         'Units', 'normalized',...
%         'Position', posBtnSelectNone,...
%         'Callback', @btnSelectNone_Click,...
%         'String', 'Select None');
%     
%     btnSelectMatch = uicontrol('parent', pnlControls,...
%         'Style', 'PushButton',...
%         'Units', 'normalized',...
%         'Position', posBtnSelectMatch,...
%         'Callback', @btnSelectMatch_Click,...
%         'Enable', 'off',...
%         'String', 'Select Match');
%     
%     btnSelectPrefix = uicontrol('parent', pnlControls,...
%         'Style', 'PushButton',...
%         'Units', 'normalized',...
%         'Position', posBtnSelectPrefix,...
%         'Callback', @btnSelectPrefix_Click,...
%         'Enable', 'off',...
%         'String', 'Select Prefix');
%     
%     btnSelectPair = uicontrol('parent', pnlControls,...
%         'Style', 'PushButton',...
%         'Units', 'normalized',...
%         'Position', posBtnSelectPair,...
%         'Callback', @btnSelectPair_Click,...
%         'Enable', 'off',...
%         'String', 'Select Pairs');
%     
%     btnSelectAllPairs = uicontrol('parent', pnlControls,...
%         'Style', 'PushButton',...
%         'Units', 'normalized',...
%         'Position', posBtnSelectAllPairs,...
%         'Callback', @btnSelectAllPairs_Click,...
%         'Enable', 'off',...
%         'String', 'Select All Pairs');
%     
%     % tasks panel
%     pnlTasks = uipanel('parent', fig,...
%         'Units', 'normalized',...
%         'Position', posPnlTasks);
%     
%     lstTasks = uicontrol('Style', 'ListBox',...
%         'Parent', pnlTasks,...
%         'Callback', @lstTasks_Select,...
%         'Max', 20,...
%         'Units', get(fig, 'Units'),...
%         'Position', posLstTasks,...
%         'FontS', 12,...
%         'Value', [],...
%         'String', tasks);  
%     
%     lstEvents = uicontrol('Style', 'ListBox',...
%         'Parent', pnlTasks,...
%         'Callback', @lstEvents_Select,...
%         'Max', 20,...
%         'Units', get(fig, 'Units'),...
%         'Position', posLstEvents,...
%         'FontS', 12,...
%         'Enable', 'off',...
%         'Value', [],...
%         'String', '<No links loaded>'); 
%     
%     pnlTaskControls = uipanel('parent', pnlTasks,...
%         'Units', 'normalized',...
%         'Position', posPnlTaskControls);
%     
%     btnLoadLink = uicontrol('parent', pnlTaskControls,...
%         'Style', 'PushButton',...
%         'Units', 'normalized',...
%         'Position', posBtnLoadLink,...
%         'Callback', @btnLoadLink_Click,...
%         'Enable', 'on',...
%         'String', 'Load Links');
%     
%     btnSaveLink = uicontrol('parent', pnlTaskControls,...
%         'Style', 'PushButton',...
%         'Units', 'normalized',...
%         'Position', posBtnSaveLink,...
%         'Callback', @btnSaveLink_Click,...
%         'Enable', 'off',...
%         'String', 'Save Links');
%     
%     btnLink = uicontrol('parent', pnlTaskControls,...
%         'Style', 'PushButton',...
%         'Units', 'normalized',...
%         'Position', posBtnLink,...
%         'Callback', @btnLink_Click,...
%         'Enable', 'off',...
%         'String', '=> Link');
%     
%     btnUnlink = uicontrol('parent', pnlTaskControls,...
%         'Style', 'PushButton',...
%         'Units', 'normalized',...
%         'Position', posBtnUnlink,...
%         'Callback', @btnUnlink_Click,...
%         'Enable', 'off',...
%         'String', '<= Unlink');

end