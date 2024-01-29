function result = etOverlayGazeVideo(data, video, sf)

    quitOut = false;

    gazeRad = 10;
    gazeDur = .4;
    evDur = 8;
    colL = [50, 50, 200];
    colR = [50, 200, 50];
    colA = [200, 50, 50];
        
    if ~exist('data', 'var') || isempty(data)
        error('Must supply data argument.')
    end
    
    if ~exist('video', 'var') || isempty(video)
        error('Must supply video argument.')
    end
    
    if ~exist('sf', 'var') || isempty(sf)
        sf = [video, '.screenflash_v7.mat'];
        if ~exist(sf, 'file')
            error('Must supply a valid sf file.')
        end
    end
    
    % make output filename
    [pth, file, ext] = fileparts(video);
    outFile = [pth, filesep, file, '.gaze2', ext];
%     outFile = strrep(outFile, ' ', '\ ');
    
    % check data and sf
    dc = checkDataIn(data);
    sf = checkScreenflashIn(sf);
    evTimes = cell2mat(dc.Data{1}.EventBuffer(:, 2));
    
    % attempt to match sf to data
    [match, sfEvents] = etScreenflashMatch(sf, dc, .5, video);
    if ~any(match)
        result = 'Could not match screenflash data to ET data.';
        return
    else
        sf.sfTime = sf.sfTime(match);
        sf.sfFrame = sf.sfFrame(match);
        sf.sfTime = sort(sf.sfTime);
        sf.sfFrame = sort(sf.sfFrame);
    end
    
    % open window
    
    % disable timing tests and PTB warnings 
    Screen('Preference', 'SkipSyncTests', 2);
    Screen('Preference', 'Verbosity', 2);

    % set HQ text rendering
    Screen('Preference', 'TextRenderer', 1);
    Screen('Preference', 'TextAntiAliasing', 1);

    % open PTB window
    info = mmfileinfo(video);
    scr = [0, 0, info.Video.Width, info.Video.Height];
    monitor = max(Screen('Screens'));
%     scr = scr ./ 3;
    res = scr;
%     res = [0, 0, 960, 540];
    winPtr = Screen('OpenWindow', monitor, [0, 0, 0], res, [], [], [], 8,...
        [], kPsychGUIWindow, scr);
%     winPtr = Screen('OpenOffscreenWindow', -1, [0, 0, 0], res);

    % turn on alpha blending 
    Screen('BlendFunction', winPtr, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    % set text style
    Screen('TextSize', winPtr, 14);
    Screen('TextFont', winPtr, 'Menlo');
    Screen('TextStyle', winPtr, 1);
    
    % open movie
    [movPtr, movDur, fps] = Screen('OpenMovie', winPtr, video);
    movTime = 0;
%     movTime = 100;
%     movDur = 110;
    % open output movie
% %     renderPtr = Screen('CreateMovie', winPtr, outFile, [], [], fps,...
% %         ':CodecType=ffenc_mpeg4');
    renderPtr = Screen('CreateMovie', winPtr, sprintf('"%s"', outFile), scr(3), scr(4), fps, ':CodecType=x264enc Videobitrate=6000 Profile=1');

%     renderPtr = Screen('CreateMovie', winPtr, sprintf('"%s"', outFile), scr(3), scr(4), fps);

%     vw = VideoWriter(outFile, 'MPEG-4');
%     vw.FrameRate = fps;
%     vw.Quality = 95;
%     open(vw);
    
    % start playing
    sfTime = nan;
    gazeDurUs = int64((gazeDur / 2) * 1e6);
    evDurUs = int64(evDur * 1e6);
    evFilt = [];

    while movTime <= movDur && ~quitOut
        
        % check keyboard
        [keyIsDown, ~, keyCode] = KbCheck;
        if keyIsDown
            quitOut = keyCode(KbName('Escape'));
        end
    
        % get frame
        Screen('SetMovieTimeIndex', movPtr, movTime);
        texPtr = Screen('GetMovieImage', winPtr, movPtr);
        Screen('DrawTexture', winPtr, texPtr);
        Screen('Close', texPtr);
        
        % update times
        sfTime = movTime - sf.sfTime(1);
        gazeTime = sfEvents{1, 2} + int64(sfTime * 1000000);
        gazeRng = [gazeTime - gazeDurUs,  gazeTime + gazeDurUs];
        evRng = [gazeTime - evDurUs,  gazeTime];

        % get eye tracking data
        [mb, tb, ~] = etGetGazeByTime(dc.Data{1}.MainBuffer,...
            dc.Data{1}.TimeBuffer, dc.Data{1}.EventBuffer,...
            gazeRng(1), gazeRng(2));
        evFilt_prev = evFilt;
        evFilt = gazeTime - evTimes > 0 & gazeTime - evTimes < evDurUs;
        eb = dc.Data{1}.EventBuffer(evFilt, :);
%         [~, ~, eb] = etGetGazeByTime(dc.Data{1}.MainBuffer,...
%             dc.Data{1}.TimeBuffer, dc.Data{1}.EventBuffer,...
%             evRng(1), evRng(2));        
        
        mb = mb{1};
        tb = tb{1};
%         eb = eb{1};
        mb = etFilterGazeOnscreen(mb);
        hasGaze = any(any(~isnan(mb(:, [7:8,20:21]))));
        hasEvents = ~isempty(eb);
        
        % format gaze data for drawing
        if hasGaze
            
            gazeNs = size(mb, 1);
            
            % convert to x, y, average; translate to pixels
            gXL             =   mb(:,7, :) * scr(3);
            gYL             =   mb(:,8, :) * scr(4);
            gXR             =   mb(:,20, :) * scr(3);
            gYR             =   mb(:,21, :) * scr(4);
            gXA             =   (gXL + gXR) / 2;
            gYA             =   (gYL + gYR) / 2;
            
            % format into rect
            prevEyeRect=[...
                [gXL'-gazeRad; gYL'-gazeRad; gXL'+gazeRad; gYL'+gazeRad],...
                [gXR'-gazeRad; gYR'-gazeRad; gXR'+gazeRad; gYR'+gazeRad],...
                [gXA'-gazeRad; gYA'-gazeRad; gXA'+gazeRad; gYA'+gazeRad]];

            % organise alpha channel to fade histortic gaze samples
            alphaInc = 255 / (gazeNs - 1);

            % organise colour information, taking alpha into account
            prevEyeCol=[...
                [[repmat(colL, gazeNs, 1)], [0:alphaInc:255]'];...
                [[repmat(colR, gazeNs, 1)], [0:alphaInc:255]'];...
                [[repmat(colA, gazeNs, 1)], [0:alphaInc:255]']];            
        
            % draw gaze
            Screen('FillRect', winPtr, prevEyeCol', prevEyeRect);
            
        end
        
%         if hasEvents
%             if ~isequal(evFilt, evFilt_prev)
%                 cellEvents = etListEvents(eb);
%                 if ~isempty(cellEvents)
%                     cellEvents = [cellEvents(1, :); flipud(cellEvents(2:end, :))];
%                     events = formatCellAsStringPTB(cellEvents(:, 4));
%                 else
%                     events = '';
%                 end   
%             end
%             DrawFormattedText(winPtr, events, 0 + 1, 30 + 1, [0, 0, 0]);
%             DrawFormattedText(winPtr, events, 0, 30, [255, 255, 20]);
%         end
       
        % flip
        Screen('Flip', winPtr, [], [], 2);

        % write frame
        Screen('AddFrameToMovie', winPtr, [], [], renderPtr);
%         frame = Screen('GetImage', winPtr);
%         writeVideo(vw, frame);
        
        % increment movie time by one frame
        movTime = movTime + (1 / fps);
        
    end
        
    Screen('FinalizeMovie', renderPtr);
%     close(vw);
    Screen('CloseMovie', movPtr);
    Screen('Close', winPtr);

    result = 'success';
    
end