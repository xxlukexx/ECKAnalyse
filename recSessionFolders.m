function sessions = recSessionFolders(path, varargin)

    silentMode = ismember('-silent', varargin);
    
    if iscell(path)
        numPaths = length(path);
    else
        numPaths = 1;
        path = {path};
    end
    
    files = {};
    for p = 1:numPaths
        if silentMode
            files = [files; recdir(path{p}, '-silent')];
        else
            files = [files; recdir(path{p})];
        end
    end
    
    fprintf('Finding valid sessions...\n')
    
    isSes = false(size(files));
    parfor i = 1:length(files)
        isSes(i) = isfolder(files{i}) & hasGazeFolder(files{i});
    end
    sessions = files(isSes);
            
    
    
%     isFolder = cellfun(@isdir, files);
%     files(~isFolder) = [];
%     idx = cellfun(@hasGazeFolder, files);
%     sessions = files(idx);
    
end