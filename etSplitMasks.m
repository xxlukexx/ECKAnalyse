function etSplitMasks(inputPath, outputPath)

    %% setup
    ECKTitle('Splitting AoI masks')
    stat = ECKStatus('Looking for files...');
    
    % check input args
    if ~exist('inputPath', 'var') || isempty(inputPath)
        error('Must specify an input path.')
    end

    if ~exist('outputPath', 'var') || isempty(outputPath)
        error('Must specify an output path.')
    end
    
    cc = etAoIColourConstants;
    
    %% look for files
    % attempt to load all image files
    d = dir(inputPath);
    f = 1;
    imgs = {};
    while f < length(d)
        
        stat.Status = sprintf('Trying to load %s...', d(f).name);
        
        try
            tmp = imread([inputPath, filesep, d(f).name]);
        catch ERR
            tmp = [];
        end
        
        if ~isempty(tmp)
            imgs{end + 1} = tmp;
        end
        
        f = f + 1;
        
    end
    
    numImgs = length(imgs);
    stat.Status = sprintf('%d images found.\n', numImgs);

    if numImgs == 0
        fprintf('No images found.\n')
        return
    end

    %% process files
    % get filed names and preallocate ouput
    featNames = fields(cc);
    numFeats = length(featNames);
    out = struct;
    for feat = 1:numFeats
        out.(featNames{feat}) = cell(size(imgs));
    end
    
    % loop through and process
    tmp = cell(size(imgs));
    for i = 1:numImgs
        
        tmp{i} = cell(1, numFeats);
        for feat = 1:numFeats
            
            tmp{i}{feat} = etSplitMask(imgs{i}, featNames{feat});
            
        end
        
    end 
    
    
end