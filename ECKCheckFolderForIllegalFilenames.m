function [hasIllegal, suc, oc] = ECKCheckFolderForIllegalFilenames(path_in)

    suc = false;
    oc = 'unknown error';
    hasIllegal = false;
    
    d = dir(path_in);
    d([d.isdir]) = [];
    files_d = {d.name};
    idx_crap = instr(files_d, '.DS_Store');
    files_d(idx_crap) = [];

    [suc, res] = system(sprintf('ls "%s"', path_in));
    parts = strsplit(res, '\n');
    parts = cellfun(@(x) strsplit(x, '\t'), parts, 'UniformOutput', false);
    parts = horzcat(parts{:});
    empty = cellfun(@isempty, parts);
    parts(empty) = [];
    files_sys = parts;
    if ~isequal(size(files_d), size(files_sys))
        oc = 'Mismatch in Matlab and system-returned files';
        return
    end
    
    idx = cellfun(@(x) find(strfind(x, '?')), files_sys, 'uniform', false);
    if any(~cellfun(@isempty, idx))
        hasIllegal = isGazeFolder(path_in);
    end
    
    suc = true;
    oc = '';
    
end