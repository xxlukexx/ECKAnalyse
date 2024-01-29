function [totFound, sfTime, sfFrame] = findScreenflash7(videoFile, maxNum,...
    rect)

    tic

    % Searches a video file for screenflashes. Uses a fairly intelligent
    % search strategy by chunking the video into sections and searching the
    % start, end and middle first, on the basis that this is where
    % screenflashes are most likely to be found. If not found here, it will
    % eventually search all of the video. 
    %
    % Note that this functions uses Psychtoolbox (PTB) and GStreamer (gst),
    % and won't run without both installed and working. 
    %
    % videoFile         -   video to search. Must be in a readable format,
    %                       e.g. MP4 (CANNOT be screenflow). 
    %
    % (maxNum)          -   terminate search after finding maxNum
    %                       screenflashes. Use if you are sure how many
    %                       screenflashes there are in the file and don't
    %                       want to waste time searching beyond this. 
    % 
    % (rect)            -   specify a portion of the video in which to
    %                       search. Be default this is a region in the
    %                       centre of the video corresponding to the
    %                       virtual window size used in Eurosibs/LEAP. 
    
    % defaults for output vars, and init fps so that is available to all
    % functions
    global fps
    totFound = 0;
    sfTime = [];
    sfFrame = [];
    
    % check input args
    if ~exist('videoFile', 'var')
        [videoFile, videoPath] = uigetfile('*.mp4', 'Select video file');
        videoFile = fullfile(videoPath, videoFile);
        if isequal(videoFile, 0)
            fprintf('Cancelled.\n')
            return
        end
    end
        
    if ~exist(videoFile, 'file') 
        error('File does not exist.')
    end
    
    if ~exist('maxNum', 'var') || isempty(maxNum)
        maxNum = inf;
    end
    
    if ~exist('rect', 'var') || isempty(rect)
        rect = [0, .1, 1, .40];
    end
    
    % get video info, open a PTB screen, and open video in PTB
    info = mmfileinfo(videoFile);                                           % video metadata
    Screen('Preference', 'SkipSyncTests', 2);                               % don't try for good timing
    Screen('Preference', 'Verbosity', 0);                                   % disable command line output from PTB
    res = [0, 0, 960, 540];                                                 % resolution of display windows
    scr = [0, 0, info.Video.Width, info.Video.Height];                      % resolution of video
    winPtr = Screen('OpenWindow', 0, [0, 0, 0], res, [], [], [],...         % open PTB screen
        [], [], kPsychGUIWindow, scr);
    [movPtr, dur, fps, w, h] = Screen('OpenMovie', winPtr, videoFile,...    % open PTB movie
        [], [], 2);
    totFrames = floor(dur * fps) - 5;                                       % calculate num frames from duration

    % rescale search rect to pixels
    rect = round([rect(1) * w, rect(2) * h, rect(3) * w, rect(4) * h]);

    % define sf duration, convert to frames
    sfDur = 2.5;
    sfDurF = sfDur * fps;
    
    % define screenflash intensity line
    sfInt = linspace(0, 255, sfDurF);
    
    % frames of a screen flash are identified by having a uniform(ish)
    % intensity range. Some noise is likely due to video compression
    % artefacts, so we leave a bit of leeway by defining (out of 255) how
    % much the intensity can vary whilst still be taken as uniform
    critRng = 20;
                
    % define search strategy - [start pos, extent, direction]
    searchDef = [...
            0.0,        0.1,      1.0   ;...    first 10%
            1.0,        0.1,     -1.0   ;...    last 10%
            0.5,        0.1,      1.0   ;...    50 - 60%
            0.5,        0.1,     -1.0   ;...    50 - 40%
            0.1,        0.3       1.0   ;...    mid remainder
            0.6,        0.3,      1.0   ;...    late remainder
        ];
    
    % loop through each search definition (i.e. chunk of video)
    for search = 1:length(searchDef)
        
        fprintf('Coarse search chunk %d of %d...\n', search,...
            length(searchDef));
        
        % define frame numbers to search around
        f1 = floor(searchDef(search, 1) * totFrames);
        if f1 < 1, f1 = 1; end
        if f1 >= totFrames, f1 = totFrames - 1; end
        extent = ceil(searchDef(search, 2) * totFrames);
        direction = searchDef(search, 3);
        
        % search current chuck
        [numFound, tmpFrame, tmpTime] = doSearch;
        
        % if screen flashes were found, append the time and frame numbers
        % to the end of the storage arrays
        if numFound > 0
            totFound = totFound + numFound;
            sfFrame(end + 1:end + length(tmpFrame)) = tmpFrame; 
            sfTime(end + 1:end + length(tmpTime)) = tmpTime;
        end
        
        % terminate search if maxNum of screenflashes has been reached
        if totFound >= maxNum
            break
        end
        
    end
    
    % if any screenflashses have been found, save these to a file
    found = totFound >= 0;
    if found
        [vPath, vFile, vExt] = fileparts([videoFile, '.screenflash_v7.mat']);
        sfPath = [vPath, filesep, vFile, vExt];
        save(sfPath, 'found', 'numFound', 'sfFrame', 'sfTime');   
    end
    
    % clean up
    Screen('CloseMovie', movPtr);
    Screen('Close', winPtr);
    
    % report results
    fprintf('<strong>%s: Finished in %.0f seconds.</strong>\n', videoFile, toc);
    
    function [numFound, foundFrame, foundTime] = doSearch
        
        numFound = 0; foundFrame = []; foundTime = [];
               
        % define range of frames to be searched
        frmRange = f1:sfDurF * direction:f1 + (extent * direction);
        
        fr = 1;
        while fr < length(frmRange)
            
            if mod(fr, 30) == 0
                fprintf('\tSub-search frame %d of %d...\n', frmRange(fr),...
                    max(frmRange));
            end
            
            % get the current frame number
            frNum = frmRange(fr);
            
            % get a frame
            frame = readFrame(frNum, winPtr, movPtr, rect);

            % check that the range in intensity values is small
            % if it is small on all three colour channels, do a
            % fine-grained search to see if it is a screen flash
            if checkIntensityRange(frame, critRng)
                
                % estimate the time point within the flash based on
                % luminance
                lum = mean(mean(mean(frame)));
                posF = find(sfInt >= lum, 1, 'first');
                pos = posF / sfDurF;
                
                % add some padding to account for a poor estimate of the
                % midpoint
                padF = 5;
                
                % look for start of screenflash
                f1 = frNum - posF - padF;
                if f1 < 1, f1 = 1; end
                f2 = f1 + (padF * 2);
                if f2 >= totFrames, f2 = totFrames - 1; end
                
                foundStart = false;
                abort = check10Ahead;
                
                if ~abort
                    
                    fprintf(...
                        '\tPossible intensity profile, searching endpoints...\n');
                
                    % read in all frames
                    frames = readFrames(f1, f2, winPtr, movPtr, rect);

                    % check intensity range 
                    [intval, intrng] = checkIntensityRange(frames, critRng);

                    if any(intval)

                        % find contigous block of frames at end of range
                        posStart = find(~intval, 1, 'last');
                        if isempty(posStart), posStart = 0; end
                        posStart = posStart + 1;

                        % check that this is not the last frame in the block
                        % (in which case we do not have a screenflash)
                        if posStart < length(intval) &&...
                                mean(mean(mean(frames(:, :, :, posStart)))) < critRng
                            foundStart = true;
                            posStart = f1 + posStart;
                        else
                            foundStart = false;
                            posStart = [];
                        end

                    end
                    
                end
                
                if foundStart
                
                    % look for end of screenflash
                    f1 = frNum + ((1 - pos) * sfDurF) - padF;
                    if f1 < 1, f1 = 1; end
                    if f1 >= totFrames, f1 = totFrames - 1; end
                    f2 = f1 + (padF * 2);
                    if f2 < 1, f2 = 1; end
                    if f2 >= totFrames, f2 = totFrames - 1; end
                    
                    foundEnd = false;

                    % read in all frames
                    frames = readFrames(f1, f2, winPtr, movPtr, rect);

                    % check intensity range 
                    [intval, intrng] = checkIntensityRange(frames, critRng);

                    if any(intval)

                        % find contigous block of frames at end of range
                        posEnd = find(~intval, 1, 'first');
                        if isempty(posEnd), posEnd = length(intval); end

                        % check that this is not the last frame in the block
                        % (in which case we do not have a screenflash)
                        if posEnd ~= 1 &&...
                                mean(mean(mean(frames(:, :, :, posEnd)))) > (255 - critRng)
                            foundEnd = true;
                            posEnd = f1 + posEnd + 1;
                        else
                            foundEnd = false;
                            posEnd = [];
                        end

                    end  

                else foundEnd = false; 
                
                end
                
                % if we have found both endpoints, we now check the
                % luminance profile to see if it matches that of a screen
                % flash
                foundEndPoints = foundStart && foundEnd;
                if foundEndPoints
                    
                    fprintf('\tEndpoints found.\n')
                    
                    f1 = posStart; 
                    f2 = posEnd; 
                    frames = readFrames(f1, f2, winPtr, movPtr, rect, 3);

                    % check intensity profile against model
                    [valProf, int, lastF] = checkIntensityProfile(frames, sfInt);
                    
                else
                                       
                    valProf = false;
                    
                end
                
                if valProf
                    
                    fprintf('\tSearching for exact time...\n')
                    
                    % if the profile matched, now we just need to find the last
                    % frame, where white goes to black
                    f1 = f1 + lastF;
                    f2 = f1 + (5 * fps);
                    if f2 >= totFrames, f2 = totFrames - 1; end
                    foundBlack = false;
                    frExact = f1;
                    EOF = false;
                    while frExact < f2 && ~foundBlack && ~EOF
                        
                        [frame, EOF] = readFrame(frExact, winPtr, movPtr, rect);
                        foundBlack = all(all(all(frame < critRng))) ;
                        frExact = frExact + 1;
                        
                    end
                    
                else
                    
                    foundBlack = false;
                    
                end
                    
                if foundBlack
                    fprintf('\tFOUND!\n');
%                     numFound = numFound + 1;
                    foundFrame(end + 1) = frExact;
                    foundTime(end + 1) = foundFrame(end) / fps;
                    numFound = length(foundFrame);
                    if direction == 1
                        fr = find(frExact + (3 * sfDurF) >= frmRange, 1, 'last');
                    else
                        fr = find(frExact - (3 * sfDurF) >= frmRange, 1, 'first');
                    end
                    if fr < 1, fr = 1; end
                end
                
            end
            
            fr = fr + 1;
            
        end
        
    end

    function abort = check10Ahead
        
        % compare the first frame with ten frames ahead and
        % ensure that luminance has changed at least a little -
        % otherwise it is not a screen flash but a solid block
        % of unchanging colour
        frameF1 = readFrame(f1, winPtr, movPtr, rect);
        intF1 = mean(mean(mean(frameF1)));
        fAhead = f1 + 20;
        if fAhead >= totFrames, fAhead = totFrames - 1; end
        frameFAhead = readFrame(fAhead, winPtr, movPtr, rect);
        intFAhead = mean(mean(mean(frameFAhead)));
        if ~checkIntensityRange(frameFAhead, critRng) ||...
                abs(intF1 - intFAhead) < critRng;
            abort = true;
            foundEnd = false;
        else 
            abort = false;
        end
                    
    end

end

function [frame, EOF] = readFrame(idx, winPtr, movPtr, rect)
  
    fprintf('Reading frame %d\n', idx)

    global fps
    
    rw = rect(3) - rect(1);
    rh = rect(4) - rect(2);
    
    timeIdx = idx / fps;
    
    Screen('SetMovieTimeIndex', movPtr, timeIdx);
    texPtr = Screen('GetMovieImage', winPtr, movPtr);
    if texPtr ~= -1
        EOF = false;
        frame = Screen('GetImage', texPtr, rect);    
    else
        EOF = true;
        frame = randi(255, [rh, rw, 3]);
        texPtr = Screen('MakeTexture', winPtr, frame);
    end

    Screen('DrawTexture', winPtr, texPtr);
    Screen('FrameRect', winPtr, [255, 255, 255], rect, 2);
    str = sprintf('Frame: %d', idx);
    DrawFormattedText(winPtr, str, 0, 15, [255, 255, 255]);
    Screen('Flip', winPtr, [], [], 1);    
    Screen('Close', texPtr);

end

function frames = readFrames(f1, f2, winPtr, movPtr, rect, step)

    if ~exist('rate', 'var'), step = 1; end

    rw = rect(3) - rect(1);
    rh = rect(4) - rect(2);
    
    frames = uint8(zeros(rh, rw, 3, f2 - f1));
    for fr = f1:step:f2
        frames(:, :, :, fr - f1 + 1) = readFrame(fr, winPtr, movPtr, rect);
    end
    
end

function [val, intrng] = checkIntensityRange(frames, crit)

    intrng = shiftdim(max(max(frames(:, :, :, :))), 2) -...
        shiftdim(min(min(frames(:, :, :, :))), 2);
    val = all(intrng <= crit, 1);

end
        
function [val, int_full, lastF] = checkIntensityProfile(frames, model)

    % get profile
    int_full = shiftdim(mean(mean(mean(frames))), 3)';
    
    % look for start and end of line
    vel = [0, int_full(2:end) - int_full(1:end - 1)];
    p1 = find(vel > 1, 1, 'first');
    p2 = find(vel > 1, 1, 'last');
    
    % chop 
    int = int_full(p1:p2);
    
    % check correlation
    if length(int) > 1
        cf = corrcoef(int, linspace(0, 255, length(int)));
        val = cf(1, 2) > .985;
        lastF = p2;
    else
        val = false;
        lastF = [];
    end

end