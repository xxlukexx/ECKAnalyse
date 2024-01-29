function ECKBatchAppendXYT(path_data)
    
    stat = ECKStatus('Finding files...\n');
    
    d = dir([path_data, filesep, '*.mat']);
    if isempty(d)
        error('No .mat files found in %s.', path_data);
    end
    
    for f = 1:length(d)
        
        stat.Status = sprintf('Converting %d of %d [%s]...\n', f,...
            length(d), d(f).name);
        
        % load
        filename = fullfile(path_data, d(f).name);
        tmp = load(filename);
        
        % append x, y, t
        data = ECKAppendXYT(tmp.data);
        save(filename, 'data');
        
    end
    
    stat.Status = sprintf('Finished.\n');
    
end

    