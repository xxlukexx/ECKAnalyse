function checkScreenflash(videoPath, sfPath, saveImage)

    if ~exist('saveImage', 'var') || isempty(saveImage)
        saveImage = false;
    end
    
    if ~exist('sfPath', 'var') || isempty(sfPath)
        sfPath = [videoPath, '.screenflash_v7.mat'];
        if ~exist(sfPath, 'file')
            error('Must supply a valid sf file.')
        end
    end
    
    framesToShow = 10;
    frameStep = 1;

    vr = VideoReader(videoPath);
    sf = load(sfPath);
    
    % temp hack whilst I reprocess to correct wrong frame number
%     sf.sfFrame = sf.sfFrame + 19;
    
    if ~sf.found
        fprintf('<strong>checkScreenflash:</strong>Screen flash not found.\n')
        return
    end
    
    numSF = length(sf.sfTime);
    fprintf('<strong>checkScreenflash:</strong> %d screen flashes found.\n',...
        numSF)
    
    eof = sf.sfFrame > vr.NumberOfFrames;
    if any(eof)
        fprintf('<strong>checkScreenflash:</strong>Impossible frame value(s) (EOF):\n')
        fprintf('\t%d\n', sf.sfFrame(eof));
    end
    
    if all(eof)
        fprintf('<strong>checkScreenflash:</strong>All screen flahes > EOF.\n')
        return
    end
    
    % fiter for valid (i.e. not EOF) flashes
    sf.sfTime = sf.sfTime(~eof);
    sf.sfFrame = sf.sfFrame(~eof);
    numSF = length(sf.sfTime);
    
    for s = 1:numSF
        
        fig = figure(...
            'Name', sprintf('Screen flash %d, time: %.0fs, frame: %d',...
            s, sf.sfTime(s), sf.sfFrame(s) + 1),...
            'Menubar', 'none',...
            'Toolbar', 'none');
        
        fprintf('<strong>checkScreenflash:</strong>Reading frames...\n')
        frameStart = sf.sfFrame(s) - framesToShow;
        frameEnd = sf.sfFrame(s) + framesToShow - 1;
        if frameStart < 1, frameStart = 1; end
        if frameEnd > vr.NumberOfFrames, frameEnd = vr.NumberOfFrames - 1; end
        frameNums =...
            frameStart:frameStep:frameEnd;
        numFrames = length(frameNums);
        numSP = numSubplots(numFrames);
            
        frm = read(vr, [frameNums(1), frameNums(end)]);
        for f = 1:(numFrames / frameStep) - 1
            
            sp = subplot(numSP(1), numSP(2), f);
            img = imshow(frm(:, :, :, f));
            
            if frameNums(f) == sf.sfFrame(s)
                title(sprintf('>> Frame %d <<', frameNums(f)))
            else
                title(sprintf('Frame %d', frameNums(f)))
            end

        end
        
        if saveImage
            imgFilename = [videoPath, '.checkSF_', num2str(s), '.png'];
            print(fig, '-dpng', imgFilename);
        end
        
    end
    
    delete(vr)
    
end