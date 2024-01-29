function ECKSegmentSummaryViewer(data, hParent)

    %% DATA
    
    if ~isa(data, 'ECKData')
        error('Input must be ECKData')
    end
    
    % make segment summary table grid
    segSumGrid = cell(data.NumSegments, 5);
    
    % rolling segment number
    segSumGrid(:, 1) = num2cell(1:data.NumSegments)';
    
    % segment label
    segSumGrid(:, 2) = cellfun(@(x) x.Label, data.Segments, 'uniform', 0)';
    
    % segment additional data (usually originating label)
    segSumGrid(:, 3) = cellfun(@(x) x.AddData{1}, data.Segments, 'uniform', 0)';
    
    % segment duration
    segSumGrid(:, 4) = cellfun(@(x)...
        double(x.TimeBuffer(end, 1) - x.TimeBuffer(1, 1)) / 1000000,...
        data.Segments, 'uniform', 0)';
    
    % number of events within segment
    segSumGrid(:, 5) = cellfun(@(x)...
        size(x.EventBuffer, 1), data.Segments, 'uniform', 0)';
    
    % headers
    segSumGridHdr = {'', 'Label', 'Add Data', 'Dur (s)',...
        'Events'};
    
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
    
    % define proportions of event table (left hand side) and plotting
    % panel (right hand side)
    tabPlotProp = .25;
    
    % segment summary table
    posTabSegSum            =   [0, 0, tabPlotProp, 1];
    
    % plotting panel
    posPnlPlot              =   [tabPlotProp, 0, 1 - tabPlotProp, 1];
    
    % segment summary table
    tabSegSum = uitable('Data', segSumGrid,...
        'CellSelectionCallback', @tabSegSum_Select,... 
        'Parent', fig,...
        'Units', 'Normalized',...
        'RowName', [],...
        'ColumnName', segSumGridHdr,...
        'ColumnWidth', {20, 90, 105, 45, 40},...
        'Position', posTabSegSum);
    
    pnlPlot = uipanel('parent', fig,...
        'Units', 'normalized',...
        'Position', posPnlPlot);
    
    %% CALLBACKS
    
    function tabSegSum_Select(h, dat)
        
        
        % clear old interface
        panelChildren = get(pnlPlot, 'children');
        if ~isempty(panelChildren), delete(panelChildren); end
        
        % get index of selected row 
        sel = dat.Indices(:, 1);
        
        % determine number of selected rows, if one, plot data, otherwise
        % make a subplot
        if length(sel) == 1
            
%             plotGaze(data.Segments{sel}, pnlPlot, [.28, 0, .74, 1.24]);
            plotGaze(data.Segments{sel}, pnlPlot);

        else 
            
            numSP = numSubplots(length(sel));
            spw = 1 / numSP(2);
            sph = 1 / numSP(1);
            
            idx = 1;
            for r = 1:numSP(1)
                
                for c = 1:numSP(2)
                    
                    if idx <= length(sel)
                        
%                         x = ((c - 1) * spw) + (spw * .03);
%                         y = (numSP(1) - r) * sph;
%                         w = spw * .99; 
%                         h = sph * 1.29;
                        x = ((c - 1) * spw);
                        y = (numSP(1) - r) * sph;
                        w = spw;
                        h = sph;

                        plotGaze(data.Segments{sel(idx)}, pnlPlot,...
                            [x, y, w, h]);
                        
                    end
                    
                    idx = idx + 1;
                    
                end
                
            end
            
        end

            
            
        disp('')
        
    end
    



end