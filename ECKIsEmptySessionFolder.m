function is = ECKIsEmptySessionFolder(path_in)

    if iscell(path_in)
        is = cellfun(@ECKIsEmptySessionFolder, path_in);
        return
    end

    is = false;

    % folder must exist    
    if ~exist(path_in, 'dir'), return, end
    
    % folder must have 'gaze' subfolder
    path_gaze = fullfile(path_in, 'gaze');
    if ~exist(path_gaze, 'dir'), return, end
    
    % gaze subfolder must not be empty
    d = dir(path_gaze);
    if length(d) == 2 && all(ismember({'.', '..'}, {d.name}))
        return
    end
    
    % must contain mainBuffer.mat, timeBuffer.mat and eventBuffer.mat
    file_mb = teFindFile(path_gaze, 'mainBuffer*.mat');
    file_tb = teFindFile(path_gaze, 'timeBuffer*.mat');
    file_eb = teFindFile(path_gaze, 'eventBuffer*.mat');
    
    hasMB = ~isempty(file_mb);
    hasTB = ~isempty(file_tb);
    hasEB = ~isempty(file_eb);
    if ~all([hasMB, hasTB, hasEB])
        return
    end
    
    % all buffers must be 200 bytes in size (aka empty)
    d_mb = dir(file_mb);
    d_tb = dir(file_tb);
    d_eb = dir(file_eb);
    if all([...
            isequal(d_mb.bytes, 200),...
            isequal(d_tb.bytes, 200),...
            isequal(d_eb.bytes, 200),...
            ])
        is = true;
        fprintf('Empty session folder found: %s\n', path_in);
        return
    end

end
