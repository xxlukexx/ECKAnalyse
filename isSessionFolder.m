function [outcome] = isSessionFolder(sessionPath)

    outcome = false;
    
    if ~exist(sessionPath, 'dir')
%         warning('Path not found: \n  %s', sessionPath);
        return
    end
    
    % get files in path
    d = dir(sessionPath);
    d = shiftdim(struct2cell(d), 3);
    
    outcome = any(strcmpi(d(:, 1), 'tracker.mat'));
    outcome = outcome & any(strcmpi(d(:, 1), 'tempData.mat'));
    outcome = any(strcmpi(d(:, 1), 'tempData.mat'));
    
end