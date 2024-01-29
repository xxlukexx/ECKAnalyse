% version 1.0 20170524

classdef ECKETVis < handle
        
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
        privState
        privStat
        privTime = 0
        privIsPanning = false
        privWidth
        privHeight
        privSel
        privSelValid = false
        privSelLabel = '<none>'
        privTimer
        
        % PTB
        privWinPtr
        privScreenOpen 
        privScreenNumber
        privWindowSize
        privLastWindowSize
        privPTBOldSyncTests
        privPTBOldWarningFlag
        privAlphaShader
        
        % UI
        privFig
        privPos_Fig
        privFigOpen = false
        privDataTree
        privNodRoot
        privPnlAOIDef
        privPnlAOIScores
        privPnlStim
        privPos_Tree
        privPos_AOIDef
        privPos_AOIScores
        privPos_Stim
        privMouseX
        privMouseY
        privMouseButtons
        privLblStimStatus
        privPos_lblStimStatus
        privPos_btnSetStimMovie
        privPos_btnSetStimImage
        privPos_btnClearStim
        privBtnSetStimMovie
        privBtnSetStimImage
        privBtnClearStim
        privStimImagePrevDir
        privStimMoviePrevDir
        privPos_tblAOI
        privPos_lblAOIDef
        privPos_btnAddAOI
        privPos_btnRemoveAOI
        privPos_btnClearAOIs
        privPos_btnFolderAOIs
        privPos_lblAOIScores
        privPos_btnScoreAOIs
        privPos_btnClearAOIScores
        privPos_btnSaveAOIScores
        privPos_btnLoadAOIScores
        privPos_PnlAOIAnalysis
        privPos_AxsAOITimeSeries
        privPos_AxsAOIMeans
        privPos_AxsAOIHist
        privPos_TblAOIValues
        privTblAOI
        privLblAOIDef
        privBtnAddAOI
        privBtnRemoveAOI
        privBtnClearAOI
        privBtnFolderAOIs
        privLblAOIScores
        privBtnScoreAOIs
        privBtnClearAOIScores
        privBtnLoadAOIScores
        privBtnSaveAOIScores
        privPnlAOIAnalysis
        privPnlAOIDisabled
        privAxsAOITimeSeries
        privAxsAOIMeans
        privAxsAOIHist
        privTblAOIValues
        privRecCursor
        
        % drawing
        privWaitToDraw = false
        privZoom
        privDrawSize
        privDrawOffset = [0, 0]
        privARFactor = 1
        privDrawFocus
        privFullscreen
        privDrawingPrepared = false
        privFrame = 1
        privMaxFrames
        privCoords
        privCoordsNorm
        privCoordsCol
        privQuiv
        privTimeLineValid = false
        privTimeLineX
        privTimeLineY
        
        % stimulus/screen
        privStimValid = false;
        privStimType 
        privStimMovPtr
        privStimMovDur
        privStimMovFPS
        privStimMovW
        privStimMovH
        privStimMovFrames
        privStimImg
        privStimImgTexPtr
        privStimPath
        privStimAR
        privStimScale = [1, 1];
        privStimDrawSize
        privStimTexPtr
        privHeatmaps
        privHeatmapsAlpha
        privHeatmapsPrepared = false
        
        % data
        privData
        privNumData
        privDataType
        privDataValid = false
        privFT
        privFN
        privResultsValid = false
        privRes_AOITimeSeries
        privRes_AOIMeans
        privRes_SubjectMeans
        privResults

        % AOIs
        privAOIs
        privAOIValid = false
        privAOIColourOrder
        privAOIColourIndex
        privAOITex
        privAOIScoreValid = false
        privAOIScores
        privAOIScoresDirty = false
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
        function obj = ECKETVis
            
            warning('25FPS hard-coded - change if this is not right!')
            
            % status
            obj.privStat = ECKStatus('ECK ET Visualiser starting up...');
            
            % check PTB
            AssertOpenGL
            
            % disable sync tests and set PTB verbosity to minimum
            obj.privPTBOldSyncTests =...
                Screen('Preference', 'SkipSyncTests', 2);
            obj.privPTBOldWarningFlag =...
                Screen('Preference', 'SuppressAllWarnings', 1);
            
            % screen defaults
            obj.privScreenOpen = false;
            obj.privScreenNumber = max(Screen('screens'));
            if obj.privScreenNumber == 0
                % small window as only one screen
                obj.privWindowSize = round(...
                    Screen('Rect', obj.privScreenNumber) .* .4);
                obj.privFullscreen = false;
            else
                % fullscreen
                obj.privWindowSize = Screen('Rect', obj.privScreenNumber);
                obj.privFullscreen = true;
            end
                       
            % open screen
            obj.OpenScreen
            
            % UI
            set(0, 'DefaultTextInterpreter', 'none')
            obj.privFig = figure(...
                'NumberTitle',          'off',...
                'Units',                'normalized',...
                'Position',             obj.privPos_Fig,...
                'Menubar',              'none',...
                'Toolbar',              'none',...
                'Name',                 'ET Visualiser',...
                'DeleteFcn',            @(obj)obj.delete,...
                'ResizeFcn',            @obj.Figure_Resize,...
                'visible',              'off',...
                'renderer',             'opengl');
            obj.privFigOpen = true;
            set(obj.privFig, 'Units', 'Pixels')
            
            % UI panel positions
            obj.UpdateUIPositions
                        
            % panels
            obj.privPnlStim = uipanel(...
                'parent',               obj.privFig,...
                'units',                'pixels',...
                'visible',              'on',...
                'bordertype',           'none',...
                'position',             obj.privPos_Stim);
            obj.privPnlAOIDef = uipanel(...
                'parent',               obj.privFig,...
                'units',                'pixels',...
                'visible',              'on',...
                'bordertype',           'none',...
                'position',             obj.privPos_AOIDef);
            obj.privPnlAOIScores = uipanel(...
                'parent',               obj.privFig,...
                'units',                'pixels',...
                'visible',              'on',...
                'bordertype',           'none',...
                'position',             obj.privPos_AOIScores);
            obj.privPnlAOIAnalysis = uipanel(...
                'parent',               obj.privFig,...
                'units',                'pixels',...
                'visible',              'on',...
                'bordertype',           'none',...
                'visible',              'off',...
                'position',             obj.privPos_PnlAOIAnalysis);
            obj.privPnlAOIDisabled = uipanel(...
                'parent',               obj.privFig,...
                'units',                'pixels',...
                'visible',              'on',...
                'bordertype',           'none',...
                'title',                'AOI Score Not Run',...
                'visible',              'on',...
                'position',             obj.privPos_PnlAOIAnalysis);            
            
            % AOI analysis
            obj.privAxsAOITimeSeries = axes(...
                'parent',               obj.privPnlAOIAnalysis,...
                'units',                'pixels',...
                'visible',              'on',...
                'color',                obj.Col_BG,...
                'position',             obj.privPos_AxsAOITimeSeries);   
            obj.privAxsAOIMeans = axes(...
                'parent',               obj.privPnlAOIAnalysis,...
                'units',                'pixels',...
                'color',                obj.Col_BG,...
                'visible',              'on',...
                'position',             obj.privPos_AxsAOIMeans);  
            obj.privAxsAOIHist = axes(...
                'parent',               obj.privPnlAOIAnalysis,...
                'units',                'pixels',...
                'color',                obj.Col_BG,...
                'visible',              'on',...
                'position',             obj.privPos_AxsAOIHist);   
            aoivalColNames =       {'AOI Name',    'Time (s)', 'Prop',     'Missing'   };
            aoivalColFormats =     {'char',        'numeric',  'numeric', 'numeric'    };
            obj.privTblAOIValues = uitable(...
                'parent',                   obj.privPnlAOIAnalysis,...
                'units',                    'pixels',...
                'position',                 obj.privPos_TblAOIValues,...
                'fontsize',                 12,...
                'cellselectioncallback',    @obj.tblAOIValues_Select,...
                'columnname',               aoivalColNames,...
                'columnformat',             aoivalColFormats);            
            
            % stimulus 
            str = 'Stimulus overlay: not present';
            obj.privLblStimStatus = uicontrol(...
                'parent',               obj.privPnlStim,...
                'style',                'text',...
                'string',               str,...
                'position',             obj.privPos_lblStimStatus,...
                'horizontalalignment',  'left',...
                'foregroundcolor',      [0.80, 0.00, 0.00],...
                'fontsize',             12,...
                'fontweight',           'bold');
            obj.privBtnClearStim = uicontrol(...
                'parent',               obj.privPnlStim,...
                'style',                'pushbutton',...
                'string',               'Clear',...
                'fontsize',             12,...
                'position',             obj.privPos_btnClearStim,...
                'enable',               'off',...
                'callback',             @obj.btnClearStim_Click);
            obj.privBtnSetStimImage = uicontrol(...
                'parent',               obj.privPnlStim,...
                'style',                'pushbutton',...
                'string',               'Set Image',...
                'fontsize',             12,...
                'position',             obj.privPos_btnSetStimImage,...
                'callback',             @obj.btnSetStimImage_Click);
            obj.privBtnSetStimMovie = uicontrol(...
                'parent',               obj.privPnlStim,...
                'style',                'pushbutton',...
                'string',               'Set Movie',...
                'fontsize',             12,...
                'position',             obj.privPos_btnSetStimMovie,...
                'callback',             @obj.btnSetStimMovie_Click);            
            obj.UpdateData
            
            % AOI def
            aoiTypes =          {'RECT', 'STATIC MASK', 'DYNAMIC MASK'};
            aoiColNames =       {'Visible', 'Name', 'Type',     'Colour'    };
            aoiColFormats =     {'logical', 'char', aoiTypes,   'char'      };
            aoiColEditable =    [true,      true,   true,       true        ];
            obj.privTblAOI = uitable(...
                'parent',                   obj.privPnlAOIDef,...
                'position',                 obj.privPos_tblAOI,...
                'fontsize',                 12,...
                'celleditcallback',         @obj.tblAOI_EditCell,...
                'cellselectioncallback',    @obj.tblAOI_Select,...
                'columnname',               aoiColNames,...
                'columneditable',           aoiColEditable,...
                'columnformat',             aoiColFormats);
            str = 'AOI Definitions: not present';
            obj.privLblAOIDef = uicontrol(...
                'parent',               obj.privPnlAOIDef,...
                'style',                'text',...
                'string',               str,...
                'position',             obj.privPos_lblAOIDef,...
                'horizontalalignment',  'left',...
                'foregroundcolor',      [0.80, 0.00, 0.00],...
                'fontsize',             12,...
                'fontweight',           'bold');            
            obj.privBtnAddAOI = uicontrol(...
                'enable',               'off',...
                'parent',               obj.privPnlAOIDef,...
                'style',                'pushbutton',...
                'string',               'Add',...
                'fontsize',             12,...
                'position',             obj.privPos_btnAddAOI,...
                'callback',             @obj.btnAddAOI_Click);  
            obj.privBtnRemoveAOI = uicontrol(...
                'enable',               'off',...
                'parent',               obj.privPnlAOIDef,...
                'style',                'pushbutton',...
                'string',               'Remove',...
                'fontsize',             12,...
                'position',             obj.privPos_btnRemoveAOI,...
                'callback',             @obj.btnRemoveAOI_Click);              
            obj.privBtnClearAOI = uicontrol(...
                'enable',               'off',...
                'parent',               obj.privPnlAOIDef,...
                'style',                'pushbutton',...
                'string',               'Clear',...
                'fontsize',             12,...
                'position',             obj.privPos_btnClearAOIs,...
                'callback',             @obj.btnClearAOIs_Click);  
            obj.privBtnFolderAOIs = uicontrol(...
                'parent',               obj.privPnlAOIDef,...
                'style',                'pushbutton',...
                'string',               'Load',...
                'fontsize',             12,...
                'position',             obj.privPos_btnFolderAOIs,...
                'callback',             @obj.btnFolderAOIs_Click);
            
            % aoi scores
            str = 'AOI Scoring';
            obj.privLblAOIScores = uicontrol(...
                'parent',               obj.privPnlAOIScores,...
                'style',                'text',...
                'string',               str,...
                'position',             obj.privPos_lblAOIScores,...
                'horizontalalignment',  'left',...
                'fontsize',             12,...
                'fontweight',           'bold'); 
            obj.privBtnScoreAOIs = uicontrol(...
                'parent',               obj.privPnlAOIScores,...
                'style',                'pushbutton',...
                'string',               'Score',...
                'fontsize',             12,...
                'enable',               'on',...
                'position',             obj.privPos_btnScoreAOIs,...
                'callback',             @obj.btnScoreAOIs_Click);
            obj.privBtnClearAOIScores = uicontrol(...
                'parent',               obj.privPnlAOIScores,...
                'style',                'pushbutton',...
                'string',               'Clear',...
                'fontsize',             12,...
                'enable',               'off',...
                'position',             obj.privPos_btnClearAOIScores,...
                'callback',             @obj.btnClearAOIScores_Click); 
            obj.privBtnLoadAOIScores = uicontrol(...
                'parent',               obj.privPnlAOIScores,...
                'style',                'pushbutton',...
                'string',               'Load',...
                'fontsize',             12,...
                'position',             obj.privPos_btnLoadAOIScores,...
                'callback',             @obj.btnLoadAOIScores_Click);            
            obj.privBtnSaveAOIScores = uicontrol(...
                'parent',               obj.privPnlAOIScores,...
                'style',                'pushbutton',...
                'string',               'Save',...
                'fontsize',             12,...
                'enable',               'off',...
                'position',             obj.privPos_btnSaveAOIScores,...
                'callback',             @obj.btnSaveAOIScores_Click);      
            
            % default zoom to 100%
            obj.privDrawSize = obj.privWindowSize;
            obj.privDrawFocus = obj.privDrawSize(3:4) / 2;
            obj.Zoom = 1;

            set(obj.privFig, 'visible', 'on')
            
            obj.privStat.Status = '';
            
            % set AOI colour order
            obj.privAOIColourOrder = get(groot, 'DefaultAxesColorOrder');
            obj.privAOIColourIndex = 1;
            
            % set up timer
            obj.privTimer = timer(...
                'Period', 1 / 60,...
                'ExecutionMode', 'fixedDelay',...
                'TimerFcn', @obj.Listener,...
                'ErrorFcn', @obj.Listener_ERR);
            start(obj.privTimer)
        
        end
        
        % destructor
        function delete(obj)   
            
            disp('destructor')
            % stop and delete timer
            stop(obj.privTimer)
            delete(obj.privTimer)
            
            % close open screen
            if obj.privScreenOpen
                try
                    obj.CloseScreen
                catch ERR
                    disp(ERR)
%                     rethrow ERR
                end
            end
            
            % delete figure
            if obj.privFigOpen
                try
                    close(obj.privFig)
                catch ERR
                    disp(ERR)
%                     rethrow ERR
                end
            end
            
           % reset PTB prefs
            Screen('Preference', 'SkipSyncTests', obj.privPTBOldSyncTests);
            Screen('Preference', 'SuppressAllWarnings',...
                obj.privPTBOldWarningFlag);
            
        end
        
        % screen
        function OpenScreen(obj)
            
            if obj.privScreenOpen
                error('Screen already open.')
            end
            if obj.privFullscreen
                fullscreenFlag = [];
                rect = [];
                obj.privPos_Fig = [0, 0, .4, .6];
            else
                rect = obj.privWindowSize;
                fullscreenFlag = [];
                screenSize = Screen('Rect', obj.privScreenNumber);
                figPosPx = [...
                    obj.privWindowSize(1) + obj.privWindowSize(3),...
                    obj.privWindowSize(2),...
                    screenSize(3) - obj.privWindowSize(1) - obj.privWindowSize(3),...
                    screenSize(4)];
                obj.privPos_Fig = figPosPx ./ repmat(screenSize(3:4), 1, 2);
            end
            
            % resize figure if open
            if obj.privFigOpen
                set(obj.privFig, 'Units', 'normalized');
                set(obj.privFig, 'Position', obj.privPos_Fig);
                set(obj.privFig, 'Units', 'pixels');
            end
            
            % PTB
            obj.privWinPtr = Screen('OpenWindow', obj.privScreenNumber,...
                obj.Col_BG, rect, [], [], [], 1, [], fullscreenFlag);
            Screen('BlendFunction', obj.privWinPtr, GL_SRC_ALPHA,...
                GL_ONE_MINUS_SRC_ALPHA);
            Screen('Preference', 'TextAlphaBlending', 1)
            Screen('TextFont', obj.privWinPtr, 'Consolas');
            obj.privScreenOpen = true;
            
            % update any AOIs with winptr
            if ~isempty(obj.privAOIs)
                for a = 1:length(obj.privAOIs)
                    obj.privAOIs{a}.MaskWinPtr = obj.privWinPtr;
                end
            end
            
            % create shader to convert luminance channel to alpha
            obj.privAlphaShader = CreateSinglePassImageProcessingShader(...
                obj.privWinPtr, 'BackgroundMaskOut', [0, 0, 0], 10);
        
        end
        
        function CloseScreen(obj)
            if ~obj.privScreenOpen
                error('Screen is not open.')
            end
            Screen('Close', obj.privWinPtr);
            obj.privScreenOpen = false;
        end
        
        function ReopenScreen(obj)
            if obj.privScreenOpen
                obj.CloseScreen
                obj.OpenScreen
                obj.PrepareForDrawing
                obj.Draw
            end
        end   
        
        %% data
        
        function UpdateData(obj)
                        
            if isempty(obj.privData)
                obj.privDataValid = false;
                return
            end
            
            wb = waitbar(0, 'Preparing data...');

            %% build tree
            if ~isempty(obj.privDataTree)
                delete(obj.privDataTree)
            end
            
            % root node
            nodRoot = uitreenode('v0', 'ROOT', 'Segmentation',...
                [], false);
            
            % add segment nodes
            [segNames, ~, segSubs] = unique(obj.Data.addData);
            numSeg = length(segNames);
            nodSeg = cell(numSeg, 1);
            for s = 1:numSeg
                nodSeg{s} = uitreenode('v0', segNames{s},...
                    segNames{s}, [], false);
                nodRoot.add(nodSeg{s})
            end
            
            tic
            % add participant nodes
            waitbar(0, wb, 'Building segment tree');
            for d = 1:obj.Data.numIDs
                nodDat = uitreenode('v0', d, obj.Data.ids{d}, [], true);
                nodSeg{segSubs(d)}.add(nodDat)
                if mod(d, 100) == 0
                    waitbar(d / obj.privData.numIDs, wb);
                end
            end 
            toc
            
            % create tree
            obj.privDataTree = uitree('v0', 'Root', nodRoot,...
                'SelectionChangeFcn', {@obj.DataTree_Select},...
                'Position', obj.privPos_Tree);
            
            %% align frame times
            
            if ~isfield(obj.privData, 'frameTimesAligned') ||...
                    ~obj.Data.frameTimesAligned
                % get data
                mb = obj.privData.mainBuffer;
                tb = obj.privData.timeBuffer;
                eb = obj.privData.eventBuffer;
                % temp output vars
                x = cell(obj.privData.numIDs, 1);
                y = cell(obj.privData.numIDs, 1);
                ft = cell(obj.privData.numIDs, 1);
                fn = cell(obj.privData.numIDs, 1);
                fttype = cell(obj.privData.numIDs, 1);
                wb = waitbar(0, wb, 'Aligning frametimes...');
                for d = 1:obj.privData.numIDs

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
                        waitbar(d / obj.privData.numIDs, wb,...
                            sprintf('Aligning frametimes [%d of %d]',...
                            d, obj.privData.numIDs));
                    end
                end
                obj.privData.x = x;
                obj.privData.y = y;
                obj.privData.ft = ft;
                obj.privData.fn = fn;
                obj.privData.frameTimesAligned = true;

                % offer to save aligned data
                resp = questdlg('Save data with aligned frametimes?',...
                    'Save', 'Yes', 'No', 'Yes');
                if strcmpi(resp, 'YES')
                    savePath = uiputfile;
                    if ~(isnumeric(savePath) && savePath == 0)
                        seg = obj.privData;
                        save(savePath, 'seg', '-v7.3')
                        clear seg
                    end
                end
                
            end
            obj.privDataValid = true;
            close(wb)

        end
        
        function UpdateSelection(obj, sel)
            obj.ClearAOIScores;
            obj.ClearAOIs;
            obj.ClearStimulusImage;
            selIdx = find(sel);
            val = obj.privData.addData{selIdx(1)};
            obj.privSelLabel = val;
            % do aoi lookup
            if isfield(obj.privData, 'aoiLookup') &&...
                    ~isempty(obj.privData.aoiLookup)
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
                                aoi{a}.MaskWinPtr = obj.privWinPtr;
                                aoi{a}.SetStaticMask(aoiPath{a})
                            otherwise
                                error('Not yet implemented.')
                        end
                    end
                    obj.AddAOI(aoi)
                end
            end
            % do stim lookup
            if isfield(obj.privData, 'stimLookup') &&...
                    ~isempty(obj.privData.stimLookup)
                found = find(strcmpi(obj.Data.stimLookup(:, 1),...
                    val));
                if ~isempty(found)
                    obj.ClearStimulusImage;
                    stimPath = obj.Data.stimLookup{found, 2};
                    obj.SetStimulusImage(stimPath);
                end
            end
            % set selection flags
            obj.privSel = sel;
            obj.privSelValid = true;
            obj.privWaitToDraw = false;
            obj.PrepareForDrawing
            obj.Draw
            % get x and y coords
            dx          = obj.privData.x(obj.privSel);
            dy          = obj.privData.y(obj.privSel);
            numSel      = sum(obj.privSel);
            numFrames   = obj.privMaxFrames;
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
            if ~obj.privDataValid 
                error('No valid data')
            end
            if ~obj.privSelValid
                error('Must select some data.')
            end
            fpMb = sum(cellfun(@(x) sum(x(:)), obj.Data.mainBuffer(obj.privSel)));
            fpTb = sum(cellfun(@(x) sum(x(:)), obj.Data.timeBuffer(obj.privSel)));
            fp = num2str(fpMb / fpTb, '%.100f');
        end
        
        function ClearResults(obj)
            obj.privResults = [];
        end
        
        %% stimulus
        function SetStimulusImage(obj, path)
            % check path
            if ~exist(path, 'file')
                error('Path does not exist.')
            end
            % attempt to load
            try
                obj.privStimImg = imread(path);
                obj.privStimImgTexPtr = Screen('MakeTexture',...
                    obj.privWinPtr, obj.privStimImg);
            catch ERR
                error('Error whilst loading image: \n\n%s', ERR.message)
            end
            obj.privStimType = 'IMAGE';
            w = size(obj.privStimImg, 2);
            h = size(obj.privStimImg, 1);
            stimAR = w / h;
            drawAR = (obj.privDrawSize(3) - obj.privDrawSize(1)) /...
                (obj.privDrawSize(4) - obj.privDrawSize(2));
            if stimAR ~= drawAR
                if stimAR > 1           % wide
                    obj.privStimScale = [1, 1 / stimAR];
                elseif stimAR < 1       % tall
                    obj.privStimScale = [1 / stimAR, 1];
                end
            end
            obj.privStimValid = true;
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
                [obj.privStimMovPtr, obj.privStimMovDur,...
                    obj.privStimMovFPS, obj.privStimMovW,...
                    obj.privStimMovH, obj.privStimMovFrames] =...
                    Screen('OpenMovie', obj.privWinPtr, path, [],...
                        [], [], pixelFormat);
                obj.privFrame = 1;
                Screen('SetMovieTimeIndex', obj.privStimMovPtr, 0);
            catch ERR
                error('Error whilst loading video: \n\n%s', ERR.message)
            end
            obj.privStimType = 'MOVIE';
            stimAR = obj.privStimMovW / obj.privStimMovH;
            drawAR = (obj.privDrawSize(3) - obj.privDrawSize(1)) /...
                (obj.privDrawSize(4) - obj.privDrawSize(2));
            if stimAR ~= drawAR
                if stimAR > 1           % wide
                    obj.privStimScale = [1, 1 / stimAR];
                elseif stimAR < 1       % tall
                    obj.privStimScale = [1 / stimAR, 1];
                end
            end
            obj.privStimValid = true;
            obj.PrepareForDrawing
            obj.Draw            
        end
            
        function ClearStimulusImage(obj)
            obj.privStimValid = false;
            obj.privStimDrawSize = [];
            obj.privStimAR = [];
            obj.privStimType = [];
            obj.privStimImg = [];
            obj.privStimTexPtr = [];
            obj.privStimPath = [];
            obj.privStimMovPtr = [];
            obj.privStimMovDur = [];
            obj.privStimMovW = [];
            obj.privStimMovH = [];
            obj.privStimMovFPS = [];
            obj.privStimMovFrames = [];
            obj.Draw
        end
        
        function UpdateStimulusStatus(obj)
            switch obj.privStimValid
                case true
                    str = sprintf('valid [%s]', obj.privStimType);
                    col = [0.00, 0.80, 0.00];
                    set(obj.privBtnClearStim, 'enable', 'on');
                    set(obj.privBtnSetStimImage, 'enable', 'off');
                    set(obj.privBtnSetStimMovie, 'enable', 'off');
                case false
                    str = 'not present';
                    col = [0.80, 0.00, 0.00];
                    set(obj.privBtnClearStim, 'enable', 'off');
                    set(obj.privBtnSetStimImage, 'enable', 'on');
                    set(obj.privBtnSetStimMovie, 'enable', 'on');                    
            end
            set(obj.privLblStimStatus, 'string',...
                sprintf('Stimulus overlay: %s', str),...
                'foregroundcolor', col);
        end
        
        %% aoi
        function AddAOI(obj, val)
            if ~iscell(val), val = {val}; end
            if all(cellfun(@(x) isa(x, 'ECKAOI2'), val))
                for a = 1:length(val)
                    % set the vis' winptr
                    if obj.privScreenOpen
                        val{a}.MaskWinPtr = obj.privWinPtr;
                    end
                    idx = length(obj.privAOIs) + 1;
                    % update the colour, if it hasn't been specified
                    if val{a}.ColourOnDefault
                        obj.privAOIColourIndex = obj.privAOIColourIndex + 1;
                        val{a}.Colour =...
                            obj.privAOIColourOrder(obj.privAOIColourIndex, :)...
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
                    obj.privAOIs{idx} = val{a};
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
            fileMask = {'.mp4', '.mov', '.avi', '.m4v'};
            [pth, name, ext] = cellfun(@fileparts, allFiles, 'uniform',...  % get exts
                false);
            found = ismember(ext, fileMask);
%             found = cellfun(@(x) any(strcmpi(fileMask, x)), ext);           % filter ext
            found = found & strncmpi(name, 'aoi_', 4);                      % filter 'aoi_'
            foundPaths = allFiles(found);
            foundFiles = name(found);
            if isempty(foundPaths) 
                error('No AOI folders found in path.')
            end
            
            num = length(foundPaths);
            for a = 1:num
                aoi = ECKAOI2;
                aoi.MaskWinPtr = obj.privWinPtr;
                aoi.SetDynamicMask(foundPaths{a}, foundFiles{a});
                aoi.Colour = round(obj.privAOIColourOrder(...
                    obj.privAOIColourIndex, :) * 255);
                obj.privAOIColourIndex = obj.privAOIColourIndex + 1;
                obj.AddAOI(aoi);
            end
            obj.UpdateAOIs;
        end
            
        function ClearAOIs(obj)
            obj.privAOIValid = false;
            obj.privAOIs = [];
            obj.privAOIColourIndex= 1;
            obj.UpdateAOIs
            obj.Draw
        end
        
        function RemoveAOI(obj, idx)
            if idx <= length(obj.privAOIs)
                obj.privAOIs(idx) = [];
                obj.UpdateAOIs
            else
                error('Index out of bounds.')
            end
        end
        
        function [suc, oc, lab] = ScoreAOIs(obj)
            % default return values
            oc = 'Unknown error';
            lab = obj.privSelLabel;
            suc = false;
            
            obj.privAOIScoreValid = false;
            if isempty(obj.privAOIs)
                oc = 'No AOIs defined';
                suc = false;
                return
            end
            if ~obj.privSelValid
                oc = 'Selection not valid';
                suc = false;
                return
            end
            wb = waitbar(0, 'Scoring AOIs...');
            obj.PrepareForDrawing
            % get numbers and prepare output var
            numData = sum(obj.privSel);
            
%             % ////////////////////////////////////////////////////////
%             % temp ugly solution to shiftdim not working when only one
%             % subject has data
%             if numData == 1
%                 oc = 'Scoring AOIs with dataset of N=1 doesnt work';
%                 suc = false;
%                 return
%             end
%             % ////////////////////////////////////////////////////////            
            
            numFrames = obj.privMaxFrames;
            numAOIs = length(obj.privAOIs);     
            scores = zeros(numData, numFrames, numAOIs);
            % get x and y gaze coords in a 2D [ID, frame] matrix
            x = shiftdim(obj.privCoordsNorm(1, :, :));
            y = shiftdim(obj.privCoordsNorm(2, :, :));
            % if only one subject is selected, shiftdim doesn't work
            % properly, so correct the shape of the matrix
            if numData == 1, x = x'; y = y'; end
            % make time vector to pass to AOIs
            t = 1 / obj.FPS:1 / obj.FPS:obj.Duration;
            % loop through AOIs
            for a = 1:numAOIs
                msg = sprintf('Scoring AOIs... [%s]', obj.privAOIs{a}.Name);
                wb = waitbar(a / numAOIs, wb, msg);
                res = obj.AOIs{a}.Score(t, x, y);
                scores(:, :, a) = res;
            end
            % update state
            suc = true;
            oc = 'OK';
            obj.privAOIScoreValid = true;
            obj.privAOIScores = scores;
            obj.privAOIScoresDirty = true;
            obj.privResults = [];   % clear cache
            close(wb)
            obj.PrepareForDrawing
            obj.Draw
        end
        
        function [res, suc, oc, lab] = BatchScoreAOIs(obj)
            % find unique segments
            [su, ~, si] = unique(obj.privData.addData);
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
            if ~obj.privAOIScoreValid
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
            aoiscores.data = obj.privAOIScores;
            aoiscores.fingerprint = obj.DataFingerprint;
            aoiscores.aoitable = obj.AOITable;
            save(path_out, 'aoiscores');
            obj.privAOIScoresDirty = false;
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
            tab = obj.AOITable;
            if ~isequal(aoiscores.aoitable(:, 2), tab(:, 2))
                error('AOI scores do not match current AOI definitions.')
            end
            % set
            obj.privAOIScoreValid = true;
            obj.privAOIScores = aoiscores.data;
            obj.privAOIScoresDirty = false;
            obj.UpdateAOIScoreDisplay
            obj.PrepareForDrawing
            obj.Draw
        end
        
        function ClearAOIScores(obj)
            obj.privAOIScoreValid = false;
            obj.privAOIScores = [];
            obj.UpdateAOIs
            obj.PrepareForDrawing
            obj.Draw
            obj.ShowHideAnalysisPanel
        end
        
        function CheckAOIsDirty(obj)
            % offer to save AOI scores if dirty
            if obj.privAOIScoresDirty && obj.privAOIScoreValid
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
            num = length(obj.privAOIs);
            if num == 0, return, end
            % build table
            for a = 1:num
                aoi = obj.privAOIs{a};
                colStr = sprintf(...
                    '<html><table border=0 width=%d bgcolor=#%s><TR></TR> </table></html>',...
                    400, rgb2hex(aoi.Colour));
                tab = [tab; {aoi.Visible, aoi.Name,...
                    aoi.Type, colStr}];
            end
            uitableAutoColumnHeaders(obj.privTblAOI);
        end
        
        function UpdateAOIs(obj)
            obj.privAOIValid = ~isempty(obj.privAOIs);
            if obj.privAOIValid
                str = 'AOI Definitions: present';
                col = [0.00, 0.80, 0.00];
                set(obj.privBtnRemoveAOI, 'enable', 'on');
                set(obj.privBtnClearAOI, 'enable', 'on');
                set(obj.privBtnFolderAOIs, 'enable', 'off');
            else
                str = 'AOI Definitions: not present';
                col = [0.80, 0.00, 0.00];
                set(obj.privBtnRemoveAOI, 'enable', 'off');
                set(obj.privBtnClearAOI, 'enable', 'off');
                set(obj.privBtnFolderAOIs, 'enable', 'on');                
            end
            set(obj.privLblAOIDef, 'string', str, 'foregroundcolor', col);
            tab = obj.AOITable;
            set(obj.privTblAOI, 'data', tab);
%             obj.Draw
        end

        %% drawing
        
        function UpdateDrawSize(obj)
            
            % check for mouse position - if it is over the window, then use
            % that as the focus (around which to scale the drawing plane) -
            % otherwise use the centre of the window
            [mx, my] = GetMouse(obj.privWinPtr);
            if...
                    mx >= obj.privWindowSize(1) &&...
                    mx <= obj.privWindowSize(3) &&...
                    my >= obj.privWindowSize(2) &&...
                    my <= obj.privWindowSize(4)
                obj.privDrawFocus = [mx, my];
            else
                obj.privDrawFocus = obj.privWindowSize(3:4) / 2;
            end

            % centre window  
            wcx = obj.privDrawFocus(1);
            wcy = obj.privDrawFocus(2);
            rect = obj.privDrawSize - [wcx, wcy, wcx, wcy];
            
            % apply zoom
            rect = rect * obj.privZoom;
            obj.privDrawOffset = obj.privDrawOffset * obj.privZoom;
            
            % apply aspect ratio correction
            screenAR = obj.privWindowSize(3) / obj.privWindowSize(4);
            if screenAR > 1     % wide
                rect([1, 3]) = rect([1, 3]) ./ obj.privARFactor;
            elseif screenAR < 1 % tall
                rect([2, 4]) = rect([2, 4]) ./ obj.privARFactor;
            end
            
            % de-centre window
            obj.privDrawSize = rect + [wcx, wcy, wcx, wcy];
           
            % reset zoom
            obj.privZoom = 1;
            
        end
        
        function PrepareForDrawing(obj)
            
            if ~obj.privDataValid && ~obj.privStimValid
                obj.privDrawingPrepared = false;
                return
            end
            
            % if wait for drawing flag is set, don't draw
            if obj.privWaitToDraw
                obj.privDrawingPrepared = false;
                return
            end
            
            % width of drawing plane
            drW = obj.privDrawSize(3) - obj.privDrawSize(1);
            
            % check that the drawing plane is not out of bounds
            if obj.privDrawSize(1) > obj.privWindowSize(3)
                % left hand edge
                obj.privDrawSize(1) = obj.privWindowSize(3);
                obj.privDrawSize(3) = obj.privDrawSize(1) + drW;
            end
            
            % width/height of drawing plane
            drW = obj.privDrawSize(3) - obj.privDrawSize(1);
            drH = obj.privDrawSize(4) - obj.privDrawSize(2);    
            
            % stimulus
            if obj.privStimValid
                switch obj.privStimType
                    case 'IMAGE'
                        obj.privStimTexPtr = Screen('MakeTexture',...
                            obj.privWinPtr, obj.privStimImg);
                end
                % rescale
                rect = obj.privDrawSize;
%                 wcx = rect(3) / 2;
%                 wcy = rect(4) / 2;             
%                 rect = rect - [wcx, wcy, wcx, wcy];
%                 rect = rect .* repmat(obj.privStimScale, 1, 2);
%                 rect = rect + [wcx, wcy, wcx, wcy];
                obj.privStimDrawSize = rect;
            end
            
            if obj.privSelValid
                
                % gather selected data
                x = obj.privData.x(obj.privSel);
                y = obj.privData.y(obj.privSel);
                ft = obj.privData.ft(obj.privSel);
                fn = obj.privData.fn(obj.privSel);
                numSel = length(fn);

                % update max number of frames
                obj.privMaxFrames = max(cell2mat(fn));

                % make matrix of frame * coords for gaze points
                mat = nan(2, numSel, obj.privMaxFrames);
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
                matPx(1, :, :) = (mat(1, :, :) .* drW) + obj.privDrawSize(1);
                matPx(2, :, :) = (mat(2, :, :) .* drH) + obj.privDrawSize(2);
                
                % colour gaze points by AOI
                obj.privCoordsCol = zeros(3, numSel, obj.privMaxFrames);
                r = repmat(255, numSel, obj.privMaxFrames);
                g = repmat(255, numSel, obj.privMaxFrames);
                b = repmat(255, numSel, obj.privMaxFrames);
                if ~isempty(obj.privAOIs) && obj.privAOIScoreValid
                    for a = 1:length(obj.privAOIs)
                        idx = find(obj.privAOIScores(:, :, a) == 1);
                        r(idx) = obj.privAOIs{a}.Colour(1);
                        g(idx) = obj.privAOIs{a}.Colour(2);
                        b(idx) = obj.privAOIs{a}.Colour(3);
                    end
                    r = reshape(r, 1, size(r, 1), size(r, 2));
                    g = reshape(g, 1, size(g, 1), size(g, 2));
                    b = reshape(b, 1, size(b, 1), size(b, 2));
                    obj.privCoordsCol = [r; g; b];
                else
                    obj.privCoordsCol =...
                        repmat(obj.Col_Series', 1, numSel, obj.privMaxFrames);
                end

                % store 
                obj.privCoordsNorm = mat;
                obj.privCoords = matPx;
            end
                        
            obj.privDrawingPrepared = true;
            
        end
        
        function Draw(obj)
            
            if obj.privDrawingPrepared && ~obj.privWaitToDraw
                
                % set BG color and text size
                Screen('FillRect', obj.privWinPtr, obj.Col_BG);                
                Screen('TextSize', obj.privWinPtr, obj.ChannelLabelFontSize);

                % stimulus
                if obj.privStimValid && obj.DrawStimulus
                    switch obj.privStimType
                        case 'MOVIE'
                            if obj.privTime < obj.privStimMovDur
                                Screen('SetMovieTimeIndex', obj.privStimMovPtr,...
                                    obj.privTime);
                                obj.privStimTexPtr = Screen('GetMovieImage',...
                                    obj.privWinPtr, obj.privStimMovPtr);
                                if obj.privStimTexPtr >= 0
                                    Screen('DrawTexture', obj.privWinPtr,...
                                        obj.privStimTexPtr, [], obj.privStimDrawSize);     
                                end
                            end
                        case 'IMAGE'
                            Screen('DrawTexture', obj.privWinPtr,...
                                obj.privStimImgTexPtr, [], obj.privStimDrawSize);
                    end
                end
                
                % AOIs
                if ~isempty(obj.privAOIs)
                    for a = 1:length(obj.privAOIs)                                
                        if obj.privAOIs{a}.Visible &&...
                                obj.privAOIs{a}.OnsetTime <= obj.privTime &&...
                                obj.privAOIs{a}.OffsetTime >= obj.privTime
                            switch obj.privAOIs{a}.Type
                                case {'DYNAMIC MASK', 'STATIC MASK'}
                                    [suc, aoiPtr] =...                        
                                        obj.privAOIs{a}.GetFrame(obj.privTime);
                                    if suc
                                        aoiCol = obj.privAOIs{a}.Colour;
                                        Screen('DrawTexture', obj.privWinPtr,...
                                            aoiPtr, [], obj.privDrawSize, [],...
                                            [], 1 / 4, [aoiCol, 255 / 2],...
                                            obj.privAlphaShader);       
                                    end
                                case 'RECT'
                                    rect = obj.privAOIs{a}.Rect .*...
                                        repmat(obj.privDrawSize(3:4), 1, 2);
                                    aoiCol = [obj.privAOIs{a}.Colour, 255 * .25];
                                    aoiRect = obj.privAOIs{a}.Rect .*...
                                        repmat(obj.privDrawSize(3:4), 1, 2);
                                    Screen('FillRect', obj.privWinPtr,...
                                        aoiCol, aoiRect);
                                    Screen('FrameRect', obj.privWinPtr,...
                                        aoiCol(1:3), aoiRect, 2);
                                    Screen('DrawLine', obj.privWinPtr,...
                                        aoiCol(1:3), aoiRect(1), aoiRect(2),...
                                        aoiRect(3), aoiRect(4), 2);
                                    Screen('DrawLine', obj.privWinPtr,...
                                        aoiCol(1:3), aoiRect(3), aoiRect(2),...
                                        aoiRect(1), aoiRect(4), 2);                                    
                                    DrawFormattedText(obj.privWinPtr,...
                                        obj.privAOIs{a}.Name, 'center',...
                                        'center', obj.Col_Label, [], [],...
                                        [], [], [], aoiRect);
                                    
                            end
                        end
                    end
                end
                    
                % draw ET data
                if obj.privDataValid && obj.privSelValid &&...
                        obj.privFrame <= obj.privMaxFrames
                
                    % draw heatmap
                    if obj.privHeatmapsPrepared && obj.DrawHeatmap
                        hm = obj.privHeatmaps(:, :, :, obj.Frame);
                        alpha = obj.privHeatmapsAlpha(:, :, obj.Frame);
                        hm(:, :, 4) = alpha;
                        hmTex = Screen('MakeTexture', obj.privWinPtr, hm);
                        Screen('DrawTexture', obj.privWinPtr, hmTex, [],...
                            obj.privDrawSize, [], [], .6)
                    end
                    
                    % draw gaze points
                    if obj.DrawGaze
                        % additional white rings for when AOIs are present
                        if obj.privAOIScoreValid
                            Screen('DrawDots', obj.privWinPtr,...
                                obj.privCoords(:, :, obj.privFrame),...
                                5,...
                                obj.privCoordsCol(:, :, obj.privFrame),...
                                [], 3);
                            gps = 2;
                        else
                            gps = obj.GazePointSize;
                        end
                        Screen('DrawDots', obj.privWinPtr,...
                            obj.privCoords(:, :, obj.privFrame),...
                            gps,...
                            [255, 255, 255],...
                            [], 3);   
                    end
                    
                    % draw quivers
                    if obj.DrawQuiver && sum(obj.privSel) > 1
                        f2 = obj.Frame;
                        f1 = f2 - obj.QuiverFrameSpan;
                        if f1 < 1, f1 = 2; end
                        quiv = [obj.privCoords(:, :, f1),...
                            obj.privCoords(:, :, f2)];
                        numSel = sum(obj.privSel);
                        qord = [1:2:(numSel * 2) - 1, 2:2:numSel * 2];
                        [~, so] = sort(qord);
                        quiv = quiv(:, so);
                        quivColAlpha1 = obj.QuiverAlpha * 255;
                        quivColAlpha2 = 0;
                        quivCol2 =...
                            [obj.privCoordsCol(:, :, obj.privFrame);...
                            repmat(quivColAlpha1, 1, numSel)];
                        quivCol1 =...
                            [obj.privCoordsCol(:, :, obj.privFrame);...
                            repmat(quivColAlpha2, 1, numSel)];       
                        quivCol = [quivCol1, quivCol2];
                        quivCol = quivCol(:, so);
                        
                        if obj.privAOIScoreValid
                            quivColWhite = quivCol;
                            quivColIdx = 1:2:size(quivColWhite, 2);
                            quivCol(1:3, quivColIdx) = repmat(255, 3, size(quivColIdx, 2));
%                             Screen('DrawLines', obj.privWinPtr,...
%                                 quiv, 6, quivCol);                            
                        end
                        Screen('DrawLines', obj.privWinPtr,...
                            quiv, 4, quivCol);
                    end
                 
                end


                % draw messages
                msg = [];
                if ~isempty(msg)
                    Screen('TextSize', obj.privWinPtr, 16);
                    tb = Screen('TextBounds', obj.privWinPtr, msg);
                    msgX = ((obj.privWindowSize(3) -...
                        obj.privWindowSize(1)) / 2) - (tb(3) / 2);
                    msgY = obj.privWindowSize(1) + tb(4) + 5;
                    Screen('DrawText', obj.privWinPtr, msg, msgX, msgY,...
                        obj.Col_Label, obj.Col_LabelBG);
                end
                
                % information pane
                if obj.DrawInfoPane
                    % place info pane 10px from bottom left
                    ix1 = 1;
                    ix2 = ix1 + obj.InfoPaneSize(1);
                    iy2 = obj.privWindowSize(4);
                    iy1 = iy2 - obj.InfoPaneSize(2);
                    % draw info pane BG
                    Screen('FillRect', obj.privWinPtr, [obj.Col_LabelBG, 200],...
                        [ix1, iy1, ix2, iy2]);
                    Screen('FrameRect', obj.privWinPtr, obj.Col_Label,...
                        [ix1, iy1, ix2, iy2]);  
                end
                
                % trial line
                obj.privTimeLineValid = false;
                if obj.privDataValid && obj.privSelValid &&...
                        obj.DrawTimeLine 
                    
                    if obj.DrawInfoPane
                        % if drawing info pane, place trial line so that it
                        % doesn't overlap
                        tlx1 = ix2 + 10;
                        tlx2 = obj.privWindowSize(3) - tlx1;
                    else
                        % otherwise, use full width of screen
                        tlx1 = 10;
                        tlx2 = obj.privWindowSize(3) - tlx1;
                    end
                    tlh = 50;                           % height
                    tly2 = obj.privWindowSize(4);       % bottom edge
                    tly1 = tly2 - tlh;                  % top edge
                    tlw = tlx2 - tlx1;                  % width
                    
                    % check width is valid, if window is too small then the
                    % timeline won't fit
                    if tlw >= 50
                        obj.privTimeLineX = [tlx1, tlx2];
                        obj.privTimeLineY = [tly1, tly2];

                        % calculate steps for tick marks
                        tlxStep = tlw / obj.Duration;
                        tlFrameW = obj.privMaxFrames / tlw;
                        tlx = tlx1 + sort(repmat(tlxStep:tlxStep:tlw, 1, 2));
                        tly = repmat([tly1, tly2], 1, length(tlx) / 2);

                        % calculate pos of box representing current trial
                        tltx1 = tlx1 + (tlxStep * obj.Time);
                        tltx2 = tltx1 + 1;

                        Screen('FillRect', obj.privWinPtr, [obj.Col_LabelBG, 150],...
                            [tlx1, tly1, tlx2, tly2]);
                        Screen('FillRect', obj.privWinPtr, obj.Col_Label,...
                            [tltx1, tly1, tltx2, tly2]);
                        Screen('FrameRect', obj.privWinPtr, [obj.Col_Label, 100],...
                            [tlx1, tly1, tlx2, tly2]);
                        Screen('DrawLines', obj.privWinPtr, [tlx; tly],...
                            1, [obj.Col_Label, 100]);    

                        % draw timecode
                        msg = sprintf('%s | %.1fs | Frame %d of %d',...
                            obj.TimeString, obj.Time, obj.Frame,...
                            obj.privMaxFrames);
                        Screen('TextSize', obj.privWinPtr, 24);
                        tb = Screen('TextBounds', obj.privWinPtr, msg);
                        msgX = ((obj.privWindowSize(3) -...
                            obj.privWindowSize(1)) / 2) - (tb(3) / 2);
                        msgY = obj.privWindowSize(1) + tb(4) + 5;
                        Screen('DrawText', obj.privWinPtr, msg, msgX, msgY,...
                            obj.Col_Label, obj.Col_LabelBG);

                        obj.privTimeLineValid = true;
                    end

                end
                
%                 obj.temp(end + 1) = Screen('Flip', obj.privWinPtr);
                Screen('Flip', obj.privWinPtr);
                    
            end
            
        end
        
        function PrepareHeatmaps(obj)
            
            if ~obj.privDataValid
                error('Cannot prepare heatmaps without valid data.')
            end
            
            if ~obj.privSelValid || ~any(obj.privSel)
                error('Cannot prepare heatmaps without some data selected.')
            end
                        
            wb = waitbar(0, 'Making heatmaps...');
                        
            % set up heatmap resolutions, and gather data into x and y
            % coords
            ar = obj.AspectRatio(1) / obj.AspectRatio(2);
            workRes = round(...
                [obj.HeatmapWorkRes, obj.HeatmapWorkRes / ar]);
            outRes = round(obj.privDrawSize(3:4) * obj.HeatmapResScale);
            x = shiftdim(obj.privCoords(1, :, :), 1);
            y = shiftdim(obj.privCoords(2, :, :), 1);
            
            % preallocate heatmap output
            hm = zeros(outRes(2), outRes(1), 3, obj.privMaxFrames,...
                'uint8');
            alpha = zeros(outRes(2), outRes(1), obj.privMaxFrames,...
                'uint8'); 
            pxRes = obj.privDrawSize(3:4);
            % loop through all frames and prepare heatmaps
            for f = 1:obj.privMaxFrames
                [hm(:, :, :, f), alpha(:, :, f)] =...
                    etHeatmap4(x(:, f), y(:, f), workRes,...
                    outRes, pxRes, obj.HeatmapColorMap);
                if mod(f, 7) == 0
                    waitbar(f / obj.privMaxFrames, wb);
                end
            end
            obj.privHeatmaps = hm;
            obj.privHeatmapsAlpha = alpha;
            close(wb)
            obj.privHeatmapsPrepared = true;
            obj.Draw
                        
        end
        
        function UpdateAOIScoreDisplay(obj)
            
            if ~obj.privAOIScoreValid || obj.privWaitToDraw
%                 warning('AOI scores not valid.')
                return
            end
            
            % time vector
            tStep = obj.Duration / size(obj.privAOIScores, 2);
            t = tStep:tStep:obj.Duration;
            hTs = obj.privAxsAOITimeSeries;
            hMu = obj.privAxsAOIMeans;
            hHist = obj.privAxsAOIHist;
            
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
            obj.privRecCursor = rectangle(hTs,...
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
                set(b, 'FaceColor', obj.privAOIs{a}.Colour / 255);
            end
            hold(hMu, 'off')
            set(hMu, 'xtick', 1:length(res.AOIMean));
            set(hMu, 'xticklabel', obj.AOINames); 
            legend(hMu, obj.AOINames, 'textcolor', obj.Col_Label / 255,...
                'color', obj.Col_LabelBG / 255, 'interpreter', 'none');
            
            % table
            set(obj.privTblAOIValues,...
                'data', table2cell(res.AOIMeansTable)',...
                'rowname', res.AOIMeansTable.Properties.VariableNames,...
                'columnname', res.AOIMeansTable.Properties.RowNames);
            uitableAutoColumnHeaders(obj.privTblAOIValues)
            
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
            rPtr = Screen('CreateMovie', obj.privWinPtr, path_out, [],...
                [], obj.FPS, ':CodecType=VideoCodec=x264enc Keyframe=15 Videobitrate=24576');
            obj.PrepareForDrawing;
            % loop through frames
            for f = 1:obj.privMaxFrames
                obj.Frame = f;
                Screen('AddFrameToMovie', obj.privWinPtr, [], [], rPtr);
            end
            Screen('FinalizeMovie', rPtr);
        end
        
        function PlotSubjectAOIScores(obj, selIdx)
            % check selection is valid
            if ~obj.Selection(selIdx)
                error('Index %d is not selected.', selIdx)
            end
            % check scores
            if ~obj.privAOIScoreValid
                error('AOI scores not calculated.')
            end
            % make new figure
            fig = figure('name', 'AOI Scores', 'menubar', 'none',...
                'numbertitle', 'off');
            % data wrangling
            scores = shiftdim(obj.privAOIScores(selIdx, :, :), 1);
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
            obj.privWaitToDraw = true;
            obj.CheckAOIsDirty
            val = tree.SelectedNodes(1).getValue;
            if ischar(val)
                if strcmpi(val, 'ROOT')
                    % root node selected - not a valid data selection
                    obj.privSel = [];
                    obj.privSelValid = false;
                else
                    % get indices of all child segments
                    sel = strcmpi(obj.Data.addData, val);
                    obj.UpdateSelection(sel)
                end
            else
                % otherwise, take a single index
                obj.privSel = false(length(obj.privData.ids), 1);
                obj.privSel(val) = true;
                obj.privSelValid = true;
            end 
            obj.privHeatmapsPrepared = false;
            obj.privHeatmaps = [];
            obj.privHeatmapsAlpha = [];
            obj.privAOIScoreValid = false;
            obj.privAOIScores = [];
            obj.privWaitToDraw = false;
            obj.PrepareForDrawing
            obj.Draw
        end
        
        function UpdateUIPositions(obj)

            % get figure size in pixels. If figure hasn't been created yet,
            % quit out
            set(obj.privFig, 'units', 'pixels');
            figPosPx = get(obj.privFig, 'Position');
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
            
            obj.privPos_Stim = [...
                                1,...
                                1,...
                                leftDiv,...
                                stimH,...
                              ];
            obj.privPos_AOIScores = [...
                                1,...
                                stimH + 1,...
                                leftDiv,...
                                aoiScoreH,...
                            ];                          
            obj.privPos_AOIDef = [...
                                1,...
                                stimH + 1 + aoiScoreH,...
                                leftDiv,...
                                aoiDefH,...
                             ];    

            obj.privPos_PnlAOIAnalysis = [...
                                leftDiv,...
                                h - aoiAnalysisH,...
                                w - leftDiv...
                                aoiAnalysisH,...
                            ];
            obj.privPos_Tree = [...
                                1,... 
                                stimH + aoiDefH + aoiScoreH + 1,...
                                leftDiv,...
                                h - stimH - aoiDefH - aoiScoreH
                            ];
                        
            % aoi analysis
            w = obj.privPos_PnlAOIAnalysis(3);
            h = obj.privPos_PnlAOIAnalysis(4);
            tsH = h * .6;
            muW = w * .33;
            sp = 2;     % pixel spacing
            asp = 27;   % axis spacing
            obj.privPos_AxsAOITimeSeries =      [asp, h - tsH + asp, w - asp - sp, tsH - asp - sp];
            obj.privPos_AxsAOIMeans =           [w - muW + asp, asp, muW - asp - sp, h - tsH - asp - sp];
            obj.privPos_AxsAOIHist =            [muW + asp, asp, muW - asp - sp, h - tsH - asp - sp];
            obj.privPos_TblAOIValues =          [asp, asp, w - muW * 2 - asp - sp, h - tsH - asp - sp];
                        
            % stimulus
            w = obj.privPos_Stim(3);
            h = obj.privPos_Stim(4);
            bw = 80;
            bh = 27;
            obj.privPos_lblStimStatus =         [3, bh + 3, w, th]; 
            obj.privPos_btnSetStimMovie =       [0 * bw, 1, bw, bh];
            obj.privPos_btnSetStimImage =       [1 * bw, 1, bw, bh];
            obj.privPos_btnClearStim =          [2 * bw, 1, bw, bh];
            
            % aoi def
            w = obj.privPos_AOIDef(3);
            h = obj.privPos_AOIDef(4);
            bw = 60;        
            obj.privPos_tblAOI =                [1, bh, w, h - bh * 2];
            obj.privPos_lblAOIDef =             [3, h - th - 4, w, th]; 
            obj.privPos_btnAddAOI =             [0 * bw, 0 * bh, bw, bh];
            obj.privPos_btnRemoveAOI =          [1 * bw, 0 * bh, bw, bh];
            obj.privPos_btnClearAOIs =          [2 * bw, 0 * bh, bw, bh];
            obj.privPos_btnFolderAOIs =         [3 * bw, 0 * bh, bw, bh];
            
            % aoi scores
            w = obj.privPos_AOIScores(3);
            h = obj.privPos_AOIScores(4);
            bw = 60;        
            obj.privPos_lblAOIScores =          [3, h - bh - 4, w, th]; 
            obj.privPos_btnScoreAOIs =          [0 * bw, 0 * bh, bw, bh];
            obj.privPos_btnClearAOIScores =     [1 * bw, 0 * bh, bw, bh];
            obj.privPos_btnLoadAOIScores =      [2 * bw, 0 * bh, bw, bh];
            obj.privPos_btnSaveAOIScores =      [3 * bw, 0 * bh, bw, bh];
            
        end
       
        function Figure_Resize(obj, h, dat)
            obj.UpdateUIPositions
            set(obj.privDataTree,           'Position', obj.privPos_Tree);
            set(obj.privPnlAOIDef,          'Position', obj.privPos_AOIDef);
            set(obj.privPnlStim,            'Position', obj.privPos_Stim);
            set(obj.privPnlAOIAnalysis,     'Position', obj.privPos_PnlAOIAnalysis);
            set(obj.privAxsAOITimeSeries,   'Position', obj.privPos_AxsAOITimeSeries);
            set(obj.privAxsAOIMeans,        'Position', obj.privPos_AxsAOIMeans);
            set(obj.privAxsAOIHist,         'Position', obj.privPos_AxsAOIHist);
            set(obj.privTblAOIValues,       'Position', obj.privPos_TblAOIValues);
        end
        
        function Listener(obj, ~, ~)
            % react to time line clicks
            if obj.privTimeLineValid
                % get mouse pos
                [mx, my, mButtons] = GetMouse(obj.privWinPtr);
                % if cursor is not on drawing window, stop
                if mx < 0 || my < 0 || mx > obj.privWindowSize(3) ||...
                        my > obj.privWindowSize(4)
                    return
                end
                % deal with mouse up/down events
                if ~isempty(obj.privMouseButtons) && mButtons(1)
                    % mouse down - check if cursor is on timeline
                    if my >= obj.privTimeLineY(1) &&...
                            my <= obj.privTimeLineY(2) &&...
                            mx >= obj.privTimeLineX(1) &&...
                            mx <= obj.privTimeLineX(2)
                        % translate cursor pos to time, update accordingly
                        xProp = (mx - obj.privTimeLineX(1)) /...
                            (obj.privTimeLineX(2) - obj.privTimeLineX(1));
                        obj.Time = obj.Duration * xProp;
                    end
                elseif ~isempty(obj.privMouseButtons) &&...
                        obj.privMouseButtons(1) && ~mButtons(1)
                    % mouse up - update AOI scores
                    obj.UpdateAOIScoreDisplay
                end
                % record cursor pos, for interrogation next time
                obj.privMouseX = mx;
                obj.privMouseY = my;
                obj.privMouseButtons = mButtons;
            end            
        end
        
        function Listener_ERR(obj, q, w)
            rethrow ERR
        end
        
        function ShowHideAnalysisPanel(obj, ~, ~)
            if obj.privSelValid && obj.privDataValid &&...
                    obj.privAOIScoreValid
                set(obj.privPnlAOIAnalysis, 'visible', 'on')
                set(obj.privPnlAOIDisabled', 'visible', 'off')  
            else
                set(obj.privPnlAOIAnalysis, 'visible', 'off')
                set(obj.privPnlAOIDisabled', 'visible', 'on')                 
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
            obj.privStimImagePrevDir = pth;
        end
        
        function btnSetStimMovie_Click(obj, ~, ~)
            filterSpec = {...
                '*.mp4',    'MP4 Files'     ;...
                '*.mov',    'MOV Files',    ;...
                '*.m4v',    'M4V Files',    ;...
                '*.avi',    'AVI Files',   };
            [file, pth] = uigetfile(filterSpec, 'Set stimulus movie');
            if isequal(file, 0) || isequal(pth, 0)  % user pressed cancel
                return
            end
            obj.SetStimulusMovie(fullfile(pth, file));
            obj.privStimMoviePrevDir = pth;
        end
        
        function tblAOI_EditCell(obj, h, dat)
            sel = dat.Indices(1);
            switch dat.Indices(2)
                case 1  % visible
                    obj.privAOIs{sel}.Visible = dat.NewData;
                case 2  % name
                    obj.privAOIs{sel}.Name = dat.NewData;
                case 3  % type
                    obj.privAOIs{sel}.Type = dat.NewData;
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
% %             newData = uisetcolor(obj.privAOIs{sel}.Colour / 255);
%             if ~isequal(newData, 0)
%                 obj.privAOIs{sel}.Colour = newData * 255;
%                 obj.UpdateAOIs;
%             end
        end
        
        function btnAddAOI_Click(obj, ~, ~)
        end
        
        function btnRemoveAOI_Click(obj, ~, ~)
        end
        
        function btnClearAOIs_Click(obj, ~, ~)
            obj.privAOIs = {};
            obj.UpdateAOIs;
        end
        
        function btnFolderAOIs_Click(obj, ~, ~)
            path = uigetdir([], 'Add AOIs from folder');
            if isequal(path, 0), return, end
            obj.AddDynamicAOIFromFolder(path);
        end
        
        function btnScoreAOIs_Click(obj, ~, ~)
            if ~obj.privAOIValid
                error('AOI definitions not valid.')
            end
            obj.ScoreAOIs;
        end
        
        function btnClearAOIScores_Click(obj, ~, ~)
            if ~obj.privAOIValid
                error('AOI definitions not valid.')
            end
            obj.ClearAOIScores
        end
        
        function btnLoadAOIScores_Click(obj, ~, ~)
            obj.LoadAOIScores;
        end
        
        function btnSaveAOIScores_Click(obj, ~, ~)
            if ~obj.privAOIValid
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
            val = obj.privScreenNumber;
        end
        
        function set.ScreenNumber(obj, val)
            % check bounds
            screens = Screen('screens');
            if val > max(screens) || val < min(screens)
                error('ScreenNumber must be between %d and %d.',...
                    min(screens), max(screens))
            end
            obj.privScreenNumber = val;
            obj.ReopenScreen
        end
        
        function val = get.WindowSize(obj)
            val = obj.privWindowSize;
        end
        
        function set.WindowSize(obj, val)
            if obj.Fullscreen
                warning('Window size not set when running in fullscreen mode.')
            else
                obj.privLastWindowSize = obj.WindowSize;
                obj.privWindowSize = round(val);
                obj.privDrawSize = round(val);
                obj.UpdateDrawSize
                obj.ReopenScreen
            end
        end
                
        function val = get.Zoom(obj)
            val = obj.privZoom;
        end
        
        function set.Zoom(obj, val)
            if val < .5, val = .5; end
            obj.privZoom = val;
            obj.UpdateDrawSize
            obj.PrepareForDrawing
            obj.Draw
        end
        
        function val = get.Fullscreen(obj)
            val = obj.privFullscreen;
        end
        
        function set.Fullscreen(obj, val)
            obj.privFullscreen = val;
            
            % determine whether we are going in or out of fullscreen;
            % record new and old window size
            if val
                oldSize = obj.privWindowSize;
                newSize = Screen('Rect', obj.privScreenNumber);
                obj.privLastWindowSize = oldSize;
            else
                oldSize = obj.privWindowSize;
                newSize = obj.privLastWindowSize;
            end
            
            % set focus to screen centre, and zoom to required value given
            % the ratio of new to old size 
            obj.privDrawFocus = oldSize(3:4) / 2;
            obj.privZoom = newSize / oldSize;

            % centre window  
            wcx = obj.privDrawFocus(1);
            wcy = obj.privDrawFocus(2);
            rect = oldSize - [wcx, wcy, wcx, wcy];

            % apply zoom
            rect = rect * obj.privZoom;
            obj.privDrawOffset = obj.privDrawOffset * obj.privZoom;

            % de-centre window
            wcx = wcx * obj.privZoom;
            wcy = wcy * obj.privZoom;
            obj.privDrawSize = rect + [wcx, wcy, wcx, wcy];

            % reset zoom
            obj.privZoom = 1;

            % store new (fullscreen) window size
            obj.privWindowSize = newSize;
            obj.ReopenScreen
        end
        
        function set.Col_BG(obj, val)
            if obj.privScreenOpen
                Screen('FillRect', obj.privWinPtr, val);
                obj.Draw
            end
        end
        
        function set.Col_FG(obj, val)
            obj.Col_FG = val;
            obj.Draw
        end
        
        function val = get.Data(obj)
            val = obj.privData;
        end
        
        function set.Data(obj, val)
            % check data type
            if ~isstruct(val) || ~isfield(val, 'mainBuffer') ||...
                    ~isfield(val, 'timeBuffer') || ~isfield(val, 'addData')
                error('Data must be gathered segments')
            end
            obj.privData = val;
            pbj.privDataValid = false;
            obj.UpdateData
            obj.PrepareForDrawing
            obj.Draw
        end      
        
        function val = get.Frame(obj)
            if obj.privDataValid
                val = obj.privFrame;
            else
                val = [];
            end
        end
        
        function set.Frame(obj, val)
            if obj.privDataValid
                if val >= obj.privMaxFrames
                    val = obj.privMaxFrames;
                elseif val == 0
                    val = 1;
                elseif val < 0
                    error('A frame number <0 was requested.')
                end
                obj.privFrame = val;
                obj.privTime = obj.privFrame * (1 / obj.FPS);
                obj.Draw
                if obj.privAOIScoreValid
                    set(obj.privRecCursor, 'position',...
                        [obj.Time, 0, 1 / obj.FPS, 1]);
                end
            else
                warning('Cannot set frame number until data has been loaded.')
            end
        end
        
        function set.Time(obj, val)
            if val > obj.Duration, val = obj.Duration; end
            if val < 0, val = 0; end
            obj.privTime = val;
            obj.Frame = round(val * obj.FPS);
        end
        
        function val = get.Time(obj)
            val = obj.privTime;
        end
        
        function val = get.AspectRatio(obj)
            val = obj.privDrawSize(3:4) /...
                gcd(obj.privDrawSize(3), obj.privDrawSize(4));
        end
        
        function set.AspectRatio(obj, val)
            if ~isvector(val) || length(val) ~= 2
                error('Aspect ratio must be a vector of length 2 [x, y].')
            end
            obj.privARFactor = val(1) / val(2);
            obj.UpdateDrawSize
            obj.PrepareForDrawing
            obj.Draw
        end
        
        function val = get.Duration(obj)
            if ~obj.privDataValid || isempty(obj.privSel)
                val = [];
            else
                val = obj.privMaxFrames / obj.FPS;
            end
        end
        
        function val = get.TimeString(obj)
            val = datestr(obj.Time / 86400, 'HH:MM.SS.FFF');
        end
        
        function val = get.AOIs(obj)
            val = obj.privAOIs;
        end
        
        function set.privStimValid(obj, val)
            obj.privStimValid = val;
            obj.UpdateStimulusStatus
            obj.PrepareForDrawing
            obj.Draw
        end
        
        function set.privAOIScores(obj, val)
            obj.privAOIScores = val;
            obj.UpdateAOIScoreDisplay
        end
        
        function set.privAOIScoreValid(obj, val)
            obj.ShowHideAnalysisPanel
            obj.privAOIScoreValid = val;
        end
        
        function set.privSelValid(obj, val)
            obj.ShowHideAnalysisPanel
            obj.privSelValid = val;
        end
        
        function set.privDataValid(obj, val)
            obj.ShowHideAnalysisPanel
            obj.privDataValid = val;
        end
        
        function val = get.Results(obj)
            
            % attempt to return cached results
            if ~isempty(obj.privResults)
                val = obj.privResults;
                return
            end
            
            if ~obj.privAOIScoreValid
                val = [];
                return
            end
            
            wb = waitbar(0, 'Preparing results...Proportions');
            
            % get IDs and timepoints
            ids                         = obj.privData.ids(obj.privSel);
            tp                          = obj.privData.timePoints(obj.privSel);
            
            % time vector
            t = 0:1 / obj.FPS:obj.Duration;
            
            % get raw scores
            scores                      = obj.privAOIScores;
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
                        tab_aoi = repmat({obj.privAOIs{a}.Name}, numLooks, 1);
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
                1:obj.privMaxFrames, 'uniform', false);
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
                obj.privData.timePoints(obj.privSel)',...
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
            
            obj.privResults = val;
            
            delete(wb)
            
        end
        
        function val = get.AOINames(obj)
            if ~obj.privAOIValid
                val = [];
                return
            end
            tab = obj.AOITable;
            val = tab(:, 2);
        end
        
        function val = get.StimulusResolution(obj)
            val = [];
            if ~obj.privStimValid, return, end
            switch obj.privStimType
                case 'MOVIE'
                    val = [obj.privStimMovW, obj.privStimMovH];
                otherwise
                    error('Not yet implemented.')
            end
        end
        
        function set.privAOIColourIndex(obj, val)
            if val > size(obj.privAOIColourOrder, 1)
                val = 1;
            end
            obj.privAOIColourIndex = val;
        end
        
        function val = get.Selection(obj)
            val = obj.privSel;
        end
        
%         function val = get.X(obj)
%             val = obj.privData.x
%         end
%         function set.privAOIValid(obj, val)
% 
%         end
        
%         function set.privAOIScores(obj, val)
%             obj.privAOIScores = val;
%             obj.privAOIScoresDirty = true;
%         end
        
    end
 
end

