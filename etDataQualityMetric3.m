function [dq, summary] = etDataQualityMetric3(mb, tb, eb)

    if isempty(mb) || isempty(tb)
        dq = [];
        summary = [];
        return
    end
    
    %% prep
    
    % remove breaks and pauses
    [mb, tb] = etFilterOutEvents(mb, tb, eb, 'BREAKIMG_ONSET',...
        'BREAKIMG_OFFSET');
    [mb, tb] = etFilterOutEvents(mb, tb, eb, 'PAUSE_ONSET',...
        'PAUSE_OFFSET');
    
    mb_avg = etAverageEyeBuffer(etFilterGazeOnscreen(mb));    
    gx = mb_avg(:, 7);
    gy = mb_avg(:, 8);
    
    %% time
    firstEvent          =   tb(1,1);
    lastEvent           =   tb(end, 1);
    
    dq.DurationS = etDetermineDuration(tb);
    secsInDay = 60 * 60 * 24;
    durDays = dq.DurationS / secsInDay;
    dq.DurationFormatMin = datestr(durDays, 'MM');
    dq.DurationFormatSec = datestr(durDays, 'SS');
    
    %% time vector
    tVec = double(tb(:, 1)) / 1000000;
    dq.TimeVector = round(tVec - tVec(1));
    
    %% sample frequency
    sf = etSamplingFrequencyTime(tb);
    sf(sf == inf) = [];
    meanSR = nanmean(sf);
    sdSR = nanstd(sf);
    crit = sdSR * 2;
    sf(sf > (meanSR + crit) | sf < (meanSR - crit)) = nan;
    dq.SampleFrequencyTimeSeries = sf;
    dq.SampleFrequencyMean = meanSR;

    %% eye validity
    eyeValL = mb_avg(:, 13);
    eyeValR = mb_avg(:, 26);

    % fill array with ones = one eye
    eyeVal = ones(size(eyeValL, 1), 1);

    % both eyes
    eyeVal(eyeValL == 0 & eyeValR == 0) = 2;

    % no eyes
    eyeVal(eyeValL == 4 & eyeValR == 4) = 0;

    % tabulate
    table = tabulate(eyeVal);
    dq.EyeValidity = table;
    dq.EyeValidityLabels = {'No eyes', 'One eye', 'Both eyes'};
    
    % easier summary
    dq.missing = prop(eyeValL == 4 & eyeValR == 4);
    dq.bino = prop(eyeValL ~= 4 & eyeValR ~= 4);
    dq.mono = prop(xor(eyeValL == 4, eyeValR == 4));
    

    %% distance from screen
    dis = mb(eyeVal == 2, [3, 16]);
    dq.DistanceFromScreenMean = nanmean(dis(:));
    dq.DistanceFromScreenSD = nanstd(dis(:));
    
    %% distance from centre of head box
    hbPosX = mb(eyeVal == 2, 4);
    hbPosY = mb(eyeVal == 2, 5);
    hbPosZ = mb(eyeVal == 2, 6);
    hbDisX = abs(hbPosX - .5);
    hbDisY = abs(hbPosY - .5);
    hbDisZ = abs(hbPosZ - .5);
    hbDis = sqrt((hbDisX .^ 2) + (hbDisY .^ 2) + (hbDisZ .^ 2));
    dq.DistanceFromHeadBoxCentreMean = mean(hbDis);
    dq.DistanceFromHeadBoxCentreSD = std(hbDis);
    
    %% gaze on screen (when both eyes detected)
    gazeScL = mb(eyeVal == 2, 7) >= 0 & mb(eyeVal == 2, 7) <=1 &...
                mb(eyeVal == 2, 8) >=0 & mb(eyeVal == 2, 8) <= 1;
    gazeScR = mb(eyeVal == 2, 20) >= 0 & mb(eyeVal == 2, 20) <=1 &...
                mb(eyeVal == 2, 21) >=0 & mb(eyeVal == 2, 21) <= 1;
    gazeSc = gazeScL & gazeScR;
    table = tabulate(gazeSc);
    dq.GazeOnScreen = table;   
    
    %% flicker (predictiveness)
    if size(mb, 1) > 2
        eyePresent = eyeVal==1 | eyeVal==2;
        
        s1 = eyePresent(2:end);
        s2 = eyePresent(1:end - 1);
        
        bothVal = s1 & s2;
%         bothMiss = ~s1 & ~s2;
        flicker = (s1 & ~s2) | (~s1 & s2);
         
        eyePresentPairs = [eyePresent(2:end), eyePresent(1:end-1)];
        dq.FlickerPairs = eyePresentPairs(:,1) | eyePresentPairs(:,2);
        dq.FlickerRatio = sum(dq.FlickerPairs) /...
            size(dq.FlickerPairs, 1);
        dq.FlickerRatioValid = sum(flicker) / sum(bothVal | flicker);
    else
        dq.FlickerPairs = nan;
        dq.FlickerRatio = nan;
    end
    
    %% RMS
    if any(eyeVal)
        [dq.RMSx, dq.RMSy] = computeRMS(...
            gx(eyeVal==2), gy(eyeVal == 2), 1);
    else
        dq.RMSx = nan;
        dq.RMSy = nan;
    end
    
    %% GAP HISTOGRAM
    [dq.GapHist.HistCount, dq.GapHist.HistTime,...
        dq.GapHist.BinsCount, dq.GapHist.BinsTime] =...
        ECKLossHistogram(mb, tb, eb, false);
    
    %% lost eyes by time
    [dq.EyeValidityTimeSeries.Data,...
        dq.EyeValidityTimeSeries.Time] =...
        etEyeValiditySeries(mb, tb);
    
    %% basic fixation ID
    vel = [0; etCalculateVelocity(mb, tb)];
    vel_m = mean(vel(~isnan(vel)));
    vel_sd = std(vel(~isnan(vel)));
    clas = false(size(gx));
    clas(vel < (vel_m + vel_sd)) = 1;
    gx_fix = gx;
    gy_fix = gy;
    gx_fix(~clas) = nan;
    gy_fix(~clas) = nan;
    dq.FixationRMS = computeRMS(gx_fix(~isnan(gx_fix)),...
        gy_fix(~isnan(gy_fix)), 1);
    
    %% summary table
    summary.Header = {...
        'Duration (tot. s)',...
        'Duration (m)',...
        'Duration (s)',...
        'No eyes (samp)',...
        'No eyes (prop)',...
        'One eye (samp)',...
        'One eye (prop)',...
        'Two eyes (samp)',...
        'Two eyes (samp)',...
        'FlickerRatio',...
        'RMSx',...
        'RMSy',...
        'Gaze on screen (samp)',...
        'Gaze on screen (prop)'};
    
    summary.Data = {...
        dq.DurationS,...
        str2double(dq.DurationFormatMin),...
        str2double(dq.DurationFormatSec),...
        size(eyeVal(eyeVal == 0), 1),...
        size(eyeVal(eyeVal == 0), 1) / size(eyeVal, 1),...
        size(eyeVal(eyeVal == 1), 1),...
        size(eyeVal(eyeVal == 1), 1) / size(eyeVal, 1),...        
        size(eyeVal(eyeVal == 2), 1),...
        size(eyeVal(eyeVal == 2), 1) / size(eyeVal, 1),... 
        dq.FlickerRatio,...
        dq.RMSx,...
        dq.RMSy,...
        size(gazeSc(gazeSc), 1),...
        size(gazeSc(gazeSc), 1) / size(gazeSc, 1),...
        };
        
    
end