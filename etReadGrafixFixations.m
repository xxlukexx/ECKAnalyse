function [fixBuffer, hdr] = etReadGrafixFixations(fixFile, screenWidth,...
    screenHeight, mainBuffer)
    
    % check graFIX filename
    if ~exist('fixFile', 'var') || isempty(fixFile) ||...
            ~exist(fixFile, 'file')
        error('Invalid or missing graFIX fixation filename.')
    end
    
    % need to know screen width and height, in mm. If
    % this has not been supplied, then default to the size of a T120 eye
    % tracker screen (17" diagonal), which is also the size of the "virtual
    % screen" used on larger screens in EU-AIMS. These dimensions are in
    % millimetres. 
    if ~exist('screenWidth', 'var') || isempty(screenWidth)
        screenWidth = 345;
    end
    
    if ~exist('screenHeight', 'var') || isempty(screenHeight)
        screenHeight = 259;
    end
    
    % read data
    raw = readtable(fixFile);
    
    % check that the number of samples in the mainbuffer matches those in
    % the fixation file
    if size(mainBuffer, 1) ~= size(raw, 1)
        error('Number of rows in main buffer (%d) does not match number of rows in fixation file (%d).',...
            size(mainBuffer, 1), size(raw, 1));
    end
    
    % to convert velocities to degrees of visual angle. first calculate median
    % distance from screen. to do this we need to take only samples where
    % both eyes were detected (since when Tobii only has one eye, it often
    % mistakes left for right, introducing noise into the estimates). 
    gazeCoords = mainBuffer(:, 13) == 0 & mainBuffer(:, 26) == 0;
    dis = mean([mainBuffer(gazeCoords, 3), mainBuffer(gazeCoords, 16)], 2);
    avgDis = nanmedian(dis);
    
    % calculate screen dimensions in degress, and degress per mm
    screenWidthRad = 2 * atan(screenWidth / 2 / avgDis);
    screenHeightRad = 2 * atan(screenHeight / 2 / avgDis);
    screenWidthDeg = screenWidthRad * (180 / pi);
    screenHeightDeg = screenHeightRad * (180 / pi);
    degPerMM = screenWidthDeg / screenWidth;
    
    % convert smoothed values from screen coords (pixels, cm etc.) to
    % normalised coords
    smoothVal = raw.smooth_x ~= -1 & raw.smooth_y ~= -1;
    raw.smooth_x(smoothVal) = raw.smooth_x(smoothVal) / screenWidth;
    raw.smooth_y(smoothVal) = raw.smooth_y(smoothVal) / screenHeight;
    
    % rescale smoothed velocities to degrees
    raw.smooth_velocity(smoothVal) = raw.smooth_velocity(smoothVal) *...
        degPerMM;
    
    % rescale saccade distance from mm to normalised coords
    raw.saccade_distance = raw.saccade_distance / screenWidth;
    
    % rescale saccade velocities to degrees
    sac = raw.saccade_velocity_average ~= 0;
%     raw.saccade_velocity_average(sac) = raw.saccade_velocity_average(sac) *...
%         degPerMM;
%     raw.saccade_velocity_peak(sac) = raw.saccade_velocity_peak(sac) *...
%         degPerMM;    
    
    % set flag for each sample to indicate:
    % 0 - no OM event (or missing data)
    % 1 - fixation
    % 2 - saccade
    % 3 - smooth pursuit
    flag = zeros(size(raw, 1), 1);
    flag(raw.fixation_number ~= 0) = 1;
    flag(raw.sacade_number ~= 0) = 2;
    flag(raw.fixation_smooth_pursuit ~= 0) = 3;    
    
    % index missing samples. Two types, totally missing - so no raw or
    % fixation data, and raw missing, but with fixation data. 
    gazeCoords = table2array(raw(:, 3:11));
    valNoSampNoFix = all(gazeCoords == -1, 2);
    valNoSamp = all(gazeCoords(:, 1:6) == -1, 2);
    valid = all(gazeCoords ~= -1, 2);
    
    % delete unused variables
    raw.sample = [];
    raw.timestamp = [];
    raw.pupil_left = [];
    raw.pupil_right = [];
    raw.fixation_smooth_pursuit = [];
    
    % make fixbuffer output variable
    fixBuffer = table2array(raw);
    hdr = raw.Properties.VariableNames;
    
 end