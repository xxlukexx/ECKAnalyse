function res = ECKEEGAverageReview(path_avg, path_clean, res, hParent)

    %% data
    
    if ~exist('path_avg', 'var') || ~exist(path_avg, 'file')
        error('Invalid path.')
    end
    
    % load results if not passed as an argument
    if ~exist('res', 'var') || isempty(res) 
        path_res = fullfile(path_avg, '_results.mat');
        if ~exist(path_res, 'file')
            error('Cannot find _results.mat.')
        else
            tmp = load(path_res);
            res = tmp.res;
            valid = ones(size(res, 1), 1);
        end
    else
        valid = res.ReviewValid;
    end
    
    sel = [];
    data = [];
    canDraw = false;
    wb = [];
    
    %% UI
    
    % if a parent handle (to e.g. figure, panel etc.) has not been
    % supplied, make a figure
    if ~exist('hParent', 'var') || isempty(hParent)
        figPos = [0, 0, 1, 1];
        fig = figure(...
                'NumberTitle',          'off',...
                'Units',                'normalized',...
                'Position',             figPos,...
                'Menubar',              'none',...
                'Toolbar',              'none',...
                'Name',                 'EEG Average Review',...
                'DeleteFcn',            @figDelete,...
                'renderer',             'opengl');
    else
        fig = hParent;
    end
    
    % main panel positions
    posTabDatasets =                    [0.00, 0.66, 1.00, 0.33];
    posTopo =                           [0.00, 0.00, 0.50, 0.66];
    posERP =                            [0.50, 0.10, 0.50, 0.56];
    posControls =                       [0.50, 0.00, 0.50, 0.10];
    
    % control positions
    btnW =                              0.15;
    posBtnValid =                       [0.00, 0.00, btnW, 1.00]; 
    posBtnVisualiser =                  [btnW, 0.00, btnW, 1.00];
    posBtnCopyID =                      [btnW * 2, 0.00, btnW, 1.00];
    posBtnReClean =                     [btnW * 3, 0.00, btnW, 1.00];
    posBtnSavePlots =                   [btnW * 4, 0.00, btnW, 1.00];
    
    tabDatasets = uitable(...
                'Data',                 table2cell(res),...
                'CellSelectionCallback',@tabDataset_Select,... 
                'CellEditCallback',     @tabDataset_Edit,...
                'Parent',               fig,...
                'Units',                'Normalized',...
                'RowName',              [],...
                'ColumnName',           res.Properties.VariableNames,...
                'ColumnWidth',          'auto',...
                'Position',             posTabDatasets);
    set(tabDatasets, 'ColumnFormat', {...
        'logical',...
        'char',...
        'char',...
        'char',...
        'char',...
        'char',...
        'char',...
        'char',...
        'char',...
        'char',...
        'numeric',...
        'char',...
        'numeric',...
        'numeric',...
        'numeric',...
        'char',...
        'logical',...
        'logical',...
        'logical',...
        'logical',...
        'numeric',...
        'numeric',...
        'numeric',...
        'numeric',...
        'char',...
        'logical',...
        'char',...
        'char',...
        'char'});
        
        
    jSPTabDatasets = findjobj(tabDatasets);
    jTabDatasets = jSPTabDatasets.getViewport.getView;
    jTabDatasets.setSortable(true);		
    jTabDatasets.setAutoResort(true);
    jTabDatasets.setMultiColumnSortable(true);
    jTabDatasets.setPreserveSelectionsAfterSorting(true);
%     jTabDatasets.setNonContiguousCellSelection(false);
    jTabDatasets.setColumnSelectionAllowed(false);
    jTabDatasets.setRowSelectionAllowed(true);
%     jTabDatasetsCB = handle(jTabDatasets, 'CallbackProperties');
%     set(jTabDatasetsCB, 'CaretPositionChangedCallback', @tabDataset_Select);
%     set(jTabDatasetsCB, 'MousePressedCallback', @tabDataset_Select);

    pnlTopo = axes(...
                'parent',               fig,...
                'units',                'normalized',...
                'position',             posTopo);
            
    pnlERP = uipanel(...
                'parent',               fig,...
                'units',                'normalized',...
                'position',             posERP);
            
    pnlControls = uipanel(...
                'parent',               fig,...
                'units',                'normalized',...
                'position',             posControls);
            
    btnValid = uicontrol(...
                'parent',               pnlControls,...
                'units',                'normalized',...
                'position',             posBtnValid,...
                'style',                'pushbutton',...
                'string',               'Unchecked',...
                'callback',             @btnValid_Click);
            
    btnVisualiser = uicontrol(...
                'parent',               pnlControls,...
                'units',                'normalized',...
                'position',             posBtnVisualiser,...
                'style',                'pushbutton',...
                'string',               'Visualiser',...
                'callback',             @btnVisualiser_Click);
            
    btnCopyID = uicontrol(...
                'parent',               pnlControls,...
                'units',                'normalized',...
                'position',             posBtnCopyID,...
                'style',                'pushbutton',...
                'string',               'Copy Clean Filename',...
                'callback',             @btnCopyID_Click);
            
    btnReClean = uicontrol(...
                'parent',               pnlControls,...
                'units',                'normalized',...
                'position',             posBtnReClean,...
                'style',                'pushbutton',...
                'string',               'Re-clean, re-avg',...
                'callback',             @btnReClean_Click);
            
    btnReClean = uicontrol(...
                'parent',               pnlControls,...
                'units',                'normalized',...
                'position',             posBtnSavePlots,...
                'style',                'pushbutton',...
                'string',               'Save All Plots',...
                'callback',             @btnSavePlots_Click);
            
    %% data
            
    function loadData
        
        if isempty(sel), return, end
        
        dataPath = res(sel, :).avg_PathOut{:};
        dataFile = res(sel, :).avg_FileOut{:};
%         tmp = load([dataPath, filesep, dataFile]);
        tmp = load([path_avg, filesep, dataFile]);
        
        data = tmp.erps;
        btnValid_UpdateState
        canDraw = true;
        
    end

    function saveValidTemp
        
        tmp = valid;
        filename = [tempdir, 'ECKEEGAverageReview_tempValid.mat'];
        save(filename, 'valid')
        
    end

    %% display

    function drawPlots
        if ~canDraw, return; end
                
        delete(get(pnlTopo, 'children'))
        delete(get(pnlERP, 'children'))
        
        % topo plot
        cfg = [];
        cfg.rotate = 90;
        cfg.layout = data.face_up.elec;
        cfg.interactive = 'no';
        cfg.showlabels = 'yes';
        gca = pnlTopo;
        ft_multiplotER(cfg, data.face_up, data.face_inv);
        
        % subplots of P7/8 O1/2
        
        chP7 = find(strcmpi(data.face_up.label, 'P7'));
        chP8 = find(strcmpi(data.face_up.label, 'P8'));
%         chPz = find(strcmpi(data.face_up.label, 'Pz'));
        chO1 = find(strcmpi(data.face_up.label, 'O1'));
        chO2 = find(strcmpi(data.face_up.label, 'O2'));
%         chOz = find(strcmpi(data.face_up.label, 'Oz'));

        % get max/min for all channels, to set ylim
        ampMax = max(max([data.face_up.avg([chP7, chP8, chO1, chO2], :);...
            data.face_inv.avg([chP7, chP8, chO1, chO2], :)]));
        ampMin = min(min([data.face_up.avg([chP7, chP8, chO1, chO2], :);...
            data.face_inv.avg([chP7, chP8, chO1, chO2], :)]));
        
        % P7
        subplot(2, 2, 1, 'parent', pnlERP)
        plot(data.face_up.time, data.face_up.avg(chP7, :), 'k',...
            'linewidth', 1);
        hold on 
        plot(data.face_inv.time, data.face_inv.avg(chP7, :), 'r',...
            'linewidth', 1);
        set(gca, 'xgrid', 'on')
        set(gca, 'xminorgrid', 'on')
        title('P7')
        legend({'Upright', 'Inverted'})
        ylim([ampMin, ampMax]);
                
        % peaks P7
        if isfield(data.face_up, 'peaklabel')
            % P1
            x = data.face_up.peakloc(chP7, 1);
            y = data.face_up.peakamp(chP7, 1);
            sc = scatter(x, y, 75, 'dk');
            sc.LineWidth = 2;
            sc.MarkerFaceColor = 'y';
            x = data.face_inv.peakloc(chP7, 1);
            y = data.face_inv.peakamp(chP7, 1);
            sc = scatter(x, y, 75, 'dr');        
            sc.LineWidth = 2;
            sc.MarkerFaceColor = 'y';
            
            % N1
            x = data.face_up.peakloc(chP7, 2);
            y = data.face_up.peakamp(chP7, 2);
            sc = scatter(x, y, 75, 'dk');
            sc.LineWidth = 2;
            sc.MarkerFaceColor = 'g';
            x = data.face_inv.peakloc(chP7, 2);
            y = data.face_inv.peakamp(chP7, 2);
            sc = scatter(x, y, 75, 'dr');        
            sc.LineWidth = 2;
            sc.MarkerFaceColor = 'g';        
        end
        
        % details
        str = '';
        str = [str, sprintf('TPC up: %d | TPC inv: %d', data.summary.tpc_up,...
            data.summary.tpc_inv)];
        text(0.025, .950, str, 'color', 'm', 'units', 'normalized',...
            'fontsize', 14);
        
        hold off
        
        % P8
        subplot(2, 2, 2, 'parent', pnlERP)
        plot(data.face_up.time, data.face_up.avg(chP8, :), 'k',...
            'linewidth', 1);
        hold on 
        plot(data.face_inv.time, data.face_inv.avg(chP8, :), 'r',...
            'linewidth', 1);
        set(gca, 'xgrid', 'on')
        set(gca, 'xminorgrid', 'on')        
        title('P8')
        legend({'Upright', 'Inverted'})
        ylim([ampMin, ampMax]);
        
        % peaks P8
        if isfield(data.face_up, 'peaklabel')
            % P1
            x = data.face_up.peakloc(chP8, 1);
            y = data.face_up.peakamp(chP8, 1);
            sc = scatter(x, y, 75, 'dk');
            sc.LineWidth = 2;
            sc.MarkerFaceColor = 'y';
            x = data.face_inv.peakloc(chP8, 1);
            y = data.face_inv.peakamp(chP8, 1);
            sc = scatter(x, y, 75, 'dr');        
            sc.LineWidth = 2;
            sc.MarkerFaceColor = 'y';
            
            % N1
            x = data.face_up.peakloc(chP8, 2);
            y = data.face_up.peakamp(chP8, 2);
            sc = scatter(x, y, 75, 'dk');
            sc.LineWidth = 2;
            sc.MarkerFaceColor = 'g';
            x = data.face_inv.peakloc(chP8, 2);
            y = data.face_inv.peakamp(chP8, 2);
            sc = scatter(x, y, 75, 'dr');        
            sc.LineWidth = 2;
            sc.MarkerFaceColor = 'g';
        end
        
        hold off
        
        % O1
        subplot(2, 2, 3, 'parent', pnlERP)
        plot(data.face_up.time, data.face_up.avg(chO1, :), 'k',...
            'linewidth', 1);
        hold on 
        plot(data.face_inv.time, data.face_inv.avg(chO1, :), 'r',...
            'linewidth', 1);
        set(gca, 'xgrid', 'on')
        set(gca, 'xminorgrid', 'on')        
        title('O1')
        legend({'Upright', 'Inverted'})
        ylim([ampMin, ampMax]);
        
        % peaks O1
        if isfield(data.face_up, 'peaklabel')
            % P1
            x = data.face_up.peakloc(chO1, 1);
            y = data.face_up.peakamp(chO1, 1);
            sc = scatter(x, y, 75, 'dk');
            sc.LineWidth = 2;
            sc.MarkerFaceColor = 'y';
            x = data.face_inv.peakloc(chO1, 1);
            y = data.face_inv.peakamp(chO1, 1);
            sc = scatter(x, y, 75, 'dr');        
            sc.LineWidth = 2;
            sc.MarkerFaceColor = 'y';
            
            % N1
            x = data.face_up.peakloc(chO1, 2);
            y = data.face_up.peakamp(chO1, 2);
            sc = scatter(x, y, 75, 'dk');
            sc.LineWidth = 2;
            sc.MarkerFaceColor = 'g';
            x = data.face_inv.peakloc(chO1, 2);
            y = data.face_inv.peakamp(chO1, 2);
            sc = scatter(x, y, 75, 'dr');        
            sc.LineWidth = 2;
            sc.MarkerFaceColor = 'g';
        end
        
        hold off
        
        % O2
        subplot(2, 2, 4, 'parent', pnlERP)
        plot(data.face_up.time, data.face_up.avg(chO2, :), 'k',...
            'linewidth', 1);
        hold on 
        plot(data.face_inv.time, data.face_inv.avg(chO2, :), 'r',...
            'linewidth', 1);
        set(gca, 'xgrid', 'on')
        set(gca, 'xminorgrid', 'on')        
        title('O2')
        legend({'Upright', 'Inverted'})
        ylim([ampMin, ampMax]);
        
        % peaks O2
        if isfield(data.face_up, 'peaklabel')
            % P1
            x = data.face_up.peakloc(chO2, 1);
            y = data.face_up.peakamp(chO2, 1);
            sc = scatter(x, y, 75, 'dk');
            sc.LineWidth = 2;
            sc.MarkerFaceColor = 'y';
            x = data.face_inv.peakloc(chO2, 1);
            y = data.face_inv.peakamp(chO2, 1);
            sc = scatter(x, y, 75, 'dr');        
            sc.LineWidth = 2;
            sc.MarkerFaceColor = 'y';
            
            % N1
            x = data.face_up.peakloc(chO2, 2);
            y = data.face_up.peakamp(chO2, 2);
            sc = scatter(x, y, 75, 'dk');
            sc.LineWidth = 2;
            sc.MarkerFaceColor = 'g';
            x = data.face_inv.peakloc(chO2, 2);
            y = data.face_inv.peakamp(chO2, 2);
            sc = scatter(x, y, 75, 'dr');        
            sc.LineWidth = 2;
            sc.MarkerFaceColor = 'g';
        end
        
        hold off  
        delete(findobj(gcf, 'type', 'uimenu', 'label', 'FieldTrip'));
        notBusy
                
    end

    function busy(msg)
        set(gcf, 'pointer', 'watch');
        if exist('msg', 'var'), wb = waitbar(0, msg); end
        drawnow
    end

    function notBusy
        set(gcf, 'pointer', 'arrow')
        if ishandle(wb), close(wb), end
        drawnow
    end 

    function btnValid_UpdateState
        switch valid(sel)
            case 0
                % invalid
                set(btnValid, 'BackgroundColor', [1.00, 0.60, 0.60]);
                set(btnValid, 'String', 'Bad');
            case 1
                % unchecked
                set(btnValid, 'BackgroundColor', [0.94, 0.94, 0.94]);
                set(btnValid, 'String', 'Unchecked');
            case 2
                % good
                set(btnValid, 'BackgroundColor', [0.60, 1.00, 0.60]);
                set(btnValid, 'String', 'Good');
        end
    end

    %% callbacks
    
    function figDelete(~, ~)
        delete(fig)
        if ~any(strcmpi(res.Properties.VariableNames, 'ReviewValid'))
            res = [res, table(valid, 'variablenames', {'ReviewValid'})];
        else
            res.ReviewValid = valid;
        end
        filename = fullfile(pwd, ['_review_', datetimeStr, '.mat']);
        save(filename, 'res');
        fprintf('<strong>Saved updated results to:</strong> \n\t%s\n',...
            filename)
    end

    function tabDataset_Select(~, dat)
        busy
%         sel = get(h, 'SelectedRow') + 1;
        sel = dat.Indices(:, 1);
        if ~res.avgValid(sel)
            errordlg('Average was not valid for this dataset')
            notBusy
            return
        end
        loadData
        drawPlots
    end

    function btnValid_Click(~, ~)
        state = valid(sel);
        state = state + 1;
        if state > 2, state = 0; end
        valid(sel) = state;
        btnValid_UpdateState
        saveValidTemp
    end

    function btnVisualiser_Click(~, ~)
        clear eegv
        eegv = ECKEEGVis;
        tmpClean = load(fullfile(path_clean, res.clean_FileOut{sel}));
        eegv.Data = tmpClean.data;
        eegv.AutoSetTrialYLim = false;
        eegv.WindowSize = [0, 0, 1600, 900];
        eegv.YLim = [-90, 90];
        eegv.StartInteractive;
    end

    function btnCopyID_Click(~, ~)
        clipboard('copy', res.clean_FileIn{sel});
    end

    function btnReClean_Click(~, ~)
        busy
        LEAP_EEG_faces_cleanOne(res.clean_FileIn{sel})
        LEAP_EEG_faces_avgOne(res.clean_FileOut{sel})
        loadData
        drawPlots
        notBusy
    end

    function btnSavePlots_Click(~, ~)
        for s = 1:size(res, 1)
            sel = s;
            loadData
            drawPlots
            
            file_out = fullfile('/Users/luke/Google Drive/Experiments/face erp/indavg_plots_20181029',...
                sprintf('%s.png', res.ID{s}));
%             export_fig(pnlERP, file_out, '-r55')
saveas(pnlERP, file_out)
            drawnow
            
        end
        
    end

end