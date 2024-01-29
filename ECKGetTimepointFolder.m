function res = ECKGetTimepointFolder(pth)
    if ~exist(pth, 'dir')
        error('Path not found.')
    end
    % get files
    d = dir(pth);
    d(~[d.isdir]) = [];
    res = cell(length(d), 2);
    res(:, 1) = {d.name}';
    % process
    parfor f = 1:length(d)
        res{f, 2} = ECKGetTimePoint(fullfile(pth, d(f).name));
    end
end