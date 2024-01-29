% version 1.0 20170524
% version 2.0 20180708

classdef ECKETVis2 < handle
        
    properties
        temp
        FPS                     =   25
        Conditions
        ChannelLabelFontSize    =   16
        InfoPaneSize            =   [200, 150]
        InfoPaneFontSize        =   13
        DrawGaze                =   true
        DrawStimulus            =   true
        StimulusGreyscale       =   true
        DrawInfoPane            =   true
        DrawTimeLine            =   true
        DrawHeatmap             =   true
        HeatmapColorMap         =   parula
        GazePointSize           =   6
        HeatmapWorkRes          =   50
        HeatmapResScale         =   .1
        HeatmapAlpha            =   .5
        DrawQuiver              =   true
        QuiverFrameSpan         =   2
        QuiverAlpha             =   .4
        Col_Series              =   [255, 255, 255]
        Col_BG                  =   [000, 000, 000]
        Col_FG                  =   [240, 240, 240]
        Col_ChanBG              =   [020, 020, 020]
        Col_Axis                =   [100, 100, 100]
        Col_LabelBG             =   [040, 020, 100]
        Col_Label               =   [250, 210, 040]
        Col_Hover               =   [250, 210, 040]
        Col_ArtefactLine        =   [230, 040, 040]
        Col_ArtefactBG          =   [040, 020, 020]
        Col_InterpLine          =   [000, 189, 114]
        Col_InterpBG            =   [050, 050, 020]  
        Col_CantInterpBG        =   [080, 020, 020]
        Col_FlagBad             =   [185, 010, 010]
        Col_FlagGood            =   [010, 185, 010]
        DrawPlaneMaxSize        =   40000
        DivTree                 =   270
        DivAOI                  =   0.80
        DivTime                 =   0.10
        FrameTimeEventLabel     =   'NATSCENES_FRAME_30_FRAME_CALC';
    end
    
    properties (SetAccess = private)
        X
        Y
        Valid
    end
    
    properties (Access = private)
        % general / state
        prState
        prStat
        prTime = 0
        prIsPanning = false
        prWidth
        prHeight
        prSel
        prSelValid = false
        prSelLabel = '<none>'
        prTimer
        
        % PTB
        prWinPtr
        prScreenOpen 
        prScreenNumber
        prWindowSize
        prLastWindowSize
        prPTBOldSyncTests
        prPTBOldWarningFlag
        prAlphaShader
        
        % UI
        prFig
        prPos_Fig
        prFigOpen = false
        prDataTree
        prNodRoot
        prPnlAOIDef
        prPnlAOIScores
        prPnlStim
        prPos_Tree
        prPos_AOIDef
        prPos_AOIScores
        prPos_Stim
        prMouseX
        prMouseY
        prMouseButtons
        prLblStimStatus
        prPos_lblStimStatus
        prPos_btnSetStimMovie
        prPos_btnSetStimImage
        prPos_btnClearStim
        prBtnSetStimMovie
        prBtnSetStimImage
        prBtnClearStim
        prStimImagePrevDir
        prStimMoviePrevDir
        prPos_tblAOI
        prPos_lblAOIDef
        prPos_btnAddAOI
        prPos_btnRemoveAOI
        prPos_btnClearAOIs
        prPos_btnFolderAOIs
        prPos_lblAOIScores
        prPos_btnScoreAOIs
        prPos_btnClearAOIScores
        prPos_btnSaveAOIScores
        prPos_btnLoadAOIScores
        prPos_PnlAOIAnalysis
        prPos_AxsAOITimeSeries
        prPos_AxsAOIMeans
        prPos_AxsAOIHist
        prPos_TblAOIValues
        prTblAOI
        prLblAOIDef
        prBtnAddAOI
        prBtnRemoveAOI
        prBtnClearAOI
        prBtnFolderAOIs
        prLblAOIScores
        prBtnScoreAOIs
        prBtnClearAOIScores
        prBtnLoadAOIScores
        prBtnSaveAOIScores
        prPnlAOIAnalysis
        prPnlAOIDisabled
        prAxsAOITimeSeries
        prAxsAOIMeans
        prAxsAOIHist
        prTblAOIValues
        prRecCursor
        prSegTV_rootNode
        
        % drawing
        prWaitToDraw = false
        prZoom
        prDrawSize
        prDrawOffset = [0, 0]
        prARFactor = 1
        prDrawFocus
        prFullscreen
        prDrawingPrepared = false
        prFrame = 1
        prMaxFrames
        prCoords
        prCoordsNorm
        prCoordsCol
        prQuiv
        prTimeLineValid = false
        prTimeLineX
        prTimeLineY
        
        % stimulus/screen
        prStimValid = false;
        prStimType 
        prStimMovPtr
        prStimMovDur
        prStimMovFPS
        prStimMovW
        prStimMovH
        prStimMovFrames
        prStimImg
        prStimImgTexPtr
        prStimPath
        prStimAR
        prStimScale = [1, 1];
        prStimDrawSize
        prStimTexPtr
        prHeatmaps
        prHeatmapsAlpha
        prHeatmapsPrepared = false
        
        % data
        prData
        prNumData
        prDataType
        prDataValid = false
        prFT
        prFN
        prResultsValid = false
        prRes_AOITimeSeries
        prRes_AOIMeans
        prRes_SubjectMeans
        prResults

        % AOIs
        prAOIs
        prAOIValid = false
        prAOIColourOrder
        prAOIColourIndex
        prAOITex
        prAOIScoreValid = false
        prAOIScores
        prAOIScoresDirty = false
    end
    
    properties (Dependent)
        Data
        ScreenNumber
        WindowSize 
        Fullscreen
        Zoom
        Frame
        Time
        AspectRatio
    end
    
    properties (Dependent, SetAccess = private)
        State
        Error
        Duration
        TimeString
        StimulusResolution
        AOIs
        AOINames
        Results     
        Selection
    end
    
    methods 
        
        %% general
        
        % constructor
        function obj = ECKETVis2
            
            warning('25FPS hard-coded - change if this is not right!')
            
            % status
            obj.prStat = ECKStatus('ECK ET Visualiser starting up...');
            
            % check PTB
            AssertOpenGL
            
            % disable sync tests and set PTB verbosity to minimum
            obj.prPTBOldSyncTests =...
                Screen('Preference', 'SkipSyncTests', 2);
            obj.prPTBOldWarningFlag =...
                Screen('Preference', 'SuppressAllWarnings', 1);
            
            % screen defaults
            obj.prScreenOpen = false;
            obj.prScreenNumber = max(Screen('screens'));
            if obj.prScreenNumber == 0
                % small window as only one screen
                obj.prWindowSize = round(...
                    Screen('Rect', obj.prScreenNumber) .* .4);
                obj.prFullscreen = false;
            else
                % fullscreen
                obj.prWindowSize = Screen('Rect', obj.prScreenNumber);
                obj.prFullscreen = true;
            end
                       
            % open screen
            obj.OpenScreen
            
            % UI
            set(0, 'DefaultTextInterpreter', 'none')
            obj.prFig = figure(...
                'NumberTitle',          'off',...
                'Units',                'normalized',...
                'Position',             obj.prPos_Fig,...
                'Menubar',              'none',...
                'Toolbar',              'none',...
                'Name',                 'ET Visualiser',...
                'DeleteFcn',            @(obj)obj.delete,...
                'ResizeFcn',            @obj.Figure_Resize,...
                'visible',              'off',...
                'renderer',             'opengl');
            obj.prFigOpen = true;
            set(obj.prFig, 'Units', 'Pixels')
            
            % UI panel positions
            obj.UpdateUIPositions
                        
            % panels
            obj.prPnlStim = uipanel(...
                'parent',               obj.prFig,...
                'units',                'pixels',...
                'visible',              'on',...
                'bordertype',           'none',...
                'position',             obj.prPos_Stim);
            obj.prPnlAOIDef = uipanel(...
                'parent',               obj.prFig,...
                'units',                'pixels',...
                'visible',              'on',...
                'bordertype',           'none',...
                'position',             obj.prPos_AOIDef);
            obj.prPnlAOIScores = uipanel(...
                'parent',               obj.prFig,...
                'units',                'pixels',...
                'visible',              'on',...
                'bordertype',           'none',...
                'position',             obj.prPos_AOIScores);
            obj.prPnlAOIAnalysis = uipanel(...
                'parent',               obj.prFig,...
                'units',                'pixels',...
                'visible',              'on',...
                'bordertype',           'none',...
                'visible',              'off',...
                'position',             obj.prPos_PnlAOIAnalysis);
            obj.prPnlAOIDisabled = uipanel(...
                'parent',               obj.prFig,...
                'units',                'pixels',...
                'visible',              'on',...
                'bordertype',           'none',...
                'title',                'AOI Score Not Run',...
                'visible',              'on',...
                'position',             obj.prPos_PnlAOIAnalysis);            
            
            % AOI analysis
            obj.prAxsAOITimeSeries = axes(...
                'parent',               obj.prPnlAOIAnalysis,...
                'units',                'pixels',...
                'visible',              'on',...
                'color',                obj.Col_BG,...
                'position',             obj.prPos_AxsAOITimeSeries);   
            obj.prAxsAOIMeans = axes(...
                'parent',               obj.prPnlAOIAnalysis,...
                'units',                'pixels',...
                'color',                obj.Col_BG,...
                'visible',              'on',...
                'position',             obj.prPos_AxsAOIMeans);  
            obj.prAxsAOIHist = axes(...
                'parent',               obj.prPnlAOIAnalysis,...
                'units',                'pixels',...
                'color',                obj.Col_BG,...
                'visible',              'on',...
                'position',             obj.prPos_AxsAOIHist);   
            aoivalColNames =       {'AOI Name',    'Time (s)', 'Prop',     'Missing'   };
            aoivalColFormats =     {'char',        'numeric',  'numeric', 'numeric'    };
            obj.prTblAOIValues = uitable(...
                'parent',                   obj.prPnlAOIAnalysis,...
                'units',                    'pixels',...
                'position',                 obj.prPos_TblAOIValues,...
                'fontsize',                 12,...
                'cellselectioncallback',    @obj.tblAOIValues_Select,...
                'columnname',               aoivalColNames,...
                'columnformat',             aoivalColFormats);            
            
            % stimulus 
            str = 'Stimulus overlay: not present';
            obj.prLblStimStatus = uicontrol(...
                'parent',               obj.prPnlStim,...
                'style',                'text',...
                'string',               str,...
                'position',             obj.prPos_lblStimStatus,...
                'horizontalalignment',  'left',...
                'foregroundcolor',      [0.80, 0.00, 0.00],...
                'fontsize',             12,...
                'fontweight',           'bold');
            obj.prBtnClearStim = uicontrol(...
                'parent',               obj.prPnlStim,...
                'style',                'pushbutton',...
                'string',               'Clear',...
                'fontsize',             12,...
                'position',             obj.prPos_btnClearStim,...
                'enable',               'off',...
                'callback',             @obj.btnClearStim_Click);
            obj.prBtnSetStimImage = uicontrol(...
                'parent',               obj.prPnlStim,...
                'style',                'pushbutton',...
                'string',               'Set Image',...
                'fontsize',             12,...
                'position',             obj.prPos_btnSetStimImage,...
                'callback',             @obj.btnSetStimImage_Click);
            obj.prBtnSetStimMovie = uicontrol(...
                'parent',               obj.prPnlStim,...
                'style',                'pushbutton',...
                'string',               'Set Movie',...
                'fontsize',             12,...
                'position',             obj.prPos_btnSetStimMovie,...
                'callback',             @obj.btnSetStimMovie_Click);            
            obj.UpdateData
            
            % AOI def
            aoiTypes =          {'RECT', 'STATIC MASK', 'DYNAMIC MASK'};
            aoiColNames =       {'Visible', 'Name', 'Type',     'Colour'    };
            aoiColFormats =     {'logical', 'char', aoiTypes,   'char'      };
            aoiColEditable =    [true,      true,   true,       true        ];
            obj.prTblAOI = uitable(...
                'parent',                   obj.prPnlAOIDef,...
                'position',                 obj.prPos_tblAOI,...
                'fontsize',                 12,...
                'celleditcallback',         @obj.tblAOI_EditCell,...
                'cellselectioncallback',    @obj.tblAOI_Select,...
                'columnname',               aoiColNames,...
                'columneditable',           aoiColEditable,...
                'columnformat',             aoiColFormats);
            str = 'AOI Definitions: not present';
            obj.prLblAOIDef = uicontrol(...
                'parent',               obj.prPnlAOIDef,...
                'style',                'text',...
                'string',               str,...
                'position',             obj.prPos_lblAOIDef,...
                'horizontalalignment',  'left',...
                'foregroundcolor',      [0.80, 0.00, 0.00],...
                'fontsize',             12,...
                'fontweight',           'bold');            
            obj.prBtnAddAOI = uicontrol(...
                'enable',               'off',...
                'parent',               obj.prPnlAOIDef,...
                'style',                'pushbutton',...
                'string',               'Add',...
                'fontsize',             12,...
                'position',             obj.prPos_btnAddAOI,...
                'callback',             @obj.btnAddAOI_Click);  
            obj.prBtnRemoveAOI = uicontrol(...
                'enable',               'off',...
                'parent',               obj.prPnlAOIDef,...
                'style',                'pushbutton',...
                'string',               'Remove',...
                'fontsize',             12,...
                'position',             obj.prPos_btnRemoveAOI,...
                'callback',             @obj.btnRemoveAOI_Click);              
            obj.prBtnClearAOI = uicontrol(...
                'enable',               'off',...
                'parent',               obj.prPnlAOIDef,...
                'style',                'pushbutton',...
                'string',               'Clear',...
                'fontsize',             12,...
                'position',             obj.prPos_btnClearAOIs,...
                'callback',             @obj.btnClearAOIs_Click);  
            obj.prBtnFolderAOIs = uicontrol(...
                'parent',               obj.prPnlAOIDef,...
                'style',                'pushbutton',...
                'string',               'Load',...
                'fontsize',             12,...
                'position',             obj.prPos_btnFolderAOIs,...
                'callback',             @obj.btnFolderAOIs_Click);
            
            % aoi scores
            str = 'AOI Scoring';
            obj.prLblAOIScores = uicontrol(...
                'parent',               obj.prPnlAOIScores,...
                'style',                'text',...
                'string',               str,...
                'position',             obj.prPos_lblAOIScores,...
                'horizontalalignment',  'left',...
                'fontsize',             12,...
                'fontweight',           'bold'); 
            obj.prBtnScoreAOIs = uicontrol(...
                'parent',               obj.prPnlAOIScores,...
                'style',                'pushbutton',...
                'string',               'Score',...
                'fontsize',             12,...
                'enable',               'on',...
                'position',             obj.prPos_btnScoreAOIs,...
                'callback',             @obj.btnScoreAOIs_Click);
            obj.prBtnClearAOIScores = uicontrol(...
                'parent',               obj.prPnlAOIScores,...
                'style',                'pushbutton',...
                'string',               'Clear',...
                'fontsize',             12,...
                'enable',               'off',...
                'position',             obj.prPos_btnClearAOIScores,...
                'callback',             @obj.btnClearAOIScores_Click); 
            obj.prBtnLoadAOIScores = uicontrol(...
                'parent',               obj.prPnlAOIScores,...
                'style',                'pushbutton',...
                'string',               'Load',...
                'fontsize',             12,...
                'position',             obj.prPos_btnLoadAOIScores,...
                'callback',             @obj.btnLoadAOIScores_Click);            
            obj.prBtnSaveAOIScores = uicontrol(...
                'parent',               obj.prPnlAOIScores,...
                'style',                'pushbutton',...
                'string',               'Save',...
                'fontsize',             12,...
                'enable',               'off',...
                'position',             obj.prPos_btnSaveAOIScores,...
                'callback',             @obj.btnSaveAOIScores_Click); 
            
            % segmentation treeview
            obj.prSegTV_rootNode = uitreenode('v0', 'ROOT', 'Segmentation',...
                [], false);
            % create blank tree
            obj.prDataTree = uitree('v0', 'Root', obj.prSegTV_rootNode,...
                'SelectionChangeFcn', {@obj.DataTree_Select},...
                'Position', obj.prPos_Tree);
            
            % default zoom to 100%
            obj.prDrawSize = obj.prWindowSize;
            obj.prDrawFocus = obj.prDrawSize(3:4) / 2;
            obj.Zoom = 1;

            set(obj.prFig, 'visible', 'on')
            
            obj.prStat.Status = '';
            
            % set AOI colour order
            obj.prAOIColourOrder = get(groot, 'DefaultAxesColorOrder');
            obj.prAOIColourIndex = 1;
            
            % set up timer
            obj.prTimer = timer(...
                'Period', 1 / 60,...
                'ExecutionMode', 'fixedDelay',...
                'TimerFcn', @obj.Listener,...
                'ErrorFcn', @obj.Listener_ERR);
            start(obj.prTimer)
        
        end
        
        % destructor
        function delete(obj)   
            
            disp('destructor')
            % stop and delete timer
            stop(obj.prTimer)
            delete(obj.prTimer)
            
            % close open screen
            if obj.prScreenOpen
                try
                    obj.CloseScreen
                catch ERR
                    disp(ERR)
%                     rethrow ERR
                end
            end
            
            % delete figure
            if obj.prFigOpen
                try
                    close(obj.prFig)
                catch ERR
                    disp(ERR)
%                     rethrow ERR
                end
            end
            
           % reset PTB prefs
            Screen('Preference', 'SkipSyncTests', obj.prPTBOldSyncTests);
            Screen('Preference', 'SuppressAllWarnings',...
                obj.prPTBOldWarningFlag);
            
        end
        
        % screen
        function OpenScreen(obj)
            
            if obj.prScreenOpen
                error('Screen already open.')
            end
            if obj.prFullscreen
                fullscreenFlag = [];
                rect = [];
                obj.prPos_Fig = [0, 0, .4, .6];
            else
                rect = obj.prWindowSize;
                fullscreenFlag = [];
                screenSize = Screen('Rect', obj.prScreenNumber);
                figPosPx = [...
                    obj.prWindowSize(1) + obj.prWindowSize(3),...
                    obj.prWindowSize(2),...
                    screenSize(3) - obj.prWindowSize(1) - obj.prWindowSize(3),...
                    screenSize(4)];
                obj.prPos_Fig = figPosPx ./ repmat(screenSize(3:4), 1, 2);
            end
            
            % resize figure if open
            if obj.prFigOpen
                set(obj.prFig, 'Units', 'normalized');
                set(obj.prFig, 'Position', obj.prPos_Fig);
                set(obj.prFig, 'Units', 'pixels');
            end
            
            % PTB
            obj.prWinPtr = Screen('OpenWindow', obj.prScreenNumber,...
                obj.Col_BG, rect, [], [], [], 1, [], fullscreenFlag);
            Screen('BlendFunction', obj.prWinPtr, GL_SRC_ALPHA,...
                GL_ONE_MINUS_SRC_ALPHA);
            Screen('Preference', 'TextAlphaBlending', 1)
            Screen('TextFont', obj.prWinPtr, 'Consolas');
            obj.prScreenOpen = true;
            
            % update any AOIs with winptr
            if ~isempty(obj.prAOIs)
                for a = 1:length(obj.prAOIs)
                    obj.prAOIs{a}.MaskWinPtr = obj.prWinPtr;
                end
            end
            
            % create shader to convert luminance channel to alpha
            obj.prAlphaShader = CreateSinglePassImageProcessingShader(...
                obj.prWinPtr, 'BackgroundMaskOut', [0, 0, 0], 10);
        
        end
        
        function CloseScreen(obj)
            if ~obj.prScreenOpen
                error('Screen is not open.')
            end
            Screen('Close', obj.prWinPtr);
            obj.prScreenOpen = false;
        end
        
        function ReopenScreen(obj)
            if obj.prScreenOpen
                obj.CloseScreen
                obj.OpenScreen
                obj.PrepareForDrawing
                obj.Draw
            end
        end   
        
        %% data
        
        function UpdateData(obj)
                        
            if isempty(obj.prData)
                obj.prDataValid = false;
                return
            end
            
            wb = waitbar(0, 'Preparing data...');

            %% build tree
            if ~isempty(obj.prDataTree)
                delete(obj.prDataTree)
            end
            
%             % root node
%             nodRoot = uitreenode('v0', 'ROOT', 'Segmentation',...
%                 [], false);
            
            % add segment nodes
            [segNames, ~, segSubs] = unique(obj.Data.addData);
            numSeg = length(segNames);
            nodSeg = cell(numSeg, 1);
            for s = 1:numSeg
                nodSeg{s} = uitreenode('v0', segNames{s},...
                    segNames{s}, [], false);
                obj.prSegTV_rootNode.add(nodSeg{s})
            end
            
            % add participant nodes
            waitbar(0, wb, 'Building segment tree');
            for d = 1:obj.Data.numIDs
                nodDat = uitreenode('v0', d, obj.Data.ids{d}, [], true);
                nodSeg{segSubs(d)}.add(nodDat)
                if mod(d, 100) == 0
                    waitbar(d / obj.prData.numIDs, wb);
                end
            end 
            
             %% align frame times
            
            if ~isfield(obj.prData, 'frameTimesAligned') ||...
                    ~obj.Data.frameTimesAligned
                % get data
                mb = obj.prData.mainBuffer;
                tb = obj.prData.timeBuffer;
                eb = obj.prData.eventBuffer;
                % temp output vars
                x = cell(obj.prData.numIDs, 1);
                y = cell(obj.prData.numIDs, 1);
                ft = cell(obj.prData.numIDs, 1);
                fn = cell(obj.prData.numIDs, 1);
                fttype = cell(obj.prData.numIDs, 1);
                wb = waitbar(0, wb, 'Aligning frametimes...');
                for d = 1:obj.prData.numIDs

                    % filter and average eyes
                    mb{d} = etFilterGazeOnscreen(mb{d});

                    % align
                    [xsamp, ysamp, ft{d}, fn{d}] = salAlignFrames(mb{d},...
                        tb{d}, eb{d}, obj.FrameTimeEventLabel);
                    
                    % take mean gaze point for each frame
                    x{d}(1:length(xsamp), 1) = cellfun(@nanmean, xsamp);
                    y{d}(1:length(ysamp), 1) = cellfun(@nanmean, ysamp);

                    % if no valid frame times, make virtual ones
                    if isempty(x{d}) || isempty(y{d})
                        fttype{d} = 'VIRTUAL';
                        % calculate duration of ET data in seconds
                        dur = double(tb{d}(end, 1) - tb{d}(1, 1)) / 1e6;
                        % calculate number of needed frames
                        tmpNumFrames = round(dur * obj.FPS);
                        spf = 1 / obj.FPS;
                        % calculate virtual frame times
                        ft{d} = (0:spf:dur)';
                        fn{d} = (1:tmpNumFrames)';
                        % convert frame times to ET remote times
                        firstTimeRemote = tb{d}(1, 1);
                        ft_rem = firstTimeRemote + uint64((ft{d} * 1e6));
                        % get sample numbers from remote times
%                         st = arrayfun(@(x) etTimeToSample(tb{d}, x), ft_rem);
                        st = etTimeToSample(tb{d}, ft_rem);
                        % get gaze data from samples
                        [gx, gy, ~] = etAverageEyeBuffer(mb{d});
                        x{d} = gx(st);
                        y{d} = gy(st);
                    else
                        fttype{d} = 'CALCULATED';
                    end

                    if mod(d, 20) == 0
                        waitbar(d / obj.prData.numIDs, wb,...
                            sprintf('Aligning frametimes [%d of %d]',...
                            d, obj.prData.numIDs));
                    end
                end
                obj.prData.x = x;
                obj.prData.y = y;
                obj.prData.ft = ft;
                obj.prData.fn = fn;
                obj.prData.frameTimesAligned = true;

                % offer to save aligned data
                resp = questdlg('Save data with aligned frametimes?',...
                    'Save', 'Yes', 'No', 'Yes');
                if strcmpi(resp, 'YES')
                    savePath = uiputfile;
                    if ~(isnumeric(savePath) && savePath == 0)
                        seg = obj.prData;
                        save(savePath, 'seg', '-v7.3')
                        clear seg
                    end
                end
                
            end
            obj.prDataValid = true;
            close(wb)

        end
        
        function UpdateSelection(obj, sel)
            obj.ClearAOIScores;
            obj.ClearAOIs;
            obj.ClearStimulusImage;
            selIdx = find(sel);
            val = obj.prData.addData{selIdx(1)};
            obj.prSelLabel = val;
            % do aoi lookup
            if isfield(obj.prData, 'aoiLookup') &&...
                    ~isempty(obj.prData.aoiLookup)
                found = find(strcmpi(obj.Data.aoiLookup(:, 1),...
                    val));
                if ~isempty(found)
                    num = length(found);
                    aoiName = obj.Data.aoiLookup(found, 2);
                    aoiPath = obj.Data.aoiLookup(found, 3);
                    aoiType = obj.Data.aoiLookup(found, 4);
                    aoi = cell(num, 1);
                    for a = 1:num
                        switch aoiType{a}
                            case 'STATIC MASK'
                                aoi{a} = ECKAOI2;
                                aoi{a}.Name = aoiName{a};
                                aoi{a}.MaskWinPtr = obj.prWinPtr;
                                aoi{a}.SetStaticMask(aoiPath{a})
                            otherwise
                                error('Not yet implemented.')
                        end
                    end
                    obj.AddAOI(aoi)
                end
            end
            % do stim lookup
            if isfield(obj.prData, 'stimLookup') &&...
                    ~isempty(obj.prData.stimLookup)
                found = find(strcmpi(obj.Data.stimLookup(:, 1),...
                    val));
                if ~isempty(found)
                    obj.ClearStimulusImage;
                    stimPath = obj.Data.stimLookup{found, 2};
                    obj.SetStimulusImage(stimPath);
                end
            end
            % set selection flags
            obj.prSel = sel;
            obj.prSelValid = true;
            obj.prWaitToDraw = false;
            obj.PrepareForDrawing
            obj.Draw
            % get x and y coords
            dx          = obj.prData.x(obj.prSel);
            dy          = obj.prData.y(obj.prSel);
            numSel      = sum(obj.prSel);
            numFrames   = obj.prMaxFrames;
            obj.X       = nan(numFrames, numSel);
            obj.Y       = nan(numFrames, numSel);
            obj.Valid   = nan(numFrames, numSel);
%             fprintf('Preparing')
            for s = 1:numSel
%                 fprintf('%d\n', s)
                obj.X       (1:length(dx{s}), s) = dx{s};
                obj.Y       (1:length(dy{s}), s) = dy{s};
                obj.Valid   (1:length(dy{s}), s) = isnan(dx{s}) | isnan(dy{s});
            end
%             fprintf('done')
        end
        
        function fp = DataFingerprint(obj)
            if ~obj.prDataValid 
                error('No valid data')
            end
            if ~obj.prSelValid
                error('Must select some data.')
            end
            fpMb = sum(cellfun(@(x) sum(x(:)), obj.Data.mainBuffer(obj.prSel)));
            fpTb = sum(cellfun(@(x) sum(x(:)), obj.Data.timeBuffer(obj.prSel)));
            fp = num2str(fpMb / fpTb, '%.100f');
        end
        
        function ClearResults(obj)
            obj.prResults = [];
        end
        
        %% stimulus
        function SetStimulusImage(obj, path)
            % check path
            if ~exist(path, 'file')
                error('Path does not exist.')
            end
            % attempt to load
            try
                obj.prStimImg = imread(path);
                obj.prStimImgTexPtr = Screen('MakeTexture',...
                    obj.prWinPtr, obj.prStimImg);
            catch ERR
                error('Error whilst loading image: \n\n%s', ERR.message)
            end
            obj.prStimType = 'IMAGE';
            w = size(obj.prStimImg, 2);
            h = size(obj.prStimImg, 1);
            stimAR = w / h;
            drawAR = (obj.prDrawSize(3) - obj.prDrawSize(1)) /...
                (obj.prDrawSize(4) - obj.prDrawSize(2));
            if stimAR ~= drawAR
                if stimAR > 1           % wide
                    obj.prStimScale = [1, 1 / stimAR];
                elseif stimAR < 1       % tall
                    obj.prStimScale = [1 / stimAR, 1];
                end
            end
            obj.prStimValid = true;
            obj.PrepareForDrawing
            obj.Draw
        end
        
        function SetStimulusMovie(obj, path)
            if ~exist(path, 'file')
                error('Path does not exist.')
            end
            % attempt to load
            try
                if obj.StimulusGreyscale
                    pixelFormat = 1;
                else
                    pixelFormat = [];
                end
                [obj.prStimMovPtr, obj.prStimMovDur,...
                    obj.prStimMovFPS, obj.prStimMovW,...
                    obj.prStimMovH, obj.prStimMovFrames] =...
                    Screen('OpenMovie', obj.prWinPtr, path, [],...
                        [], [], pixelFormat);
                obj.prFrame = 1;
                Screen('SetMovieTimeIndex', obj.prStimMovPtr, 0);
            catch ERR
                error('Error whilst loading video: \n\n%s', ERR.message)
            end
            obj.prStimType = 'MOVIE';
            stimAR = obj.prStimMovW / obj.prStimMovH;
            drawAR = (obj.prDrawSize(3) - obj.prDrawSize(1)) /...
                (obj.prDrawSize(4) - obj.prDrawSize(2));
            if stimAR ~= drawAR
                if stimAR > 1           % wide
                    obj.prStimScale = [1, 1 / stimAR];
                elseif stimAR < 1       % tall
                    obj.prStimScale = [1 / stimAR, 1];
                end
            end
            obj.prStimValid = true;
            obj.PrepareForDrawing
            obj.Draw            
        end
            
        function ClearStimulusImage(obj)
            obj.prStimValid = false;
            obj.prStimDrawSize = [];
            obj.prStimAR = [];
            obj.prStimType = [];
            obj.prStimImg = [];
            obj.prStimTexPtr = [];
            obj.prStimPath = [];
            obj.prStimMovPtr = [];
            obj.prStimMovDur = [];
            obj.prStimMovW = [];
            obj.prStimMovH = [];
            obj.prStimMovFPS = [];
            obj.prStimMovFrames = [];
            obj.Draw
        end
        
        function UpdateStimulusStatus(obj)
            switch obj.prStimValid
                case true
                    str = sprintf('valid [%s]', obj.prStimType);
                    col = [0.00, 0.80, 0.00];
                    set(obj.prBtnClearStim, 'enable', 'on');
                    set(obj.prBtnSetStimImage, 'enable', 'off');
                    set(obj.prBtnSetStimMovie, 'enable', 'off');
                case false
                    str = 'not present';
                    col = [0.80, 0.00, 0.00];
                    set(obj.prBtnClearStim, 'enable', 'off');
                    set(obj.prBtnSetStimImage, 'enable', 'on');
                    set(obj.prBtnSetStimMovie, 'enable', 'on');                    
            end
            set(obj.prLblStimStatus, 'string',...
                sprintf('Stimulus overlay: %s', str),...
                'foregroundcolor', col);
        end
        
        %% aoi
        function AddAOI(obj, val)
            if ~iscell(val), val = {val}; end
            if all(cellfun(@(x) isa(x, 'ECKAOI2'), val))
                for a = 1:length(val)
                    % set the vis' winptr
                    if obj.prScreenOpen
                        val{a}.MaskWinPtr = obj.prWinPtr;
                    end
                    idx = length(obj.prAOIs) + 1;
                    % update the colour, if it hasn't been specified
                    if val{a}.ColourOnDefault
                        obj.prAOIColourIndex = obj.prAOIColourIndex + 1;
                        val{a}.Colour =...
                            obj.prAOIColourOrder(obj.prAOIColourIndex, :)...
                            * 255;
                    end
                    % check that the onset/offset times are in bounds,
                    % otherwise adjust
                    timesAdjusted = false;
                    if val{a}.OnsetTime < 0
                        val{a}.OnsetTime = 0;
                        timesAdjusted = true;
                    end
                    if val{a}.OffsetTime > obj.Duration
                        val{a}.OffsetTime = obj.Duration;
                        timesAdjusted = true;
                    end
                    if timesAdjusted
                        warning('AOI onset/offset times were adjusted to be within bounds of the data.')
                    end
                    % store AOI
                    obj.prAOIs{idx} = val{a};
                end
            else 
                error('AOIs must be defined as ECKAOI2 objects')
            end
            obj.UpdateAOIs
            obj.Draw
        end
        
        function AddDynamicAOIFromFolder(obj, path)
            if ~exist(path, 'dir')
                error('Path not found.')
            end
            
            % find video files
            allFiles = recdir(path, 1);                                     % get all files
            fileMask = {'.mp4', '.mov', '.avi'};
            [pth, name, ext] = cellfun(@fileparts, allFiles, 'uniform',...  % get exts
                false);
            found = cellfun(@(x) any(strcmpi(fileMask, x)), ext);           % filter ext
            found = found & strncmpi(name, 'aoi_', 4);                      % filter 'aoi_'
            foundPaths = allFiles(found);
            foundFiles = name(found);
            if isempty(foundPaths) 
                error('No AOI folders found in path.')
            end
            
            num = length(foundPaths);
            for a = 1:num
                aoi = ECKAOI2;
                aoi.MaskWinPtr = obj.prWinPtr;
                aoi.SetDynamicMask(foundPaths{a}, foundFiles{a});
                aoi.Colour = round(obj.prAOIColourOrder(...
                    obj.prAOIColourIndex, :) * 255);
                obj.prAOIColourIndex = obj.prAOIColourIndex + 1;
                obj.AddAOI(aoi);
            end
            obj.UpdateAOIs;
        end
            
        function ClearAOIs(obj)
            obj.prAOIValid = false;
            obj.prAOIs = [];
            obj.prAOIColourIndex= 1;
            obj.UpdateAOIs
            obj.Draw
        end
        
        function RemoveAOI(obj, idx)
            if idx <= length(obj.prAOIs)
                obj.prAOIs(idx) = [];
                obj.UpdateAOIs
            else
                error('Index out of bounds.')
            end
        end
        
        function [suc, oc, lab] = ScoreAOIs(obj)
            % default return values
            oc = 'Unknown error';
            lab = obj.prSelLabel;
            suc = false;
            
            obj.prAOIScoreValid = false;
            if isempty(obj.prAOIs)
                oc = 'No AOIs defined';
                suc = false;
                return
            end
            if ~obj.prSelValid
                oc = 'Selection not valid';
                suc = false;
                return
            end
            wb = waitbar(0, 'Scoring AOIs...');
            obj.PrepareForDrawing
            % get numbers and prepare output var
            numData = sum(obj.prSel);
            
%             % ////////////////////////////////////////////////////////
%             % temp ugly solution to shiftdim not working when only one
%             % subject has data
%             if numData == 1
%                 oc = 'Scoring AOIs with dataset of N=1 doesnt work';
%                 suc = false;
%                 return
%             end
%             % ////////////////////////////////////////////////////////            
            
            numFrames = obj.prMaxFrames;
            numAOIs = length(obj.prAOIs);     
            scores = zeros(numData, numFrames, numAOIs);
            % get x and y gaze coords in a 2D [ID, frame] matrix
            x = shiftdim(obj.prCoordsNorm(1, :, :));
            y = shiftdim(obj.prCoordsNorm(2, :, :));
            % if only one subject is selected, shiftdim doesn't work
            % properly, so correct the shape of the matrix
            if numData == 1, x = x'; y = y'; end
            % make time vector to pass to AOIs
            t = 1 / obj.FPS:1 / obj.FPS:obj.Duration;
            % loop through AOIs
            for a = 1:numAOIs
                msg = sprintf('Scoring AOIs... [%s]', obj.prAOIs{a}.Name);
                wb = waitbar(a / numAOIs, wb, msg);
                res = obj.AOIs{a}.Score(t, x, y);
                scores(:, :, a) = res;
            end
            % update state
            suc = true;
            oc = 'OK';
            obj.prAOIScoreValid = true;
            obj.prAOIScores = scores;
            obj.prAOIScoresDirty = true;
            obj.prResults = [];   % clear cache
            close(wb)
            obj.PrepareForDrawing
            obj.Draw
        end
        
        function [res, suc, oc, lab] = BatchScoreAOIs(obj)
            % find unique segments
            [su, ~, si] = unique(obj.prData.addData);
            numSegs = length(su);
            res = cell(numSegs, 1);
            lab = cell(numSegs, 1);
            oc  = cell(numSegs, 1);
            suc = false(numSegs, 1);
            % loop through segments and process
            wb = waitbar(0, 'Batch scoring AOIs...');
            for s = 1:numSegs
                sel = si == s;
                obj.UpdateSelection(sel);
                [suc(s), oc{s}, lab{s}] = obj.ScoreAOIs;
                res{s} = obj.Results;
                wb = waitbar(s / numSegs, wb);
            end
            close(wb)
        end
        
        function SaveAOIScores(obj, path_out)
            if ~obj.prAOIScoreValid
                error('AOIs not yet scored.')
            end
            if ~exist('path_out', 'var') || isempty(path_out)
                defFilename = sprintf('aoiscores_%s.mat',...
                    datetimeStr);
                [file, pth] = uiputfile({'*.mat', 'Matlab files'},...
                    'Save AOI scores', defFilename);
                if isequal(file, 0), return, end    % user cancel
                path_out = fullfile(pth, file);
            end
            aoiscores.type = 'ETVIS:AOISCORES';
            aoiscores.data = obj.prAOIScores;
            aoiscores.fingerprint = obj.DataFingerprint;
            aoiscores.aoitable = obj.AOITable;
            save(path_out, 'aoiscores');
            obj.prAOIScoresDirty = false;
        end
                        
        function LoadAOIScores(obj, path_in)
            obj.CheckAOIsDirty
            % get filename
            if ~exist('path_in', 'var') || isempty(path_in)
                [file, pth] = uigetfile({'*.mat', 'Matlab files'},...
                    'Load AOI scores');
                if isequal(file, 0), return, end    % user cancel
                path_in = fullfile(pth, file);
            end
            % check file
            if ~exist(path_in, 'file')
                error('File not found.')
            end
            try
                load(path_in);
            catch ERR
                error('Error reading file: \n\n%s', ERR.message)
            end
            % check data validity
            if...
                    ~exist('aoiscores', 'var') ||...
                    ~isstruct(aoiscores) ||...
                    ~isfield(aoiscores, 'type') ||...
                    ~strcmpi(aoiscores.type, 'ETVIS:AOISCORES') ||...
                    ~isfield(aoiscores, 'aoitable') ||...
                    isempty(aoiscores.aoitable) ||...
                    ~isfield(aoiscores, 'data') ||...
                    isempty(aoiscores.data)
                error('Invalid file format.')
            end
            % check data match
            if ~isequal(aoiscores.fingerprint, obj.DataFingerprint)
                error('AOI scores do not match currently loaded/selected data.')
            end
            if ~isequal(aoiscores.aoitable, obj.AOITable)
                error('AOI scores do not match current AOI definitions.')
            end
            % set
            obj.prAOIScoreValid = true;
            obj.prAOIScores = aoiscores.data;
            obj.prAOIScoresDirty = false;
            obj.UpdateAOIScoreDisplay
            obj.PrepareForDrawing
            obj.Draw
        end
        
        function ClearAOIScores(obj)
            obj.prAOIScoreValid = false;
            obj.prAOIScores = [];
            obj.UpdateAOIs
            obj.PrepareForDrawing
            obj.Draw
            obj.ShowHideAnalysisPanel
        end
        
        function CheckAOIsDirty(obj)
            % offer to save AOI scores if dirty
            if obj.prAOIScoresDirty && obj.prAOIScoreValid
                resp = questdlg('AOI scores have not been saved. Save now?',...
                    'Save current AOI scores?');
                switch resp
                    case 'Cancel'
                        return
                    case 'Yes'
                        obj.SaveAOIScores
                end
            end
        end
        
        function tab = AOITable(obj)
            tab = {};
            num = length(obj.prAOIs);
            if num == 0, return, end
            % build table
            for a = 1:num
                aoi = obj.prAOIs{a};
                colStr = sprintf(...
                    '<html><table border=0 width=%d bgcolor=#%s><TR></TR> </table></html>',...
                    400, rgb2hex(aoi.Colour));
                tab = [tab; {aoi.Visible, aoi.Name,...
                    aoi.Type, colStr}];
            end
            uitableAutoColumnHeaders(obj.prTblAOI);
        end
        
        function UpdateAOIs(obj)
            obj.prAOIValid = ~isempty(obj.prAOIs);
            if obj.prAOIValid
                str = 'AOI Definitions: present';
                col = [0.00, 0.80, 0.00];
                set(obj.prBtnRemoveAOI, 'enable', 'on');
                set(obj.prBtnClearAOI, 'enable', 'on');
                set(obj.prBtnFolderAOIs, 'enable', 'off');
            else
                str = 'AOI Definitions: not present';
                col = [0.80, 0.00, 0.00];
                set(obj.prBtnRemoveAOI, 'enable', 'off');
                set(obj.prBtnClearAOI, 'enable', 'off');
                set(obj.prBtnFolderAOIs, 'enable', 'on');                
            end
            set(obj.prLblAOIDef, 'string', str, 'foregroundcolor', col);
            tab = obj.AOITable;
            set(obj.prTblAOI, 'data', tab);
%             obj.Draw
        end

        %% drawing
        
        function UpdateDrawSize(obj)
            
            % check for mouse position - if it is over the window, then use
            % that as the focus (around which to scale the drawing plane) -
            % otherwise use the centre of the window
            [mx, my] = GetMouse(obj.prWinPtr);
            if...
                    mx >= obj.prWindowSize(1) &&...
                    mx <= obj.prWindowSize(3) &&...
                    my >= obj.prWindowSize(2) &&...
                    my <= obj.prWindowSize(4)
                obj.prDrawFocus = [mx, my];
            else
                obj.prDrawFocus = obj.prWindowSize(3:4) / 2;
            end

            % centre window  
            wcx = obj.prDrawFocus(1);
            wcy = obj.prDrawFocus(2);
            rect = obj.prDrawSize - [wcx, wcy, wcx, wcy];
            
            % apply zoom
            rect = rect * obj.prZoom;
            obj.prDrawOffset = obj.prDrawOffset * obj.prZoom;
            
            % apply aspect ratio correction
            screenAR = obj.prWindowSize(3) / obj.prWindowSize(4);
            if screenAR > 1     % wide
                rect([1, 3]) = rect([1, 3]) ./ obj.prARFactor;
            elseif screenAR < 1 % tall
                rect([2, 4]) = rect([2, 4]) ./ obj.prARFactor;
            end
            
            % de-centre window
            obj.prDrawSize = rect + [wcx, wcy, wcx, wcy];
           
            % reset zoom
            obj.prZoom = 1;
            
        end
        
        function PrepareForDrawing(obj)
            
            if ~obj.prDataValid && ~obj.prStimValid
                obj.prDrawingPrepared = false;
                return
            end
            
            % if wait for drawing flag is set, don't draw
            if obj.prWaitToDraw
                obj.prDrawingPrepared = false;
                return
            end
            
            % width of drawing plane
            drW = obj.prDrawSize(3) - obj.prDrawSize(1);
            
            % check that the drawing plane is not out of bounds
            if obj.prDrawSize(1) > obj.prWindowSize(3)
                % left hand edge
                obj.prDrawSize(1) = obj.prWindowSize(3);
                obj.prDrawSize(3) = obj.prDrawSize(1) + drW;
            end
            
            % width/height of drawing plane
            drW = obj.prDrawSize(3) - obj.prDrawSize(1);
            drH = obj.prDrawSize(4) - obj.prDrawSize(2);    
            
            % stimulus
            if obj.prStimValid
                switch obj.prStimType
                    case 'IMAGE'
                        obj.prStimTexPtr = Screen('MakeTexture',...
                            obj.prWinPtr, obj.prStimImg);
                end
                % rescale
                rect = obj.prDrawSize;
%                 wcx = rect(3) / 2;
%                 wcy = rect(4) / 2;             
%                 rect = rect - [wcx, wcy, wcx, wcy];
%                 rect = rect .* repmat(obj.prStimScale, 1, 2);
%                 rect = rect + [wcx, wcy, wcx, wcy];
                obj.prStimDrawSize = rect;
            end
            
            if obj.prSelValid
                
                % gather selected data
                x = obj.prData.x(obj.prSel);
                y = obj.prData.y(obj.prSel);
                ft = obj.prData.ft(obj.prSel);
                fn = obj.prData.fn(obj.prSel);
                numSel = length(fn);

                % update max number of frames
                obj.prMaxFrames = max(cell2mat(fn));

                % make matrix of frame * coords for gaze points
                mat = nan(2, numSel, obj.prMaxFrames);
                for d = 1:numSel
                    % find sample numbers for all frames
                    if ~isempty(fn{d})
                        s1 = 1;
                        s2 = fn{d}(end);
                        % gather x, y coords for gaze points
                        mat(1, d, s1:s2) = x{d}(s1:s2);
                        mat(2, d, s1:s2) = y{d}(s1:s2);
                    end
                end

                % rescale matrix to drawing window size
                matPx = mat;    % need this to maintain size when N = 1
                matPx(1, :, :) = (mat(1, :, :) .* drW) + obj.prDrawSize(1);
                matPx(2, :, :) = (mat(2, :, :) .* drH) + obj.prDrawSize(2);
                
                % colour gaze points by AOI
                obj.prCoordsCol = zeros(3, numSel, obj.prMaxFrames);
                r = repmat(255, numSel, obj.prMaxFrames);
                g = repmat(255, numSel, obj.prMaxFrames);
                b = repmat(255, numSel, obj.prMaxFrames);
                if ~isempty(obj.prAOIs) && obj.prAOIScoreValid
                    for a = 1:length(obj.prAOIs)
                        idx = find(obj.prAOIScores(:, :, a) == 1);
                        r(idx) = obj.prAOIs{a}.Colour(1);
                        g(idx) = obj.prAOIs{a}.Colour(2);
                        b(idx) = obj.prAOIs{a}.Colour(3);
                    end
                    r = reshape(r, 1, size(r, 1), size(r, 2));
                    g = reshape(g, 1, size(g, 1), size(g, 2));
                    b = reshape(b, 1, size(b, 1), size(b, 2));
                    obj.prCoordsCol = [r; g; b];
                else
                    obj.prCoordsCol =...
                        repmat(obj.Col_Series', 1, numSel, obj.prMaxFrames);
                end

                % store 
                obj.prCoordsNorm = mat;
                obj.prCoords = matPx;
            end
                        
            obj.prDrawingPrepared = true;
            
        end
        
        function Draw(obj)
            
            if obj.prDrawingPrepared && ~obj.prWaitToDraw
                
                % set BG color and text size
                Screen('FillRect', obj.prWinPtr, obj.Col_BG);                
                Screen('TextSize', obj.prWinPtr, obj.ChannelLabelFontSize);

                % stimulus
                if obj.prStimValid && obj.DrawStimulus
                    switch obj.prStimType
                        case 'MOVIE'
                            if obj.prTime < obj.prStimMovDur
                                Screen('SetMovieTimeIndex', obj.prStimMovPtr,...
                                    obj.prTime);
                                obj.prStimTexPtr = Screen('GetMovieImage',...
                                    obj.prWinPtr, obj.prStimMovPtr);
                                if obj.prStimTexPtr >= 0
                                    Screen('DrawTexture', obj.prWinPtr,...
                                        obj.prStimTexPtr, [], obj.prStimDrawSize);     
                                end
                            end
                        case 'IMAGE'
                            Screen('DrawTexture', obj.prWinPtr,...
                                obj.prStimImgTexPtr, [], obj.prStimDrawSize);
                    end
                end
                
                % AOIs
                if ~isempty(obj.prAOIs)
                    for a = 1:length(obj.prAOIs)                                
                        if obj.prAOIs{a}.Visible &&...
                                obj.prAOIs{a}.OnsetTime <= obj.prTime &&...
                                obj.prAOIs{a}.OffsetTime >= obj.prTime
                            switch obj.prAOIs{a}.Type
                                case {'DYNAMIC MASK', 'STATIC MASK'}
                                    [suc, aoiPtr] =...                        
                                        obj.prAOIs{a}.GetFrame(obj.prTime);
                                    if suc
                                        aoiCol = obj.prAOIs{a}.Colour;
                                        Screen('DrawTexture', obj.prWinPtr,...
                                            aoiPtr, [], obj.prDrawSize, [],...
                                            [], 1 / 4, [aoiCol, 255 / 2],...
                                            obj.prAlphaShader);       
                                    end
                                case 'RECT'
                                    rect = obj.prAOIs{a}.Rect .*...
                                        repmat(obj.prDrawSize(3:4), 1, 2);
                                    aoiCol = [obj.prAOIs{a}.Colour, 255 * .25];
                                    aoiRect = obj.prAOIs{a}.Rect .*...
                                        repmat(obj.prDrawSize(3:4), 1, 2);
                                    Screen('FillRect', obj.prWinPtr,...
                                        aoiCol, aoiRect);
                                    Screen('FrameRect', obj.prWinPtr,...
                                        aoiCol(1:3), aoiRect, 2);
                                    Screen('DrawLine', obj.prWinPtr,...
                                        aoiCol(1:3), aoiRect(1), aoiRect(2),...
                                        aoiRect(3), aoiRect(4), 2);
                                    Screen('DrawLine', obj.prWinPtr,...
                                        aoiCol(1:3), aoiRect(3), aoiRect(2),...
                                        aoiRect(1), aoiRect(4), 2);                                    
                                    DrawFormattedText(obj.prWinPtr,...
                                        obj.prAOIs{a}.Name, 'center',...
                                        'center', obj.Col_Label, [], [],...
                                        [], [], [], aoiRect);
                                    
                            end
                        end
                    end
                end
                    
                % draw ET data
                if obj.prDataValid && obj.prSelValid &&...
                        obj.prFrame <= obj.prMaxFrames
                
                    % draw heatmap
                    if obj.prHeatmapsPrepared && obj.DrawHeatmap
                        hm = obj.prHeatmaps(:, :, :, obj.Frame);
                        alpha = obj.prHeatmapsAlpha(:, :, obj.Frame);
                        hm(:, :, 4) = alpha;
                        hmTex = Screen('MakeTexture', obj.prWinPtr, hm);
                        Screen('DrawTexture', obj.prWinPtr, hmTex, [],...
                            obj.prDrawSize, [], [], .6)
                    end
                    
                    % draw gaze points
                    if obj.DrawGaze
                        % additional white rings for when AOIs are present
                        if obj.prAOIScoreValid
                            Screen('DrawDots', obj.prWinPtr,...
                                obj.prCoords(:, :, obj.prFrame),...
                                5,...
                                obj.prCoordsCol(:, :, obj.prFrame),...
                                [], 3);
                            gps = 2;
                        else
                            gps = obj.GazePointSize;
                        end
                        Screen('DrawDots', obj.prWinPtr,...
                            obj.prCoords(:, :, obj.prFrame),...
                            gps,...
                            [255, 255, 255],...
                            [], 3);   
                    end
                    
                    % draw quivers
                    if obj.DrawQuiver && sum(obj.prSel) > 1
                        f2 = obj.Frame;
                        f1 = f2 - obj.QuiverFrameSpan;
                        if f1 < 1, f1 = 2; end
                        quiv = [obj.prCoords(:, :, f1),...
                            obj.prCoords(:, :, f2)];
                        numSel = sum(obj.prSel);
                        qord = [1:2:(numSel * 2) - 1, 2:2:numSel * 2];
                        [~, so] = sort(qord);
                        quiv = quiv(:, so);
                        quivColAlpha1 = obj.QuiverAlpha * 255;
                        quivColAlpha2 = 0;
                        quivCol2 =...
                            [obj.prCoordsCol(:, :, obj.prFrame);...
                            repmat(quivColAlpha1, 1, numSel)];
                        quivCol1 =...
                            [obj.prCoordsCol(:, :, obj.prFrame);...
                            repmat(quivColAlpha2, 1, numSel)];       
                        quivCol = [quivCol1, quivCol2];
                        quivCol = quivCol(:, so);
                        
                        if obj.prAOIScoreValid
                            quivColWhite = quivCol;
                            quivColIdx = 1:2:size(quivColWhite, 2);
                            quivCol(1:3, quivColIdx) = repmat(255, 3, size(quivColIdx, 2));
%                             Screen('DrawLines', obj.prWinPtr,...
%                                 quiv, 6, quivCol);                            
                        end
                        Screen('DrawLines', obj.prWinPtr,...
                            quiv, 4, quivCol);
                    end
                 
                end


                % draw messages
                msg = [];
                if ~isempty(msg)
                    Screen('TextSize', obj.prWinPtr, 16);
                    tb = Screen('TextBounds', obj.prWinPtr, msg);
                    msgX = ((obj.prWindowSize(3) -...
                        obj.prWindowSize(1)) / 2) - (tb(3) / 2);
                    msgY = obj.prWindowSize(1) + tb(4) + 5;
                    Screen('DrawText', obj.prWinPtr, msg, msgX, msgY,...
                        obj.Col_Label, obj.Col_LabelBG);
                end
                
                % information pane
                if obj.DrawInfoPane
                    % place info pane 10px from bottom left
                    ix1 = 1;
                    ix2 = ix1 + obj.InfoPaneSize(1);
                    iy2 = obj.prWindowSize(4);
                    iy1 = iy2 - obj.InfoPaneSize(2);
                    % draw info pane BG
                    Screen('FillRect', obj.prWinPtr, [obj.Col_LabelBG, 200],...
                        [ix1, iy1, ix2, iy2]);
                    Screen('FrameRect', obj.prWinPtr, obj.Col_Label,...
                        [ix1, iy1, ix2, iy2]);  
                end
                
                % trial line
                obj.prTimeLineValid = false;
                if obj.prDataValid && obj.prSelValid &&...
                        obj.DrawTimeLine 
                    
                    if obj.DrawInfoPane
                        % if drawing info pane, place trial line so that it
                        % doesn't overlap
                        tlx1 = ix2 + 10;
                        tlx2 = obj.prWindowSize(3) - tlx1;
                    else
                        % otherwise, use full width of screen
                        tlx1 = 10;
                        tlx2 = obj.prWindowSize(3) - tlx1;
                    end
                    tlh = 50;                           % height
                    tly2 = obj.prWindowSize(4);       % bottom edge
                    tly1 = tly2 - tlh;                  % top edge
                    tlw = tlx2 - tlx1;                  % width
                    
                    % check width is valid, if window is too small then the
                    % timeline won't fit
                    if tlw >= 50
                        obj.prTimeLineX = [tlx1, tlx2];
                        obj.prTimeLineY = [tly1, tly2];

                        % calculate steps for tick marks
                        tlxStep = tlw / obj.Duration;
                        tlFrameW = obj.prMaxFrames / tlw;
                        tlx = tlx1 + sort(repmat(tlxStep:tlxStep:tlw, 1, 2));
                        tly = repmat([tly1, tly2], 1, length(tlx) / 2);

                        % calculate pos of box representing current trial
                        tltx1 = tlx1 + (tlxStep * obj.Time);
                        tltx2 = tltx1 + 1;

                        Screen('FillRect', obj.prWinPtr, [obj.Col_LabelBG, 150],...
                            [tlx1, tly1, tlx2, tly2]);
                        Screen('FillRect', obj.prWinPtr, obj.Col_Label,...
                            [tltx1, tly1, tltx2, tly2]);
                        Screen('FrameRect', obj.prWinPtr, [obj.Col_Label, 100],...
                            [tlx1, tly1, tlx2, tly2]);
                        Screen('DrawLines', obj.prWinPtr, [tlx; tly],...
                            1, [obj.Col_Label, 100]);    

                        % draw timecode
                        msg = sprintf('%s | %.1fs | Frame %d of %d',...
                            obj.TimeString, obj.Time, obj.Frame,...
                            obj.prMaxFrames);
                        Screen('TextSize', obj.prWinPtr, 24);
                        tb = Screen('TextBounds', obj.prWinPtr, msg);
                        msgX = ((obj.prWindowSize(3) -...
                            obj.prWindowSize(1)) / 2) - (tb(3) / 2);
                        msgY = obj.prWindowSize(1) + tb(4) + 5;
                        Screen('DrawText', obj.prWinPtr, msg, msgX, msgY,...
                            obj.Col_Label, obj.Col_LabelBG);

                        obj.prTimeLineValid = true;
                    end

                end
                
%                 obj.temp(end + 1) = Screen('Flip', obj.prWinPtr);
                Screen('Flip', obj.prWinPtr);
                    
            end
            
        end
        
        function PrepareHeatmaps(obj)
            
            if ~obj.prDataValid
                error('Cannot prepare heatmaps without valid data.')
            end
            
            if ~obj.prSelValid || ~any(obj.prSel)
                error('Cannot prepare heatmaps without some data selected.')
            end
                        
            wb = waitbar(0, 'Making heatmaps...');
                        
            % set up heatmap resolutions, and gather data into x and y
            % coords
            ar = obj.AspectRatio(1) / obj.AspectRatio(2);
            workRes = round(...
                [obj.HeatmapWorkRes, obj.HeatmapWorkRes / ar]);
            outRes = round(obj.prDrawSize(3:4) * obj.HeatmapResScale);
            x = shiftdim(obj.prCoords(1, :, :), 1);
            y = shiftdim(obj.prCoords(2, :, :), 1);
            
            % preallocate heatmap output
            hm = zeros(outRes(2), outRes(1), 3, obj.prMaxFrames,...
                'uint8');
            alpha = zeros(outRes(2), outRes(1), obj.prMaxFrames,...
                'uint8'); 
            pxRes = obj.prDrawSize(3:4);
            % loop through all frames and prepare heatmaps
            for f = 1:obj.prMaxFrames
                [hm(:, :, :, f), alpha(:, :, f)] =...
                    etHeatmap4(x(:, f), y(:, f), workRes,...
                    outRes, pxRes, obj.HeatmapColorMap);
                if mod(f, 7) == 0
                    waitbar(f / obj.prMaxFrames, wb);
                end
            end
            obj.prHeatmaps = hm;
            obj.prHeatmapsAlpha = alpha;
            close(wb)
            obj.prHeatmapsPrepared = true;
            obj.Draw
                        
        end
        
        function UpdateAOIScoreDisplay(obj)
            
            if ~obj.prAOIScoreValid || obj.prWaitToDraw
%                 warning('AOI scores not valid.')
                return
            end
            
            % time vector
            tStep = obj.Duration / size(obj.prAOIScores, 2);
            t = tStep:tStep:obj.Duration;
            hTs = obj.prAxsAOITimeSeries;
            hMu = obj.prAxsAOIMeans;
            hHist = obj.prAxsAOIHist;
            
            res = obj.Results;
            
            % timeseries
            pl = plot(hTs, t, res.TimeSeries);
            set(pl, 'hittest', 'off')
            set(pl, 'linewidth', 2)
            xlim(hTs, t([1, end]))
            set(hTs, 'color', obj.Col_BG)
            set(hTs, 'xcolor', obj.Col_LabelBG / 255)
            set(hTs, 'xgrid', 'on')
            set(hTs, 'xminorgrid', 'on')
            set(hTs, 'buttondownfcn', @obj.axsAOITimeSeries_Click)
            legend(hTs, obj.AOINames, 'textcolor', obj.Col_Label / 255,...
                'color', obj.Col_LabelBG / 255, 'interpreter', 'none');
            obj.prRecCursor = rectangle(hTs,...
                'position',         [obj.Time, 0, 1 / obj.FPS, 1],...
                'edgecolor',        [1, 1 ,1],...
                'facecolor',        'none');
            
            % aoi hist
            cla(hHist)
            hold(hHist, 'on')
            for a = 1:length(res.AOIMean)
                tmp = hist(res.SubjectMean(a, :), 20);
                pl = plot(hHist, tmp, 'linewidth', 3);
            end
            legend(hHist, obj.AOINames, 'textcolor', obj.Col_Label / 255,...
                'color', obj.Col_LabelBG / 255, 'interpreter', 'none');
            
            % aoi means bar
            cla(hMu)
            hold(hMu, 'on')
            for a = 1:length(res.AOIMean)
                b = bar(hMu, a, res.AOIMean(a));
                set(b, 'FaceColor', obj.prAOIs{a}.Colour / 255);
            end
            hold(hMu, 'off')
            set(hMu, 'xtick', 1:length(res.AOIMean));
            set(hMu, 'xticklabel', obj.AOINames); 
            legend(hMu, obj.AOINames, 'textcolor', obj.Col_Label / 255,...
                'color', obj.Col_LabelBG / 255, 'interpreter', 'none');
            
            % table
            set(obj.prTblAOIValues,...
                'data', table2cell(res.AOIMeansTable)',...
                'rowname', res.AOIMeansTable.Properties.VariableNames,...
                'columnname', res.AOIMeansTable.Properties.RowNames);
            uitableAutoColumnHeaders(obj.prTblAOIValues)
            
            obj.ShowHideAnalysisPanel
        end
        
        function RenderVideo(obj, path_out)
            % if no path passed, prompt for it
            if ~exist('path_out', 'var')
                filterSpec = {'*.mp4', 'MP4 Files'};
                [file, pth] = uigetfile(filterSpec, 'Choose movie location');
                if isequal(file, 0) || isequal(pth, 0)  % user pressed cancel
                    return
                end
                path_out = fullfile(pth, file);      
            end
            path_out = sprintf('"%s"', path_out);
            % create output movie file, prepare
            rPtr = Screen('CreateMovie', obj.prWinPtr, path_out, [],...
                [], obj.FPS, ':CodecType=VideoCodec=x264enc Keyframe=15 Videobitrate=24576');
            obj.PrepareForDrawing;
            % loop through frames
            for f = 1:obj.prMaxFrames
                obj.Frame = f;
                Screen('AddFrameToMovie', obj.prWinPtr, [], [], rPtr);
            end
            Screen('FinalizeMovie', rPtr);
        end
        
        function PlotSubjectAOIScores(obj, selIdx)
            % check selection is valid
            if ~obj.Selection(selIdx)
                error('Index %d is not selected.', selIdx)
            end
            % check scores
            if ~obj.prAOIScoreValid
                error('AOI scores not calculated.')
            end
            % make new figure
            fig = figure('name', 'AOI Scores', 'menubar', 'none',...
                'numbertitle', 'off');
            % data wrangling
            scores = shiftdim(obj.prAOIScores(selIdx, :, :), 1);
            % index samples
            notInAOI                    = scores == 0;
            inAOI                       = scores == 1;
            aoiOff                      = scores == 2;
            missing                     = scores == 3;    
            % time vector
            t = 0:1 / obj.FPS:obj.Duration;
            % plot
            bar(t, aoiOff)
            hold on
            bar(t, missing)
            hold on
            bar(t, aoiOff)
        end
        
        %% UI
        function DataTree_Select(obj, tree, ~)
            obj.prWaitToDraw = true;
            obj.CheckAOIsDirty
            val = tree.SelectedNodes(1).getValue;
            if ischar(val)
                if strcmpi(val, 'ROOT')
                    % root node selected - not a valid data selection
                    obj.prSel = [];
                    obj.prSelValid = false;
                else
                    % get indices of all child segments
                    sel = strcmpi(obj.Data.addData, val);
                    obj.UpdateSelection(sel)
                end
            else
                % otherwise, take a single index
                obj.prSel = false(length(obj.prData.ids), 1);
                obj.prSel(val) = true;
                obj.prSelValid = true;
            end 
            obj.prHeatmapsPrepared = false;
            obj.prHeatmaps = [];
            obj.prHeatmapsAlpha = [];
            obj.prAOIScoreValid = false;
            obj.prAOIScores = [];
            obj.prWaitToDraw = false;
            obj.PrepareForDrawing
            obj.Draw
        end
        
        function UpdateUIPositions(obj)

            % get figure size in pixels. If figure hasn't been created yet,
            % quit out
            set(obj.prFig, 'units', 'pixels');
            figPosPx = get(obj.prFig, 'Position');
            if isempty(figPosPx), return, end
            
            % get bounds of text box
            tmp = uicontrol('style', 'text', 'string', 'arse',...
                'position', [0, 0, 100, 100], 'visible', 'off');
            tb = get(tmp, 'extent');
            tw = tb(3);
            th = tb(4);
            delete(tmp);
                        
            % figure dimensions
            w = figPosPx(3);
            h = figPosPx(4);
            
            leftDiv = 250;      % width of left panel
            stimH = 50;         % heigh of stimulus overlay controls
            aoiDefH = 400;  
            aoiScoreH = 60;
            aoiAnalysisH = h;
            
            obj.prPos_Stim = [...
                                1,...
                                1,...
                                leftDiv,...
                                stimH,...
                              ];
            obj.prPos_AOIScores = [...
                                1,...
                                stimH + 1,...
                                leftDiv,...
                                aoiScoreH,...
                            ];                          
            obj.prPos_AOIDef = [...
                                1,...
                                stimH + 1 + aoiScoreH,...
                                leftDiv,...
                                aoiDefH,...
                             ];    

            obj.prPos_PnlAOIAnalysis = [...
                                leftDiv,...
                                h - aoiAnalysisH,...
                                w - leftDiv...
                                aoiAnalysisH,...
                            ];
            obj.prPos_Tree = [...
                                1,... 
                                stimH + aoiDefH + aoiScoreH + 1,...
                                leftDiv,...
                                h - stimH - aoiDefH - aoiScoreH
                            ];
                        
            % aoi analysis
            w = obj.prPos_PnlAOIAnalysis(3);
            h = obj.prPos_PnlAOIAnalysis(4);
            tsH = h * .6;
            muW = w * .33;
            sp = 2;     % pixel spacing
            asp = 27;   % axis spacing
            obj.prPos_AxsAOITimeSeries =      [asp, h - tsH + asp, w - asp - sp, tsH - asp - sp];
            obj.prPos_AxsAOIMeans =           [w - muW + asp, asp, muW - asp - sp, h - tsH - asp - sp];
            obj.prPos_AxsAOIHist =            [muW + asp, asp, muW - asp - sp, h - tsH - asp - sp];
            obj.prPos_TblAOIValues =          [asp, asp, w - muW * 2 - asp - sp, h - tsH - asp - sp];
                        
            % stimulus
            w = obj.prPos_Stim(3);
            h = obj.prPos_Stim(4);
            bw = 80;
            bh = 27;
            obj.prPos_lblStimStatus =         [3, bh + 3, w, th]; 
            obj.prPos_btnSetStimMovie =       [0 * bw, 1, bw, bh];
            obj.prPos_btnSetStimImage =       [1 * bw, 1, bw, bh];
            obj.prPos_btnClearStim =          [2 * bw, 1, bw, bh];
            
            % aoi def
            w = obj.prPos_AOIDef(3);
            h = obj.prPos_AOIDef(4);
            bw = 60;        
            obj.prPos_tblAOI =                [1, bh, w, h - bh * 2];
            obj.prPos_lblAOIDef =             [3, h - th - 4, w, th]; 
            obj.prPos_btnAddAOI =             [0 * bw, 0 * bh, bw, bh];
            obj.prPos_btnRemoveAOI =          [1 * bw, 0 * bh, bw, bh];
            obj.prPos_btnClearAOIs =          [2 * bw, 0 * bh, bw, bh];
            obj.prPos_btnFolderAOIs =         [3 * bw, 0 * bh, bw, bh];
            
            % aoi scores
            w = obj.prPos_AOIScores(3);
            h = obj.prPos_AOIScores(4);
            bw = 60;        
            obj.prPos_lblAOIScores =          [3, h - bh - 4, w, th]; 
            obj.prPos_btnScoreAOIs =          [0 * bw, 0 * bh, bw, bh];
            obj.prPos_btnClearAOIScores =     [1 * bw, 0 * bh, bw, bh];
            obj.prPos_btnLoadAOIScores =      [2 * bw, 0 * bh, bw, bh];
            obj.prPos_btnSaveAOIScores =      [3 * bw, 0 * bh, bw, bh];
            
        end
       
        function Figure_Resize(obj, h, dat)
            obj.UpdateUIPositions
            set(obj.prDataTree,           'Position', obj.prPos_Tree);
            set(obj.prPnlAOIDef,          'Position', obj.prPos_AOIDef);
            set(obj.prPnlStim,            'Position', obj.prPos_Stim);
            set(obj.prPnlAOIAnalysis,     'Position', obj.prPos_PnlAOIAnalysis);
            set(obj.prAxsAOITimeSeries,   'Position', obj.prPos_AxsAOITimeSeries);
            set(obj.prAxsAOIMeans,        'Position', obj.prPos_AxsAOIMeans);
            set(obj.prAxsAOIHist,         'Position', obj.prPos_AxsAOIHist);
            set(obj.prTblAOIValues,       'Position', obj.prPos_TblAOIValues);
        end
        
        function Listener(obj, ~, ~)
            % react to time line clicks
            if obj.prTimeLineValid
                % get mouse pos
                [mx, my, mButtons] = GetMouse(obj.prWinPtr);
                % if cursor is not on drawing window, stop
                if mx < 0 || my < 0 || mx > obj.prWindowSize(3) ||...
                        my > obj.prWindowSize(4)
                    return
                end
                % deal with mouse up/down events
                if ~isempty(obj.prMouseButtons) && mButtons(1)
                    % mouse down - check if cursor is on timeline
                    if my >= obj.prTimeLineY(1) &&...
                            my <= obj.prTimeLineY(2) &&...
                            mx >= obj.prTimeLineX(1) &&...
                            mx <= obj.prTimeLineX(2)
                        % translate cursor pos to time, update accordingly
                        xProp = (mx - obj.prTimeLineX(1)) /...
                            (obj.prTimeLineX(2) - obj.prTimeLineX(1));
                        obj.Time = obj.Duration * xProp;
                    end
                elseif ~isempty(obj.prMouseButtons) &&...
                        obj.prMouseButtons(1) && ~mButtons(1)
                    % mouse up - update AOI scores
                    obj.UpdateAOIScoreDisplay
                end
                % record cursor pos, for interrogation next time
                obj.prMouseX = mx;
                obj.prMouseY = my;
                obj.prMouseButtons = mButtons;
            end            
        end
        
        function Listener_ERR(obj, q, w)
            rethrow ERR
        end
        
        function ShowHideAnalysisPanel(obj, ~, ~)
            if obj.prSelValid && obj.prDataValid &&...
                    obj.prAOIScoreValid
                set(obj.prPnlAOIAnalysis, 'visible', 'on')
                set(obj.prPnlAOIDisabled', 'visible', 'off')  
            else
                set(obj.prPnlAOIAnalysis, 'visible', 'off')
                set(obj.prPnlAOIDisabled', 'visible', 'on')                 
            end
        end
        
        function btnClearStim_Click(obj, ~, ~)
            obj.ClearStimulusImage
        end
        
        function btnSetStimImage_Click(obj, ~, ~)
            filterSpec = {...
                '*.png',    'PNG Files'     ;...
                '*.jpg',    'JPG Files',    ;...
                '*.jpeg',   'JPEG Files',   };
            [file, pth] = uigetfile(filterSpec, 'Set stimulus image');
            if isequal(file, 0) || isequal(pth, 0)  % user pressed cancel
                return
            end
            obj.SetStimulusImage(fullfile(pth, file));
            obj.prStimImagePrevDir = pth;
        end
        
        function btnSetStimMovie_Click(obj, ~, ~)
            filterSpec = {...
                '*.mp4',    'MP4 Files'     ;...
                '*.mov',    'MOV Files',    ;...
                '*.avi',    'AVI Files',   };
            [file, pth] = uigetfile(filterSpec, 'Set stimulus movie');
            if isequal(file, 0) || isequal(pth, 0)  % user pressed cancel
                return
            end
            obj.SetStimulusMovie(fullfile(pth, file));
            obj.prStimMoviePrevDir = pth;
        end
        
        function tblAOI_EditCell(obj, h, dat)
            sel = dat.Indices(1);
            switch dat.Indices(2)
                case 1  % visible
                    obj.prAOIs{sel}.Visible = dat.NewData;
                case 2  % name
                    obj.prAOIs{sel}.Name = dat.NewData;
                case 3  % type
                    obj.prAOIs{sel}.Type = dat.NewData;
                case 4  % colour
            end
            obj.UpdateAOIs
        end
        
        function tblAOI_Select(obj, ~, dat)
%             % only respond if colour col selected
%             if dat.Indices(2) ~= 4, return, end
%             
%             % get selected row
%             sel = dat.Indices(1);
%             
%             % get mouse pos
%             mouse = get(0, 'PointerLocation');
%             pos = [mouse(1), mouse(2), 200, 200];
%             cp = com.mathworks.mlwidgets.graphics.ColorDialog;
%             [jColorPicker,hContainer] = javacomponent(cp, pos, gcf);
% 
% %             newData = uisetcolor(obj.prAOIs{sel}.Colour / 255);
%             if ~isequal(newData, 0)
%                 obj.prAOIs{sel}.Colour = newData * 255;
%                 obj.UpdateAOIs;
%             end
        end
        
        function btnAddAOI_Click(obj, ~, ~)
        end
        
        function btnRemoveAOI_Click(obj, ~, ~)
        end
        
        function btnClearAOIs_Click(obj, ~, ~)
            obj.prAOIs = {};
            obj.UpdateAOIs;
        end
        
        function btnFolderAOIs_Click(obj, ~, ~)
            path = uigetdir([], 'Add AOIs from folder');
            if isequal(path, 0), return, end
            obj.AddDynamicAOIFromFolder(path);
        end
        
        function btnScoreAOIs_Click(obj, ~, ~)
            if ~obj.prAOIValid
                error('AOI definitions not valid.')
            end
            obj.ScoreAOIs;
        end
        
        function btnClearAOIScores_Click(obj, ~, ~)
            if ~obj.prAOIValid
                error('AOI definitions not valid.')
            end
            obj.ClearAOIScores
        end
        
        function btnLoadAOIScores_Click(obj, ~, ~)
            obj.LoadAOIScores;
        end
        
        function btnSaveAOIScores_Click(obj, ~, ~)
            if ~obj.prAOIValid
                error('AOI definitions not valid.')
            end
            obj.SaveAOIScores;
        end
        
        function axsAOITimeSeries_Click(obj, h, dat)
            if dat.Button == 1
                obj.Time = dat.IntersectionPoint(1);
            end
        end 
        
        %% property get/set       
        
        function val = get.ScreenNumber(obj)
            val = obj.prScreenNumber;
        end
        
        function set.ScreenNumber(obj, val)
            % check bounds
            screens = Screen('screens');
            if val > max(screens) || val < min(screens)
                error('ScreenNumber must be between %d and %d.',...
                    min(screens), max(screens))
            end
            obj.prScreenNumber = val;
            obj.ReopenScreen
        end
        
        function val = get.WindowSize(obj)
            val = obj.prWindowSize;
        end
        
        function set.WindowSize(obj, val)
            if obj.Fullscreen
                warning('Window size not set when running in fullscreen mode.')
            else
                obj.prLastWindowSize = obj.WindowSize;
                obj.prWindowSize = round(val);
                obj.prDrawSize = round(val);
                obj.UpdateDrawSize
                obj.ReopenScreen
            end
        end
                
        function val = get.Zoom(obj)
            val = obj.prZoom;
        end
        
        function set.Zoom(obj, val)
            if val < .5, val = .5; end
            obj.prZoom = val;
            obj.UpdateDrawSize
            obj.PrepareForDrawing
            obj.Draw
        end
        
        function val = get.Fullscreen(obj)
            val = obj.prFullscreen;
        end
        
        function set.Fullscreen(obj, val)
            obj.prFullscreen = val;
            
            % determine whether we are going in or out of fullscreen;
            % record new and old window size
            if val
                oldSize = obj.prWindowSize;
                newSize = Screen('Rect', obj.prScreenNumber);
                obj.prLastWindowSize = oldSize;
            else
                oldSize = obj.prWindowSize;
                newSize = obj.prLastWindowSize;
            end
            
            % set focus to screen centre, and zoom to required value given
            % the ratio of new to old size 
            obj.prDrawFocus = oldSize(3:4) / 2;
            obj.prZoom = newSize / oldSize;

            % centre window  
            wcx = obj.prDrawFocus(1);
            wcy = obj.prDrawFocus(2);
            rect = oldSize - [wcx, wcy, wcx, wcy];

            % apply zoom
            rect = rect * obj.prZoom;
            obj.prDrawOffset = obj.prDrawOffset * obj.prZoom;

            % de-centre window
            wcx = wcx * obj.prZoom;
            wcy = wcy * obj.prZoom;
            obj.prDrawSize = rect + [wcx, wcy, wcx, wcy];

            % reset zoom
            obj.prZoom = 1;

            % store new (fullscreen) window size
            obj.prWindowSize = newSize;
            obj.ReopenScreen
        end
        
        function set.Col_BG(obj, val)
            if obj.prScreenOpen
                Screen('FillRect', obj.prWinPtr, val);
                obj.Draw
            end
        end
        
        function set.Col_FG(obj, val)
            obj.Col_FG = val;
            obj.Draw
        end
        
        function val = get.Data(obj)
            val = obj.prData;
        end
        
        function set.Data(obj, val)
            % check data type
            if ~isstruct(val) || ~isfield(val, 'mainBuffer') ||...
                    ~isfield(val, 'timeBuffer') || ~isfield(val, 'addData')
                error('Data must be gathered segments')
            end
            obj.prData = val;
            pbj.prDataValid = false;
            obj.UpdateData
            obj.PrepareForDrawing
            obj.Draw
        end      
        
        function val = get.Frame(obj)
            if obj.prDataValid
                val = obj.prFrame;
            else
                val = [];
            end
        end
        
        function set.Frame(obj, val)
            if obj.prDataValid
                if val >= obj.prMaxFrames
                    val = obj.prMaxFrames;
                elseif val == 0
                    val = 1;
                elseif val < 0
                    error('A frame number <0 was requested.')
                end
                obj.prFrame = val;
                obj.prTime = obj.prFrame * (1 / obj.FPS);
                obj.Draw
                if obj.prAOIScoreValid
                    set(obj.prRecCursor, 'position',...
                        [obj.Time, 0, 1 / obj.FPS, 1]);
                end
            else
                warning('Cannot set frame number until data has been loaded.')
            end
        end
        
        function set.Time(obj, val)
            if val > obj.Duration, val = obj.Duration; end
            if val < 0, val = 0; end
            obj.prTime = val;
            obj.Frame = round(val * obj.FPS);
        end
        
        function val = get.Time(obj)
            val = obj.prTime;
        end
        
        function val = get.AspectRatio(obj)
            val = obj.prDrawSize(3:4) /...
                gcd(obj.prDrawSize(3), obj.prDrawSize(4));
        end
        
        function set.AspectRatio(obj, val)
            if ~isvector(val) || length(val) ~= 2
                error('Aspect ratio must be a vector of length 2 [x, y].')
            end
            obj.prARFactor = val(1) / val(2);
            obj.UpdateDrawSize
            obj.PrepareForDrawing
            obj.Draw
        end
        
        function val = get.Duration(obj)
            if ~obj.prDataValid || isempty(obj.prSel)
                val = [];
            else
                val = obj.prMaxFrames / obj.FPS;
            end
        end
        
        function val = get.TimeString(obj)
            val = datestr(obj.Time / 86400, 'HH:MM.SS.FFF');
        end
        
        function val = get.AOIs(obj)
            val = obj.prAOIs;
        end
        
        function set.prStimValid(obj, val)
            obj.prStimValid = val;
            obj.UpdateStimulusStatus
            obj.PrepareForDrawing
            obj.Draw
        end
        
        function set.prAOIScores(obj, val)
            obj.prAOIScores = val;
            obj.UpdateAOIScoreDisplay
        end
        
        function set.prAOIScoreValid(obj, val)
            obj.ShowHideAnalysisPanel
            obj.prAOIScoreValid = val;
        end
        
        function set.prSelValid(obj, val)
            obj.ShowHideAnalysisPanel
            obj.prSelValid = val;
        end
        
        function set.prDataValid(obj, val)
            obj.ShowHideAnalysisPanel
            obj.prDataValid = val;
        end
        
        function val = get.Results(obj)
            
            % attempt to return cached results
            if ~isempty(obj.prResults)
                val = obj.prResults;
                return
            end
            
            if ~obj.prAOIScoreValid
                val = [];
                return
            end
            
            wb = waitbar(0, 'Preparing results...Proportions');
            
            % get IDs and timepoints
            ids                         = obj.prData.ids(obj.prSel);
            tp                          = obj.prData.timePoints(obj.prSel);
            
            % time vector
            t = 0:1 / obj.FPS:obj.Duration;
            
            % get raw scores
            scores                      = obj.prAOIScores;
            N                           = size(scores, 1);
            numSamps                    = size(scores, 2);
            numAOIs                     = size(scores, 3); 
            
            % index samples
            notInAOI                    = scores == 0;
            inAOI                       = scores == 1;
            aoiOff                      = scores == 2;
            missing                     = scores == 3;
            
            % count samples
            numInAOI                    = sum(inAOI, 2);
            numOutAOI                   = sum(notInAOI, 2);
            numMissing                  = sum(missing, 2);
            numPossible                 = numInAOI + numOutAOI + numMissing;

            % calculate proportions
            propInAOI                   = numInAOI ./ numPossible;
            propMissing                 = numMissing ./ numPossible;
            
            wb = waitbar(.20, wb, 'Preparing results...Time series');

            % timeseries - put proportion in AOI for each sample, collapsed
            % across all participants. For samples where the AOI is off,
            % put a NaN
            ts                          = shiftdim(nanmean(scores == 1, 1), 1);
            tsAOIOff                    = shiftdim(all(scores == 2, 1), 1); 
            ts(tsAOIOff)                = nan;
            val.TimeSeries              = ts;
            
            wb = waitbar(0.40, wb, 'Preparing results...Mean tables');
            
            % AOI means
            amu                         = shiftdim(nanmean(propInAOI, 1), 1);
            asd                         = shiftdim(nanstd(propInAOI, 1), 1);
            val.AOIMean                 = amu;
            val.AOISD                   = asd;
            val.AOIValid                = shiftdim(nanmean(propMissing, 1), 1);
            
            % subject means
            smu                         = shiftdim(propInAOI, 2)';            
            val.SubjectMean             = smu;
            
            wb = waitbar(0.60, wb, 'Preparing results...First looks');

            % first visit
            vis = zeros(N, numAOIs);
            fv = zeros(N, 1);
            entryTime = nan(N, numAOIs);
            for d = 1:N
                curMin = inf;
                curA = nan;
                for a = 1:numAOIs
                    vis = find(scores(d, :, a) == 1, 1, 'first');
                    if ~isempty(vis)
                        entryTime(d, a) = t(vis);
                    end
                    if vis < curMin
                        curMin = vis; 
                        curA = a;
                    end
                end
                fv(d) = curA;
            end
            
            % if any first visit indices are NaN this means that no AOIs
            % were visited. Need to score this (in terms of first visit) as
            % <none>, so create a list of AOI names, add <none> to the end
            % of it, and replace any NaN indices to the end value. 
            fv(isnan(fv)) = length(obj.AOINames) + 1;
            aoiLabels = [obj.AOINames; '<none>'];
            
            wb = waitbar(0.80, wb, 'Preparing results...Look processing');

            % looks
            val.Looks   = table;
            look_num    = zeros(N, numAOIs);
            look_min    = nan(N, numAOIs);
            look_peak   = nan(N, numAOIs);
            look_mu     = nan(N, numAOIs);
            look_med    = nan(N, numAOIs);
            for a = 1:numAOIs
                for d = 1:N
                    % make time vector in ms
                    t_ms = t * 1000;
                    % interpolate sub-200ms gaps
                    inAOI_int = aoiInterp(inAOI(d, :, a), missing(d, :, a), t_ms, 200);
                    % find contiguous looks
                    ct = findcontig2(inAOI_int, 1);
                    if ~isempty(ct)
                        % convert samples to time
                        looks = t_ms(ct) / 1000;
                        numLooks = size(looks, 1);
                        % store in table
                        tab_ids = repmat(ids(d), numLooks, 1);
                        tab_tp = repmat(tp(d), numLooks, 1);
                        tab_aoi = repmat({obj.prAOIs{a}.Name}, numLooks, 1);
                        val.Looks = [val.Looks; cell2table(...
                            [tab_ids, tab_tp, tab_aoi, num2cell(looks)],...
                            'variablenames', {'ID', 'Timepoint', 'AOI',...
                            'Look_Onset', 'Look_Offset', 'Look_Duration'})];
                        % calculate look stats
                        look_num(d, a)  = numLooks;
                        look_min(d, a)  = min(      looks(:, 3));
                        look_peak(d, a) = max(      looks(:, 3));
                        look_mu(d, a)   = mean(     looks(:, 3));
                        look_med(d, a)  = median(   looks(:, 3));
                    end
                end
            end
            % sort table by ID, then onset time
            val.Looks = sortrows(val.Looks,...
                {'ID', 'Timepoint', 'Look_Onset', 'Look_Offset'});
            
            % time series table
            varNames = ['frame', obj.AOINames'];
            frameNums = arrayfun(@(x) LeadingString('000000', x),...
                1:obj.prMaxFrames, 'uniform', false);
            val.TimeSeriesTable = cell2table(...
                [frameNums', num2cell(ts)],...
                'variablenames', varNames);  
            
            % aoi means table
            rowNames = {'Mean'; 'StdDev'};
            rowNames = renameDups(rowNames);
            val.AOIMeansTable = array2table([amu; asd], 'variablenames',...
                obj.AOINames', 'rownames', rowNames);
            
            % subject means table
            rowNames = ids;
            var_prop    = cellfun(@(x) [x, '_Prop'], obj.AOINames,...
                            'uniform', false);
            var_lkNum   = cellfun(@(x) [x, '_Looks'], obj.AOINames,...
                            'uniform', false);
            var_lkMin   = cellfun(@(x) [x, '_MinLook'], obj.AOINames,...
                            'uniform', false);                        
            var_lkPeak  = cellfun(@(x) [x, '_PeakLook'], obj.AOINames,...
                            'uniform', false);                        
            var_lkMean  = cellfun(@(x) [x, '_MeanLook'], obj.AOINames,...
                            'uniform', false);
            var_lkMed   = cellfun(@(x) [x, '_MedianLook'], obj.AOINames,...
                            'uniform', false);
            var_entry   = cellfun(@(x) [x, '_EntryTime'], obj.AOINames,...
                            'uniform', false);                        
            varNames = [...
                            cellstr('ID');...
                            cellstr('TimePoint');...
                            cellstr('First');...
                            var_prop;...
                            var_lkNum;...
                            var_lkMin;...
                            var_lkPeak;...
                            var_lkMean;...
                            var_lkMed;...
                            var_entry;...
                            'PropValid',...
                        ];
            val.SubjectMeansTable = cell2table(...
                [rowNames',...
                obj.prData.timePoints(obj.prSel)',...
                aoiLabels(fv),...
                num2cell(smu),...
                num2cell(look_num),...
                num2cell(look_min),...
                num2cell(look_peak),...
                num2cell(look_mu),...
                num2cell(look_med),...  
                num2cell(entryTime),...
                num2cell(1 - propMissing(:, :, 1))],...
                'variablenames', varNames);
            
            obj.prResults = val;
            
            delete(wb)
            
        end
        
        function val = get.AOINames(obj)
            if ~obj.prAOIValid
                val = [];
                return
            end
            tab = obj.AOITable;
            val = tab(:, 2);
        end
        
        function val = get.StimulusResolution(obj)
            val = [];
            if ~obj.prStimValid, return, end
            switch obj.prStimType
                case 'MOVIE'
                    val = [obj.prStimMovW, obj.prStimMovH];
                otherwise
                    error('Not yet implemented.')
            end
        end
        
        function set.prAOIColourIndex(obj, val)
            if val > size(obj.prAOIColourOrder, 1)
                val = 1;
            end
            obj.prAOIColourIndex = val;
        end
        
        function val = get.Selection(obj)
            val = obj.prSel;
        end
        
%         function val = get.X(obj)
%             val = obj.prData.x
%         end
%         function set.prAOIValid(obj, val)
% 
%         end
        
%         function set.prAOIScores(obj, val)
%             obj.prAOIScores = val;
%             obj.prAOIScoresDirty = true;
%         end
        
    end
 
end

