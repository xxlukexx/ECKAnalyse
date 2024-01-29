function [outcome] = hasGazeData(sessionPath)

    outcome = false;
    
    if ~exist(sessionPath, 'dir')
        warning('Path not found: \n  %s', sessionPath);
        return
    end
    
    % get files in path
    d = dir(sessionPath);
    d = shiftdim(struct2cell(d), 3);
    
    % check for gaze folder
    gazeIdx = find(strcmpi(d(:, 1), 'gaze'), 1, 'first');
    outcome = ~isempty(gazeIdx);
    if outcome
        outcome = outcome & logical(cell2mat(d(gazeIdx, 5)));
    end
    
    % check for buffers
    gazePath = [sessionPath, filesep, 'gaze'];
    mbFile = findFilename('mainBuffer', gazePath);
    tbFile = findFilename('timeBuffer', gazePath);
    ebFile = findFilename('eventBuffer', gazePath); 
    outcome = outcome & ~isempty(mbFile) & ~isempty(tbFile) &...
        ~isempty(ebFile);     

end