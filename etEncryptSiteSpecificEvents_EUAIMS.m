function dcOut = etEncryptSiteSpecificEvents_EUAIMS(data, links)

    if ~exist('links', 'var') || isempty(links)
        error('Invalid or empty links array passed.')
    end
    
    if ischar(links)
        if exist(links, 'file')
            tmp = load(links);
            links = tmp.links;
        else
            error('Attempted to load passed links argument as a file, file not found.')
        end
    elseif ~iscell(links) && ~size(links, 2) == 2
        error('Invalid or empty links array passed.')
    end
        
    encTasks = {...
        'antisaccade_trial',...
        'asahi_trial',...
        'bunnies_trial',...
        'cog_control_trial',...
        'emotion_trial',...
        'frequency_trial',...
        'hab_trial',...
        'ms_trial',...
        'ns_contingency_trial',...
        'predictability_trial',...
        'soc_contingency_trial',...
        'wm_trial'};
    
    key = 'EUAIMS';
    
    dc = checkDataIn(data);
    numData = length(dc.Data);
    dcOut = ECKDuplicateDC(dc);
    
    wb = waitbar(0, 'Encrypting site specific events');
    for d = 1:numData
        
        wb = waitbar(d / numData, wb, 'Encrypting site specific events');
        dcOut.Data{d}.EventBuffer =...
            etEncryptEvents(dc.Data{d}.EventBuffer, links, encTasks, key);
        
    end
    
    close(wb)

end