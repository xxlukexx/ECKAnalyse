function is = isGazeFolder(gazePath)

    if exist(gazePath, 'dir') 
        
        mbFile = findFilename('mainBuffer', gazePath);
        if iscell(mbFile) && length(mbFile) > 1
            mbFile = mbFile{1};
        end
        tbFile = findFilename('timeBuffer', gazePath);
        if iscell(tbFile) && length(tbFile) > 1
            tbFile = tbFile{1};
        end
        
        if ~isempty(mbFile)
            mbWhos = whos('-file', mbFile); 
            mbSizeCheck = ~isempty(mbWhos) && mbWhos.size(1) ~= 0;
        else
            is = false;
            return
        end
        
        if ~isempty(tbFile)
            tbWhos = whos('-file', tbFile); 
            tbSizeCheck = ~isempty(tbWhos) && tbWhos.size(1) ~= 0;
        else
            is = false;
            return
        end
        
        is = ~isempty(mbFile) && ~isempty(tbFile) && mbSizeCheck && tbSizeCheck;
        
    else
        
        is = false;
        
    end
    
end