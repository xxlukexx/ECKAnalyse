function ECKDataTree(dc)
         
    % check input arg
    if ~exist('dc', 'var') || isempty(dc)
        dataPath = uigetdir(pwd, 'Select folder that contains data.');
        if isnumeric(dataPath) && dataPath == 0
            return
        end
        dc = ECKDataContainer(dataPath);
    end
    
    if ~isa(dc, 'ECKDataContainer')
        error('Input argument must be ECKDataContainer.')
    end
    
    % create figure window
    fig = figure('NumberTitle','off',...
               'Menubar','none',...
               'Toolbar','none',...
               'Name', 'Data Viewer',...
               'renderer', 'opengl',...
               'ResizeFcn', @resize);
 
    posFig = get(fig, 'Position');
    
    % create data panel
    posPanel = [(posFig(1, 3) / 3) + 2, 2, (posFig(1, 3) / 1.5), posFig(1, 4) - 2];
    panel = uipanel('Units', get(fig, 'Units'),...
        'Position', posPanel,...
        'BorderType', 'line');
    
    % root nodes (main root node will be invisible)
    nodRoot = uitreenode('v0', 'ROOT', 'Root', [], false);
    nodData = uitreenode('v0', 'DATA', 'Data', [], false);
    nodRoot.add(nodData);
    nodTools = uitreenode('v0', 'TOOLS', 'Tools', [], false);
    nodRoot.add(nodTools);  
    
    % data nodes
    nodParticipants = uitreenode('V0', 'ALLPIDS', 'By participant', [], false);
    nodData.add(nodParticipants);
    nodTasks = uitreenode('v0', 'ALLTASKS', 'By task', [], false);
    nodData.add(nodTasks);
    nodSegmentation = uitreenode('v0', 'ALLSEG', 'Segmentation', [], false);
    nodData.add(nodSegmentation);

    % tool nodes
    nodEvents = uitreenode('v0', 'ALLEVENTS', 'Event Viewer', [], false);
    nodEncryptEvents = uitreenode('v0', 'ALLENC', 'Encrypt Events', [], false);
    nodFixSplitSessions = uitreenode('v0', 'ALLFIXSPLIT', 'Fix Split Sessions', [], false);
    nodTools.add(nodEvents);
    nodTools.add(nodEncryptEvents);
    nodTools.add(nodFixSplitSessions);

    % create tree
    posTree = [2, 2, posFig(1, 3) / 3, posFig(1, 4) - 2];
    tree = uitree('v0', 'Root', nodRoot,...
        'ExpandFcn', {@expand, dc},...
        'SelectionChangeFcn', {@select, dc, panel},...
        'Position', posTree);

    tree.Tree.expandRow(0)
%     tree.Tree.expandRow(1)
%     tree.Tree.expandRow(5)
    
    tree.Tree.setRootVisible(false);
    
    function resize(hObject, eventdata, handles)

        posFig = get(fig, 'Position');
        treeWidth = posFig(1, 3) / 3;
        panLeft = treeWidth;
        if treeWidth > 200
            treeWidth = 200;
            panLeft = treeWidth;
        end
        panWidth = posFig(3) - treeWidth;

        posTree=[2, 2, treeWidth, posFig(1, 4) - 2];
        posPanel = [panLeft + 2, 2, panWidth,...
            posFig(1, 4) - 2];

        tree.Position = posTree;
        set(panel, 'Position', posPanel);

    end

end

function nodes = expand(tree, value, dc)

        % break apart value code 
        elements = breakApart(value);
        if isempty(elements),
            val = value; 
        else
            val = elements{1};
        end
        
        % check values/codes and create node data accordingly
        dc.FilterDisableAll;
        nodeCol = [1, 1, 1];
        switch val
            
            case 'ALLPIDS'
                
                TPs = dc.Timepoints;
                nodeNames = TPs;
                nodeTypes = cellfun(@(x) ['PIDTP#', x], TPs, 'Uniform', 0);
                isLeaf = false;
                                
            case 'ALLTASKS'
                
                tasks = sort(dc.Tasks);
                nodeNames = tasks;
                nodeTypes = cellfun(@(x) ['TASK#', x], tasks, 'Uniform', 0);
                isLeaf = false;
                
            case 'ALLEVENTS'
                
                PIDs = dc.Participants;
                nodeNames = PIDs;
                nodeTypes = cellfun(@(x) ['PIDEVENT#', x], PIDs, 'Uniform', 0);
                isLeaf = true;
                
            case 'ALLSEG'
                
                PIDs = dc.Participants;
                nodeNames = PIDs;
                nodeTypes = cellfun(@(x) ['PIDSEG#', x], PIDs, 'Uniform', 0);
                isLeaf = false;
                
            case 'PIDTP'
                
                TP = elements{2};
                dc.FilterDisableAll;
                dc.FilterValue('TIMEPOINT', TP);
                PIDs = dc.Participants;
                nodeNames = PIDs;
                nodeTypes = cellfun(@(x) ['PID#', x], PIDs, 'Uniform', 0);
                isLeaf = false;
            
            case 'PID'

                PID =  elements{2};
                dc.FilterDisableAll;
                dc.FilterValue('PARTICIPANTID', PID);
                tasks = sort(dc.Tasks);
                nodeNames = tasks;
                nodeTypes = cellfun(@(x) ['PIDTASK#', PID, '#', x], tasks, 'Uniform', 0);
                isLeaf = false;
                dc.FilterDisableAll;
                
            case 'TASK'
                
                task = elements{2};
                dc.FilterDisableAll;
                dc.FilterValue('TASK', task);
                
                % get participant ID and timepoint from DC and reformat
                tmpTab = dc.Table;
                tmpTab = convertCell(tmpTab(:, [2, 4]), 'string');
                numRows = size(tmpTab, 1);
                tmpTab = [...
                    tmpTab(:, 1),...
                    cellstr(repmat(' [', size(tmpTab, 1), 1)),...
                    tmpTab(:, 2), cellstr(repmat(']',...
                    size(tmpTab, 1), 1))];
                PIDTP = cell(numRows, 1);
                for pt = 1:numRows
                    PIDTP{pt, 1} = strjoin(tmpTab(pt, :), '');
                end
                [PIDTP, sortOrd] = sort(PIDTP);
                tmpTab = tmpTab(sortOrd, :);
                
                nodeNames = PIDTP;
                nodeTypes = cellfun(@(x) ['PIDTASK#', x, '#', task], tmpTab(:, 1), 'Uniform', 0);
                isLeaf = false;
                dc.FilterDisableAll;

            case 'PIDTASK'
                
                PID = elements{2};
                task = elements{3};
                dc.FilterDisableAll;
                dc.FilterValue('PARTICIPANTID', PID);
                [trials, valid] = ECKListTaskTrials(dc, task);
                if ~isempty(valid)
                    nodeColour = cell(1, length(valid));
                    nodeColour(~valid) = repmat({'"red"'}, 1, sum(~valid));
                    nodeColour(valid) = repmat({'"green"'}, 1, sum(valid));
                end
                nodeNames = trials;
                nodeTypes = cellfun(@(x) ['TRIAL#', task, '#', x(end - 2:end), '#PID#', PID], trials, 'Uniform', 0);
                isLeaf = true;
                
            case 'PIDSEG'
                
                PID = elements{2};
                
        end
        
        % loop through and add nodes to tree
        if exist('nodeNames', 'var') && ~isempty(nodeNames)
            for nodeIdx = 1:length(nodeNames)
                if ~exist('nodeColour', 'var') || isempty(nodeColour{nodeIdx})
                    nodeName = nodeNames{nodeIdx};
                else
                    nodeName = ['<html><font color=', nodeColour{nodeIdx}, '>', nodeNames{nodeIdx}, '</html>'];
                end
              nodeType = nodeTypes{nodeIdx};
              nodes(nodeIdx) = uitreenode('v0', nodeType, nodeName, [], isLeaf);
            end
        else 
            nodes = [];
        end
        
end

function select(tree, value, dc, panel)

    % clear old interface
    panelChildren = get(panel, 'children');
    if ~isempty(panelChildren), delete(panelChildren); end
    
    % break apart value code 
    nd = value.handle.CurrentNode;
    ndData = nd.handle.Value;
    elements = breakApart(ndData);
    if isempty(elements),
        val = ndData; 
    else
        val = elements{1};
    end

    % check values/codes and create node data accordingly
    dc.FilterDisableAll;
    switch val
        
        case 'DATA'

        case 'TASK'

            task = elements{2};
            dc.FilterDisableAll;
            PIDs = dc.Participants;
            displayTaskData(dc, task, panel);

        case 'PIDTASK'

            PID = elements{2};
            task = elements{3};
            dc.FilterDisableAll;
            dc.FilterValue('PARTICIPANTID', PID);
            PIDs = dc.Participants;
            displayTaskData(dc, task, panel);

        case 'TRIAL'

            task = elements{2};
            trial = str2num(elements{3});
            PID = elements{5};
            dc.FilterValue('PARTICIPANTID', PID);
            displayTrialData(dc, task, trial, panel);
            
        case 'PIDEVENT'
            
            PID = elements{2};
            dc.FilterValue('PARTICIPANTID', PID);
            ECKEventViewer(dc, panel);
            
        case 'ALLENC'
            
            dc.FilterDisableAll;
            ECKEncryptEvents(dc, panel);
            
        case 'ALLFIXSPLIT'
            
            ECKFixSplitSessions([], panel);
            
        case 'PIDSEG'
            
            disp('')
            
    end

end

function elements = breakApart(value)

    if isempty(value)
        elements = {};
        return
    end
    
    del = strfind(value, '#');
    if isempty(del)
        elements = {};
        return
    end
    
    elements{1} = value(1:del(1) - 1);
    for d = 1:length(del) - 1
        elements{end + 1} = value(del(d) + 1:del(d + 1) - 1);
    end
    elements{end + 1} = value(del(end) + 1:end);

end

function displayTrialData(dc, task, trial, panel)

    % clear old interface
    panelChildren = get(panel, 'children');
    if ~isempty(panelChildren), delete(panelChildren); end
        
    [found, onsets, offsets] = ECKTimestampsFromLog(dc, task);
    
    if found
        
        % segment
        cfg.onsettime = onsets(trial);
        cfg.offsettime = offsets(trial);
        cfg.type = 'timepairs';
        try
            dc_trial = etSegment(dc, cfg);      
        catch ERR
            if strcmpi(ERR.message, 'Timepairs segmentation can only be run on single datasets.')
                errordlg('Cannot segment this dataset beacuse it contains split sessions.', 'Split session');
                fprintf('Cannot segment this dataset beacuse it contains split sessions.')
                return
            end
        end
                
        switch task
            case 'gap_trial'

                % get all trial data
                [hdr, dta] = etCollateTask(dc, task);

                % store in segmented DC (since segmentation loses log data)
                dc_trial.ExtraData.gap_trial.hdr = hdr;
                dc_trial.ExtraData.gap_trial.dta = dta;
                dc_trial.ExtraData.gap_trial.trial = trial;

                ECKVisualise_gap_trial(dc_trial, hdr, dta(trial, :),...
                    panel);
                
            case 'scenes_trial'
                
                % attempt to segment using markers (since timestamps are
                % not correct in csvs)
                clear cfg
                cfg.type = 'labelpairs';
                cfg.onsetlabel = 'NATSCENES_BLOCK_START';
                cfg.offsetlabel = 'NATSCENES_BLOCK_END';
                cfg.takefirstoffset = true;
                cfg.takefirstonset = true;
                dc_ns = etSegment(dc_trial, cfg);
                plotGaze(dc_ns, panel, [.03, 0, 1, 1.25], {'NATSCENES_FRAME_X'});
                
            otherwise
                
                plotGaze(dc_trial, panel, [.03, 0, 1, 1.25]);

        end
        
    end
        
        
            
end

function displayTaskData(dc, task, panel)

    % clear old interface
    panelChildren = get(panel, 'children');
    if ~isempty(panelChildren), delete(panelChildren); end
                
        switch task
            case 'gap_trial'

                ECKVisualise_gap_summary(dc, panel);
                
%             case 'scenes_trial'
%                 
%                 plotGaze(dc_trial, panel, [.03, 0, 1, 1.25], {'NATSCENES_FRAME_30'});
%                 
%             otherwise
%                 
%                 plotGaze(dc_trial, panel, [.03, 0, 1, 1.25]);

        end
        
end
        
        
            