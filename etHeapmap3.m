function etHeapmap3(cfg)

    % draws a still image or video, optionally with stimuli, and overlays
    % eye tracking data as a heatmap
    
    %% interrogate cfg
    
    if ~exist('cfg', 'var') || ~isstruct(cfg) || isempty(cfg)
        error('Must supply a cfg struct.')
    end
    
    % make all cfg fields lowercase
    cfg = structFieldsToLowercase(cfg);
    
    % check for valid buffers
    if ~isfield(cfg, 'mainbuffer') || isempty(cfg.mainbuffer) ||...
            ~iscell(cfg.mainBuffer)
        error('Must supply cfg.mainBuffer as cell array')
    else
        mb = cfg.mainbuffer;
    end
    
    if ~isfield(cfg, 'timebuffer') || isempty(cfg.timebuffer) ||...
            ~iscell(cfg.timebuffer)
        error('Must supply cfg.timeBuffer as cell array')
    else
        tb = cfg.timebuffer;
    end    

    if ~isfield(cfg, 'eventbuffer') || isempty(cfg.eventbuffer) ||...
            ~iscell(cfg.eventbuffer)
        error('Must supply cfg.eventBuffer as cell array')
    else
        eb = cfg.eventbuffer;
    end

    if ~isfield(cfg, 'fixationbuffer') || isempty(cfg.fixationbuffer) ||...
            ~iscell(cfg.fixationbuffer)
        fixationsPresent = false;
        fb = [];
    else
        fixationsPresent = true;
        fb = cfg.fixationbuffer;
    end
    
    % check stim type
    if ~isfield(cfg, 'stimtype') || isempty(cfg.stimtype) ||...
            ~any(strcmpi(cfg.stimtype, {'IMAGE', 'VIDEO'}))
        error('Must supply cfg.stimtype as either VIDEO or IMAGE')
    else
        stimType = cfg.stimtype;
    end    
    
    % check whether align frametimes is set
    if ~isfield(cfg, 'alignframetimes') || isempty(cfg.alignframetimes) ||...
            ~islogical(cfg.alignframetimes)
        alignFT = false;
    else
        if ~strcmpi(stimType, 'VIDEO')
            warning('cfg.alignframetimes was set, but cfg.stimtype is VIDEO - setting will be ignored.')
            alignFT = false;
        else
            alignFT = cfg.alighframetimes;
        end
    end
    
    % check group settings - must be the same number of groups as buffers,
    % and as group labels
    if ~isfield(cfg, 'groupmembership') || isempty(cfg.groupmembership) ||...
            ~iscell(cfg.groupmembership)
        
        grpsDefined = false;
        grpMember = [];
        
    else
        
        % check number of groups
        grpMember = cfg.groupmembership;
        grpNum = length(grpMember);
        if ~isequal(grpNum, length(mb), length(tb), length(eb))
            error('cfg.groupmembership must the same size as buffer cell arrays.')
        end
        grpsDefined = true;
        
        % check group labels
        if ~isfield(cfg, 'grouplabels') 
            grpLabsDefined = false;
        else
            if ~iscell(cfg.grouplabels)
                error('cfg.grouplabels must be a cell array of strings.')
            end
            grpLabs = cfg.grouplabels;
            if length(grpLabs) ~= grpNum
                error('Number of cfg.grouplabels must match length of cfg.groupmembership, and of buffer cell arrays.')
            end
            grpLabsDefined = true;
        end
        
    end    
    
    % check stimpath
    if ~isfield(cfg, 'stimpath') || isempty(cfg.stimpath)
        
        stimPathPresent = false;
        stimPath = [];
        
    else
        
        if ~exist(cfg.stimpath, 'file')
            error('cfg.stimpath not found: \n%s', cfg.stimpath)
        end
        stimPath = cfg.stimpath;
        
        % check format of provided stim
        switch stimType
            
            case 'VIDEO'
                try
                    stimInf = mmfileinfo(stimPath);
                    stimPathPresent = true;
                catch ERR
                    switch ERR.identifier
                        case 'MATLAB:audiovideo:VideoReader:unsupportedImage'
                            error('cfg.stimtype is set to VIDEO, but cfg.stimpath points to an image file.')
                        case 'MATLAB:audiovideo:VideoReader:InitializationFailed'
                            error('cfg.stimtype is set to VIDEO but cfg.stimpath could not be identiifed as a video.')
                        otherwise 
                            error('Could not read video data from cfg.stimpath:\n\t%s',...
                                ERR.message)
                    end
                end
                
            case 'IMAGE'
                try
                    stimInf = imageinfo(stimPath);
                    stimPathPresent = true;
                catch ERR
                    switch ERR.identifier
                        case 'images:imageinfo:couldNotReadFile'
                            error('cfg.stimtype is set to IMAGE, but cfg.stimpath could not be indentified as an image.')
                        otherwise
                            error('Could not read image data from cfg.stimpath:\n\t%s',...
                                ERR.message)                    
                    end
                end
                
        end

    end
    
    % check output path
    if ~isfield(cfg, 'outputpath') || isempty(cfg.outputpath)
        error('Must set cfg.outputpath.')
    end
        

    
    
    
    
end