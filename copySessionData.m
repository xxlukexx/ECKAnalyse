function copySessionData(md, destPath)

    if ~exist(destPath, 'dir')
        error('Destination path not found.')
    end
    
    for ses = 1:size(md, 1);
        fname = md{ses, 4};
        
        pathSeps = strfind(fname, filesep);
        src = fname(1:pathSeps(end) - 1);
        dest = [destPath, fname(pathSeps(end - 2):pathSeps(end))];
        
        fprintf('%s...', fname);
        if ~exist(dest, 'dir'), mkdir(dest); end
        copyfile(src, dest);
        fprintf('done.\n');
        
    end
        
end