function [files_ses, suc, oc] = ECKFixAllGazePaths(path_in)

    fprintf('Finding all files...\n');
    path_adds = '/Volumes/Projects/ADDS/ET/incoming';
    files = recdir(path_in);
    
    fprintf('Finding folder...\n');
    idx_dir = cellfun(@(x) exist(x, 'dir'), files);
    files(~idx_dir) = [];
    
    fprintf('Finding gaze folders...\n');
    idx_gaze = instr(files, sprintf('%sgaze', filesep));
    files(~idx_gaze) = [];
    
    fprintf('Finding illegal filenames...\n');
    [illegal, suc, oc] = cellfun(@ECKCheckFolderForIllegalFilenames, files, 'UniformOutput', false);
    tab = table;
    tab.path = files;
    illegal = cell2mat(illegal);
    tab.illegal = illegal;
    tab.suc = suc;
    tab.oc = oc;
    
    % find parent (session) folders
    files(~illegal) = [];
    parts = cellfun(@(x) strsplit(x, filesep), files, 'UniformOutput', false);
    files_ses = cellfun(@(x) [filesep, fullfile(x{1:end - 1})], parts,...
        'UniformOutput', false);
    
    numFiles = length(files_ses);
    suc = false(numFiles, 1);
    oc = repmat({'unknown error'}, numFiles, 1);
    for i = 1:numFiles
        
        try
            data = ECKData;
            data.Load(files_ses{i});
            ECKFixGazePaths(data)
            fprintf('%s - success\n', files_ses{i});
        catch ERR
            oc(i) = ERR.message;
            fprintf('%s - failed (%s)\n', files_ses{i}, ERR.message);
        end
        
    end

end