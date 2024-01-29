classdef ECKVideoBuilder < handle
    
    properties (Dependent)
        TaskName
    end
    
    properties (Access = private)
        
        % UI
        pFig
        pFig_pos                    = [0.33, 0.33, 0.66, 0.66]
        pFigOpen                    = false
        pLblTaskName 
        pLblTaskName_pos            = [0.00, 0.95, 0.15, 0.05]
        pTxtTaskName            
        pTxtTaskName_pos            = [0.15, 0.95, 0.40, 0.05]
        pLstVideos
        pLstVideos_pos              = [0.00, 0.05, 0.45, 0.90]
        pLstOrder
        pLstOrder_pos               = [0.55, 0.05, 0.45, 0.90]
        pBtnOrderUp         
        pBtnOrderUp_pos             = [0.45, 0.70, 0.10, 0.05]        
        pBtnAdd
        pBtnAdd_pos                 = [0.45, 0.65, 0.10, 0.05]
        pBtnRemove               
        pBtnRemove_pos              = [0.45, 0.60, 0.10, 0.05]
        pBtnOrderDown           
        pBtnOrderDown_pos           = [0.45, 0.55, 0.10, 0.05]
        pBtnOrderClear              
        pBtnOrderClear_pos          = [0.45, 0.50, 0.10, 0.05]
        pBtnAddVideo            
        pBtnAddVideo_pos            = [0.00, 0.00, 0.10, 0.05]
        pBtnRemoveVideo             
        pBtnRemoveVideo_pos         = [0.10, 0.00, 0.10, 0.05]
        pBtnClearVideos             
        pBtnClearVideos_pos         = [0.20, 0.00, 0.10, 0.05]
        pBtnGenerateCode    
        pBtnGenerateCode_pos        = [0.55, 0.00, 0.10, 0.05]
        pVideos
        pOrder
        
    end
    
    properties (Constant)
        CONST_defListFontSize       = 14
    end
    
    methods
        
        function o = ECKVideoBuilder
            
            %% UI
            
            % make figure
            set(0, 'DefaultTextInterpreter', 'none')
            o.pFig = figure(...
                'NumberTitle',          'off',...
                'Units',                'normalized',...
                'Position',             o.pFig_pos,...
                'Menubar',              'none',...
                'Toolbar',              'none',...
                'Name',                 'ECK Video Builder',...
                'visible',              'on',...
                'renderer',             'opengl');
%                 'DeleteFcn',            @o.delete,...
%                 'ResizeFcn',            @o.Figure_Resize,...            
            o.pFigOpen = true;
%             set(o.pFig, 'Units', 'Pixels')

            % UI controls
            o.pLblTaskName  = uicontrol(...
                                'parent',           o.pFig,...
                                'Units',            'normalized',...
                                'style',            'text',...
                                'position',         o.pLblTaskName_pos,...
                                'string',           'Task Name',...
                                'fontsize',         o.CONST_defListFontSize,...
                                'enable',           'on');
                                        
            o.pTxtTaskName  = uicontrol(...
                                'parent',           o.pFig,...
                                'Units',            'normalized',...
                                'style',            'edit',...
                                'position',         o.pTxtTaskName_pos,...
                                'string',           'videos',...
                                'fontsize',         o.CONST_defListFontSize,...
                                'horizontalalignment', 'left',...
                                'enable',           'on');
                            
            o.pLstVideos    = uicontrol(...
                                'parent',           o.pFig,...
                                'Units',            'normalized',...
                                'style',            'listbox',...
                                'position',         o.pLstVideos_pos,...
                                'string',           'No videos added',...
                                'fontsize',         o.CONST_defListFontSize,...
                                'callback',         @o.LstVideos_Select,...
                                'enable',           'off');
                            
            o.pLstOrder     = uicontrol(...
                                'parent',           o.pFig,...
                                'Units',            'normalized',...
                                'style',            'listbox',...
                                'position',         o.pLstOrder_pos,...
                                'string',           'No order defined',...
                                'fontsize',         o.CONST_defListFontSize,...
                                'callback',         @o.LstOrder_Select,...
                                'enable',           'off');  
                            
            o.pBtnOrderUp    = uicontrol(...
                                'parent',           o.pFig,...
                                'Units',            'normalized',...
                                'style',            'pushbutton',...
                                'position',         o.pBtnOrderUp_pos,...
                                'string',           'Up',...
                                'fontsize',         o.CONST_defListFontSize,...
                                'callback',         @o.BtnOrderUp_Click,...
                                'enable',           'off');            
                            
            o.pBtnAdd       = uicontrol(...
                                'parent',           o.pFig,...
                                'Units',            'normalized',...
                                'style',            'pushbutton',...
                                'position',         o.pBtnAdd_pos,...
                                'string',           '->',...
                                'fontsize',         o.CONST_defListFontSize,...
                                'callback',         @o.BtnAdd_Click,...
                                'enable',           'off');    
                            
            o.pBtnRemove    = uicontrol(...
                                'parent',           o.pFig,...
                                'Units',            'normalized',...
                                'style',            'pushbutton',...
                                'position',         o.pBtnRemove_pos,...
                                'string',           '<-',...
                                'fontsize',         o.CONST_defListFontSize,...
                                'callback',         @o.BtnRemove_Click,...
                                'enable',           'off');                               

            o.pBtnOrderDown = uicontrol(...
                                'parent',           o.pFig,...
                                'Units',            'normalized',...
                                'style',            'pushbutton',...
                                'position',         o.pBtnOrderDown_pos,...
                                'string',           'Down',...
                                'fontsize',         o.CONST_defListFontSize,...
                                'callback',         @o.BtnOrderDown_Click,...
                                'enable',           'off');
                            
            o.pBtnOrderClear = uicontrol(...
                                'parent',           o.pFig,...
                                'Units',            'normalized',...
                                'style',            'pushbutton',...
                                'position',         o.pBtnOrderClear_pos,...
                                'string',           'Clear Order',...
                                'fontsize',         o.CONST_defListFontSize,...
                                'callback',         @o.BtnOrderClear_Click,...
                                'enable',           'off');
        
            o.pBtnAddVideo = uicontrol(...
                                'parent',           o.pFig,...
                                'Units',            'normalized',...
                                'style',            'pushbutton',...
                                'position',         o.pBtnAddVideo_pos,...
                                'string',           'Add Video',...
                                'fontsize',         o.CONST_defListFontSize,...
                                'callback',         @o.BtnAddVideo_Click,...
                                'enable',           'on');
                            
%             o.pBtnRemoveVideo = uicontrol(...
%                                 'parent',           o.pFig,...
%                                 'Units',            'normalized',...
%                                 'style',            'pushbutton',...
%                                 'position',         o.pBtnRemoveVideo_pos,...
%                                 'string',           'Remove Video',...
%                                 'fontsize',         o.CONST_defListFontSize,...
%                                 'callback',         @o.BtnRemoveVideo_Click,...
%                                 'enable',           'off');
                            
%             o.pBtnClearVideos = uicontrol(...
%                                 'parent',           o.pFig,...
%                                 'Units',            'normalized',...
%                                 'style',            'pushbutton',...
%                                 'position',         o.pBtnClearVideos_pos,...
%                                 'string',           'Clear Videos',...
%                                 'fontsize',         o.CONST_defListFontSize,...
%                                 'callback',         @o.BtnClearVideos_Click,...
%                                 'enable',           'off');
                            
            o.pBtnGenerateCode = uicontrol(...
                                'parent',           o.pFig,...
                                'Units',            'normalized',...
                                'style',            'pushbutton',...
                                'position',         o.pBtnGenerateCode_pos,...
                                'string',           'Generate Code',...
                                'fontsize',         o.CONST_defListFontSize,...                                'callback',         @o.BtnOrderUp_Click,...
                                'callback',         @o.BtnGenerateCode_Click,...
                                'enable',           'off');
                            
            o.UpdateVideoList
            o.Figure_Resize
        end
        
        function AddVideo(o, path_in)
            % check path and video format
            if ~exist(path_in, 'file')
                errordlg('Video path not found.')
                return
            end
            try
                inf = mmfileinfo(path_in);
            catch ERR
                errordlg('Invalid video format.')
                return
            end
            % split path
            [pth, file, ext] = fileparts(path_in);
            filename = [file, ext];
            % store
            o.pVideos{end + 1, 1}   = pth;
            o.pVideos{end,     2}   = filename;
            o.UpdateVideoList
        end
        
        function UpdateVideoList(o)
            if isempty(o.pVideos)
                set(o.pLstVideos, 'string', 'No videos added')
                set(o.pLstVideos, 'enable', 'off')
            else
                set(o.pLstVideos, 'string', o.pVideos(:, 2))
                set(o.pLstVideos, 'enable', 'on')
            end
            o.UpdateButtons
        end
        
        function UpdateOrderList(o)
            if isempty(o.pOrder)
                set(o.pLstOrder, 'string', 'No order defined')
                set(o.pLstOrder, 'enable', 'off')
            else
                set(o.pLstOrder, 'enable', 'on')
                val = get(o.pLstOrder, 'value');
                if val > length(o.pOrder), 
                    val = length(o.pOrder); 
                    set(o.pLstOrder, 'value', val);
                end
                set(o.pLstOrder, 'string', o.pVideos(o.pOrder, 2))
            end
            o.UpdateButtons
        end
        
        function UpdateButtons(o)
            if isempty(o.pVideos)
                set(o.pBtnRemoveVideo, 'enable', 'off')
                set(o.pBtnClearVideos, 'enable', 'off')
                set(o.pBtnAdd, 'enable', 'off')
            else
                set(o.pBtnRemoveVideo, 'enable', 'on')
                set(o.pBtnClearVideos, 'enable', 'on')   
                set(o.pBtnAdd, 'enable', 'on')
            end
            if isempty(o.pOrder)
                set(o.pBtnRemove, 'enable', 'off')
                set(o.pBtnOrderClear, 'enable', 'off')
                set(o.pBtnGenerateCode, 'enable', 'off')
                set(o.pBtnOrderUp, 'enable', 'off')
                set(o.pBtnOrderDown, 'enable', 'off')                  
            else
                set(o.pBtnRemove, 'enable', 'on')
                set(o.pBtnOrderClear, 'enable', 'on')
                set(o.pBtnGenerateCode, 'enable', 'on')
                val = get(o.pLstOrder, 'value');
                % check there are at least 2 entries
                if length(o.pOrder) > 1 
                    % check the entry is not already first
                    if val ~= 1
                        set(o.pBtnOrderUp, 'enable', 'on')
                    else
                        set(o.pBtnOrderUp, 'enable', 'off')
                    end
                    % check the entry is not already last
                    if val ~= length(o.pOrder)
                        set(o.pBtnOrderDown, 'enable', 'on')
                    else
                        set(o.pBtnOrderDown, 'enable', 'off')                    
                    end
                else
                    set(o.pBtnOrderUp, 'enable', 'off')
                    set(o.pBtnOrderDown, 'enable', 'off')                    
                end
            end
        end
        
        %% CALLBACKS
        
        % UI
        function Figure_Resize(o)
            bounds = get(o.pLblTaskName, 'extent');
            o.pLblTaskName_pos(3) = bounds(3);
            o.pTxtTaskName_pos(1) = o.pLblTaskName_pos(1) + bounds(3);
            o.pTxtTaskName_pos(3) = 1 - o.pTxtTaskName_pos(1);
            set(o.pLblTaskName, 'position', o.pLblTaskName_pos)
            set(o.pTxtTaskName, 'position', o.pTxtTaskName_pos)
        end           
        
        % lists
        function LstVideos_Select(o, h, dat)
            o.UpdateButtons
        end
        
        function LstOrder_Select(o, h, dat)
            o.UpdateButtons
        end
        
        % video management
        function idx = GetVideoIndex(o)
            val     = get(o.pLstVideos, 'value');
            if isempty(val)
                errdialog('Selected video not found in video store - DEBUG!')
                return
            end
            items   = get(o.pLstVideos, 'string');
            items   = items(val);
            idx     = find(strcmpi(o.pVideos(:, 2), items), 1, 'first');
        end
        
        function BtnAddVideo_Click(o, h, dat)
            [fil, pth] = uigetfile('*.*', 'Select video file',...
                'multiselect', 'on');
            % check for cancel
            if isequal(fil, 0), return, end
            % if single selection, put into cell array
            if ~iscell(fil), fil = {fil}; end
            cellfun(@(x) o.AddVideo(fullfile(pth, x)), fil)
        end
        
        function BtnRemoveVideo_Click(o, h, dat)
            % remove entry from video list
            vidIdx = o.GetVideoIndex;
            if isempty(vidIdx)
                error('No video returned - DEBUG!')
            end
            o.pVideos(vidIdx, :) = [];
            % remove entry from order list
            ordIdx = find(o.pOrder == vidIdx);
            o.UpdateVideoList;
            if ~isempty(ordIdx)
                o.pOrder(ordIdx) = [];
                o.UpdateOrderList;
            end
        end
        
        % order management
        function BtnAdd_Click(o, h, dat)
            % look up current value in videos list
            idx = o.GetVideoIndex;
            o.pOrder(end + 1) = idx;
            o.UpdateOrderList
        end
        
        function BtnRemove_Click(o, h, dat)
            val = get(o.pLstOrder, 'value');
            if isempty(val), errordlg('Tried to remove nonexistant order - DEBUG!')
                return
            end
            o.pOrder(val) = [];
            o.UpdateOrderList;
        end
        
        function BtnOrderUp_Click(o, h, dat)
            val = get(o.pLstOrder, 'value');
            curOrd = 1:length(o.pOrder);
            curOrd(val) = curOrd(val) - 1;
            curOrd(val - 1) = curOrd(val - 1) + 1;
            o.pOrder = o.pOrder(curOrd);
            set(o.pLstOrder, 'value', val - 1);
            o.UpdateOrderList;
        end
        
        function BtnOrderDown_Click(o, h, dat)
            val = get(o.pLstOrder, 'value');
            curOrd = 1:length(o.pOrder);
            curOrd(val) = curOrd(val) + 1;
            curOrd(val + 1) = curOrd(val + 1) - 1;
            o.pOrder = o.pOrder(curOrd);
            set(o.pLstOrder, 'value', val + 1);
            o.UpdateOrderList;
        end
        
        function BtnOrderClear_Click(o, h, dat)
            o.pOrder = [];
            o.UpdateOrderList;
        end
        
        % code generation
        function BtnGenerateCode_Click(o, h, dat)
            
            % check that videos and order have been defined
            if isempty(o.pVideos)
                errordlg('No videos have been added.')
                return
            end
            if isempty(o.pOrder)
                errordlg('No order has been defined.')
                return
            end
            
            % get output folder
            path_out = uigetdir(pwd, 'Select output folder');
            % check that dialog was not cancelled
            if isequal(path_out, 0)
                return
            end
            % check path is valid
            if ~exist(path_out, 'dir')
                errordlg('Output path does not exist.')
                return
            end
            
            % get list of videos to be played, in order
            vids = cellfun(@(x, y) fullfile(x, y),...
                o.pVideos(o.pOrder, 1), o.pVideos(o.pOrder, 2),...
                'uniform', false);
            
            % make code generator
            gen = ECKCodeGenerator(path_out);
            load('ECKCodeGenerator_instance.mat')
            
            % write main script
            gen.StartFile(o.TaskName, 'main');
            gen.WriteCode('header');
            for v = 1:length(vids)
                vidName = o.pVideos{o.pOrder(v), 2};
                gen.WriteCode('loadMovie', 'filename', vids{v},...
                    'moviename', vidName);
            end
            gen.WriteCode('eyeTracker');
            gen.WriteCode('log', 'outputpath', path_out);
            gen.WriteCode('calibrate');
            gen.WriteCode('design');
            
            % write trial list
            tl = {};
            tl = [tl; 'trials.Table = {...'];
            tl = [tl;       sprintf('\t''Nested'',\t''Function''\t\t''BGColour'',\t\t\t''VideoFile''\t;...')];
            tl = [tl;       sprintf('\t1,\t\t\t''screenflash'',\t[000, 000, 000],\t[],\t\t\t;...')];
            gen.Write(tl);
            for v = 1:length(vids)
                tl = {};
                vidName = o.pVideos{o.pOrder(v), 2};
                tl = [tl;   sprintf('\t1,\t\t\t''fixation'',\t\t[000, 000, 000],\t[],\t\t\t;...')];
                tl = [tl;   sprintf('\t1,\t\t\t''%s_trial'',\t[000, 000, 000],\t''%s'',\t;...', o.TaskName, vidName)];
                gen.Write(tl);
            end
            tl = {};
            tl = [tl;       sprintf('\t1,\t\t\t''screenflash'',\t[000, 000, 000],\t[],\t\t\t};')];
            gen.Write(tl);
            gen.WriteCode('taskListParams');
            gen.WriteCode('startET');
            gen.WriteCode('startMain');
            gen.WriteCode('stopET');
            gen.WriteCode('stopMain');
            
            gen.EditFile
            gen.CloseFile
            
            % copy video trial function
            copyfile(fullfile(pwd, '_repository', 'videos_trial.m'), path_out)
            copyfile(fullfile(pwd, '_repository', 'fixation.m'), path_out)
        end
        
        % set/get
        function val = get.TaskName(o)
            val = get(o.pTxtTaskName, 'string');
        end
        
        function set.TaskName(o, val)
            set(o.pTxtTaskName, 'string', val)
        end
        
    end
  
end