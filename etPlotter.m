classdef etPlotter 
  
    properties (Access = public)
        FilterOffscreenGaze = true;
        ShowLeftEye = false;
        ShowRightEye = false;
        ShowAvgEyes = true;
        CursorTime
        CursorWidth = .5;
        VisibleStart = 0;
        VisibleTime = 10;
        hParent
    end
    
    properties (Dependent)
        DataLoaded = false;
        Selected 
    end
    
    properties (SetAccess = private)
        Data@etData
    end      
    
    properties (Access = private)
        hspx                        % handles to subplots for x data...
        hspy                        % ...y data
        hspp                        % ...pupil data
        hsp2                        % ...2D gaze
        hCursorx                    % ...cursor on x time series
        hCursory                    % ...cursor on y time series
        hCursorp                    % ...cursor on pupil time series
        hCursor2D                   % ...cursor on 2D gaze plot
        pSelected                   % ...vector indexing selected samples
    end
    
    properties (Constant)
        WIDTH_MONO = 1;
        WIDTH_BINO = 7;
        WIDTH_SELECTED = 25;
        COL_CURSOR = 'm';
        COL_SELECTED = 'm';
    end
    
    methods
        
        % constructor
        function obj = etPlotter(varargin)
            
            % set cursor pos 
            obj.CursorTime = obj.VisibleStart;
            
            % if data has been passed, get it
            if nargin == 0
                return
            elseif nargin >= 1
                obj = obj.AddData(varargin{:});
            end
            
%             % colour defaults
%             tmpCols = lines(3);
%             obj.ColourX = tmpCols(1);
%             obj.ColourY = tmpCols(2);
%             obj.ColourPupil = tmpCols(3);
            
            obj = obj.DrawUI;
            
        end
        
        % data
        function obj = AddData(obj, varargin)
            
            if nargin >= 1
                
                % pass input args to etData. this assumes that a single
                % dataset has been passed, in either ECKData or 3-4 buffer
                % format
                obj.Data = etData(varargin{:});   
                
            end
            
        end
        
        % UI
        function obj = DrawUI(obj)
            
            if isempty(obj.hParent)
                obj.hParent = figure('MenuBar', 'none', 'Name',...
                    'etPlotter', 'Toolbar', 'none', 'NumberTitle',...
                    'off');
            end
                        
            clf
            
            set(gcf, 'pointer', 'watch');
            
            %% DATA
            
            % make a temporary copy of the data
            data = obj.Data;
                        
            % check if fixation have been supplied
            fixations = ~isempty(data.fb);
            
            % get number of datasets
            nd = data.NumData;
            
            % position cursor
            s1 = zeros(nd, 1);
            s2 = zeros(nd, 1);
            cursorPosUs = data.tb(1, 1) + uint64(obj.VisibleStart * 1e6);
            endPosUs = cursorPosUs + uint64(obj.VisibleTime * 1e6);
            for d = 1:nd
                s1(d) = etTimeToSample(data.tb(:, :, d), cursorPosUs);
                s2(d) = etTimeToSample(data.tb(:, :, d), endPosUs);
            end
            data.mb = data.mb(s1:s2, :, :);
            data.tb = data.tb(s1:s2, :, :);
            
            % get time vector
            t = data.Time + obj.VisibleStart;

            % get number of samples
            ns = size(data.mb, 1);
            
            % preallocate x, y and pupil coords
            agx = zeros(ns, nd);
            agy = zeros(ns, nd);
            ap = zeros(ns, nd);
            
            lgx = zeros(ns, nd);
            lgy = zeros(ns, nd);
            lp = zeros(ns, nd);
            
            rgx = zeros(ns, nd);
            rgy = zeros(ns, nd);
            rp = zeros(ns, nd);

            % remove offscreen samples of gaze
            if obj.FilterOffscreenGaze
                for d = 1:data.NumData
                    data.mb(:, :, d) =...
                        etFilterGazeOnscreen(data.mb(:, :, d));
                end
            end
            
            % average eyes
            if obj.ShowAvgEyes
                for d = 1:data.NumData
                    [agx(:, d), agy(:, d), ap(:, d)] =...
                        etAverageEyeBuffer(data.mb);
                end
            end
            
            % get left and right eye data
            if obj.ShowLeftEye
                lgx = shiftdim(data.mb(:, 7, :), 1);
                lgy = shiftdim(data.mb(:, 8, :), 1);
                lp = shiftdim(data.mb(:, 12, :), 1);
            end
            
            if obj.ShowRightEye
                rgx = shiftdim(data.mb(:, 7, :), 1);
                rgy = shiftdim(data.mb(:, 7, :), 1);
                rp = shiftdim(data.mb(:, 7, :), 1);
            end

            %% PLOTS
            
            % time series
            obj.hspx = subplot(3, 3, 1:2);
            hold(obj.hspx, 'on')
            
            obj.hspy = subplot(3, 3, 4:5);
            hold(obj.hspy, 'on')
            
            obj.hspp = subplot(3, 3, 7:8);
            hold(obj.hspp, 'on')
            
            % set axis details
            ylim(obj.hspx, [0, 1]);
            xlim(obj.hspx, [min(t), max(t)])
            posx = get(obj.hspx, 'position');
            posx = posx + [-.1, 0, .1, .05];
            set(obj.hspx, 'position', posx);
            set(obj.hspx, 'ydir', 'reverse')
            set(obj.hspx, 'xticklabel', [])
            set(obj.hspx, 'yticklabel', {'L', 'C', 'R'});
            set(obj.hspx, 'xgrid', 'on')
            set(obj.hspx, 'ygrid', 'on')
            set(obj.hspx, 'yminorgrid', 'on')
            text(.01, .95, 'X', 'parent', obj.hspx, 'units', 'normalized',...
                'color', [.5, 0, 0]);
            
            ylim(obj.hspy, [0, 1]);
            xlim(obj.hspy, [min(t), max(t)])
            posy = get(obj.hspy, 'position');
            posy = posy + [-.1, 0, .1, .05];
            set(obj.hspy, 'position', posy);
            set(obj.hspy, 'ydir', 'reverse')
            set(obj.hspy, 'xticklabel', [])
            set(obj.hspy, 'yticklabel', {'T', 'C', 'B'});
            set(obj.hspy, 'xgrid', 'on')
            set(obj.hspy, 'ygrid', 'on')
            set(obj.hspy, 'yminorgrid', 'on')
            text(.01, .95, 'Y', 'parent', obj.hspy, 'units', 'normalized',...
                'color', [.5, 0, 0]);

            xlim(obj.hspp, [min(t), max(t)])
            posp = get(obj.hspp, 'position');
            posp = posp + [-.1, 0, .1, .05];
            set(obj.hspp, 'position', posp);
            set(obj.hspp, 'xgrid', 'on')
            set(obj.hspp, 'ygrid', 'on')
            set(obj.hspp, 'yminorgrid', 'on')
            splim = get(obj.hspp, 'ylim');
            text(.01, .95, 'Pupil', 'parent', obj.hspp, 'units', 'normalized',...
                'color', [.5, 0, 0]);
            
            % 2D plot
            obj.hsp2 = subplot(3, 3, [3, 6]);
            xlim(obj.hsp2, [0, 1]);
            ylim(obj.hsp2, [0, 1]);
            set(obj.hsp2, 'clim', [min(t), max(t)]);
            sp2cb = colorbar('location', 'southoutside');
            set(sp2cb, 'ticks', get(obj.hspx, 'xtick'));
            hold(obj.hsp2, 'on')
            set(obj.hsp2, 'xticklabel', []);
            set(obj.hsp2, 'yticklabel', []);
            set(obj.hsp2, 'ydir', 'reverse');
            set(obj.hsp2, 'xtick', [0:.1:1]);
            set(obj.hsp2, 'ytick', [0:.1:1]);
            set(obj.hsp2, 'position', [0.645, 0.55, 0.33, 0.425]);
            set(obj.hsp2, 'xgrid', 'on')
            set(obj.hsp2, 'ygrid', 'on')
            sp2cbPos = get(sp2cb ,'position');
            sp2cbPos(2) = sp2cbPos(2) + .05;
            sp2cbPos(4) = sp2cbPos(4) - .025;
            set(sp2cb, 'position', sp2cbPos);
            
%             if obj.ShowLeftEye
%                 scatter(t, lgx, obj.WIDTH_MONO,...
%                     'parent', obj.hspx, 'hittest', 'off');
%                 scatter(t, lgy, obj.WIDTH_MONO,...
%                     'parent', obj.hspy, 'hittest', 'off');
%                 scatter(t, lp, obj.WIDTH_MONO,...
%                     'parent', obj.hspp, 'hittest', 'off');
%                 scatter(lgx, lgy, obj.WIDTH_MONO, parula(ns),...
%                     'parent', obj.hsp2, 'hittest', 'off');
%             end
%             
%             if obj.ShowRightEye
%                 scatter(t, rgx, obj.WIDTH_MONO,...
%                     'parent', obj.hspx, 'hittest', 'off');
%                 scatter(t, rgy, obj.WIDTH_MONO,...
%                     'parent', obj.hspy, 'hittest', 'off');
%                 scatter(t, rp, obj.WIDTH_MONO,...
%                     'parent', obj.hspp, 'hittest', 'off');
%                 scatter(rgx, rgy, obj.WIDTH_MONO, parula(ns),...
%                     'parent', obj.hsp2, 'hittest', 'off');
%             end            
            
            if obj.ShowAvgEyes
                
                % average x
                scatter(t, agx, obj.WIDTH_BINO,...
                    'parent', obj.hspx, 'hittest', 'off');
                scatter(t(obj.pSelected), agx(obj.pSelected),...
                    obj.WIDTH_SELECTED, obj.COL_SELECTED,...
                    'parent', obj.hspx, 'hittest', 'off');
                
                % average y
                scatter(t, agy, obj.WIDTH_BINO,...
                    'parent', obj.hspy, 'hittest', 'off');
                
                % average pupil
                scatter(t, ap, obj.WIDTH_BINO,...
                    'parent', obj.hspp, 'hittest', 'off');
                
                % 2D gaze
                scatter(agx, agy, obj.WIDTH_BINO, parula(ns),...
                    'parent', obj.hsp2, 'hittest', 'off');
                
            end
            
            % draw cursor
            cx = obj.CursorTime;
            obj.hCursorx = line([cx, cx], [0, 1], 'color', obj.COL_CURSOR,...
                'parent', obj.hspx);
            obj.hCursory = line([cx, cx], [0, 1], 'color', obj.COL_CURSOR,...
                'parent', obj.hspy);
            obj.hCursorp = line([cx, cx], get(obj.hspp, 'ylim'), 'color', obj.COL_CURSOR,...
                'parent', obj.hspp);
            
            hold(obj.hspx, 'off')
            hold(obj.hspy, 'off')
            hold(obj.hspp, 'off')
            hold(obj.hsp2, 'off')
            
            set(obj.hspx, 'buttondownfcn', @obj.timeSeriesButtonDown);
            set(obj.hspy, 'buttondownfcn', @obj.timeSeriesButtonDown);
            set(obj.hspp, 'buttondownfcn', @obj.timeSeriesButtonDown);
            
            %% CONTROLS
            
            % time control panel
            pos = get(obj.hspx, 'position');
            pnlTime = uipanel('position', [pos(1), .01, pos(3), .055],...
                'BorderType', 'none', 'units', 'normalized');
            
            % time control buttons
            nBtn = 4;
            btnW = .08;
            btnH = 1;
            btnX = 0:btnW:btnW;
            btnX = [btnX, 1 - btnX - btnW];
            btnPos = [btnX', repmat([0, btnW, btnH], nBtn, 1)];
            
            btnBack = uicontrol(...
                'style', 'pushbutton',...
                'parent', pnlTime,...
                'units', 'normalized',...
                'position', btnPos(1, :),...
                'string', '<',...
                'callback', @obj.btnBack_Down);
            
            btnForward = uicontrol(...
                'style', 'pushbutton',...
                'parent', pnlTime,...
                'units', 'normalized',...
                'position', btnPos(2, :),...
                'string', '>',...
                'callback', @obj.btnForward_Down);
        
            btnZoomOut = uicontrol(...
                'style', 'pushbutton',...
                'parent', pnlTime,...
                'units', 'normalized',...
                'position', btnPos(3, :),...
                'string', '-',...
                'callback', @obj.btnZoomOut_Down);
        
            btnZoomIn = uicontrol(...
                'style', 'pushbutton',...
                'parent', pnlTime,...
                'units', 'normalized',...
                'position', btnPos(4, :),...
                'string', '+',...
                'callback', @obj.btnZoomIn_Down);
            
            % time slider
            sldPos = [btnW * 2, 0, 1 - (btnW * nBtn), 1];
%             sldTime = javax.swing.JSlider;
%             javacomponent(sldTime, sldPos);

            sldTime = uicontrol(...
                'style', 'slider',...
                'parent', pnlTime,...
                'units', 'normalized',...
                'position', sldPos,...
                'min', obj.Data.Time(1),...
                'max', obj.Data.Time(end),...
                'value', obj.VisibleStart + obj.CursorTime,...
                'callback', @obj.sldTime_Change);
            sldTime = obj.setSliderStep(sldTime);
            
            set(gcf, 'pointer', 'arrow')
            
        end
        
        % get/set
        
        function obj = set.VisibleTime(obj, newVal)
            
            % if requested visible time is greater than the duration of
            % data, set the visibile time to the duration of data
            if newVal > max(obj.Data.Time)
                newVal = max(obj.Data.Time);
            end
            
            % if a new a visible time 
            if newVal - obj.VisibleStart > max(obj.Data.Time)
                obj.VisibleStart = max(obj.Data.Time) - newVal;
            end
            
            obj.VisibleTime = newVal;
            
            obj.DrawUI;
            
        end
        
        function obj = set.VisibleStart(obj, newVal)
            
            % if requested 
            if newVal > max(obj.Data.Time) - obj.VisibleTime
                newVal = max(obj.Data.Time) - obj.VisibleTime;
            end     
            
            obj.VisibleStart = newVal;
            
            obj.DrawUI;
            
        end
        
        function obj = set.CursorTime(obj, newVal)
            
            % check bounds
            if newVal > obj.VisibleStart + obj.VisibleTime
                newVal =  obj.VisibleStart + obj.VisibleTime;
            end
            
            if newVal < obj.VisibleStart
                newVal = obj.VisibleStart;
            end
            
            % set 
            obj.CursorTime = newVal;
            
            % update selection of samples around cursor
            obj = obj.updateSelection(newVal);
            
            % move cursor line object
            set(obj.hCursorx, 'xdata', [newVal, newVal]);
            set(obj.hCursory, 'xdata', [newVal, newVal]);
            set(obj.hCursorp, 'xdata', [newVal, newVal]);

        end
        
        function newVal = get.Selected(obj)
            
            newVal = obj.pSelected;
            
        end
        
        function obj = set.Selected(obj, newVal)
            
            if ~isequal(size(newVal), size(t)) || ~islogical(newVal)
                error('Selection must be a logical vector with a length of .VisibleTime')
            end
            
            obj.pSelected = newVal;
            
        end
        
        function newVal = get.DataLoaded(obj)
            
            newVal = ~isempty(obj.Data) && isa(obj.Data, 'etData');
            
        end
                             
    end   
    
    methods (Access = private)
        
        function sld = setSliderStep(obj, sld)
            
            set(sld, 'sliderstep', [...
                (.2 * obj.VisibleTime) / obj.Data.Time(end),...
                obj.VisibleTime / obj.Data.Time(end)]);
            
        end
        
        function obj = updateSelection(obj, newTime)
            
            if obj.DataLoaded 
                t = obj.Data.Time + obj.VisibleStart;
                obj.pSelected = abs(t - newTime) <= obj.CursorWidth;
            end
            
        end
        
        function obj = timeSeriesButtonDown(obj, src, ~)
            
            % get position of mouse pointer, set cursor to this
            mousePos = get(src,'CurrentPoint');
            obj.CursorTime = mousePos(1, 1);
                        
        end
        
        function obj = btnBack_Down(obj, ~, ~)
            
            obj.VisibleStart = obj.VisibleStart - (.2 * obj.VisibleTime);
                        
        end
        
        function obj = btnForward_Down(obj, ~, ~)
            
            obj.VisibleStart = obj.VisibleStart + (.2 * obj.VisibleTime);
                        
        end        
        
        function obj = btnZoomIn_Down(obj, ~, ~)
            
            obj.VisibleTime = obj.VisibleTime / 2;
                        
        end            
        
        function obj = btnZoomOut_Down(obj, ~, ~)
            
            obj.VisibleTime = obj.VisibleTime * 2;
                        
        end
        
        function obj = sldTime_Change(obj, src, ~)
            
            get(src, 'value')
            obj.VisibleStart = get(src, 'value');
                        
        end
        
    end
    
end

