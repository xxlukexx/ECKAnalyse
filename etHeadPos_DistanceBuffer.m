function dis = etHeadPos_DistanceBuffer(mb, tb, smoothWindow, plotSmoothing)
    
    maxAbsVel = 500;    % 500 m/s

    if ~exist('smoothWindow', 'var') || isempty(smoothWindow)
        smoothWindow = .1;
    end
    
    if ~exist('plotSmoothing', 'var') || isempty(plotSmoothing)
        plotSmoothing = false;
    end

    % average eyes, remove missing
    mb = etPreprocess(mb, 'removemissing', true, 'binocularonly', true,...
        'averageeyes', true);
    
    % extract head pos coords
    [x, y, z] = etHeadPos_getCoords(mb);
    
    ni = growidx(rand(size(z)) > .9, 4);
    oz = z;
    z(ni) = nan;
    
    % make time vector
    t = etTimeBuffer2Secs(tb);

    % convert smoothing window from seconds to samples
    sr = etDetermineSampleRate(tb);
    smoothWindowSamp = round(smoothWindow * sr);
    
    % iteratively clean data
    maxIter = 3;
    iter = 1;
    anyNoise = true;
    xi = x;
    yi = y;
    zi = z;
    while iter <= maxIter && anyNoise
        % find noisy samples
        [xol, yol, zol] = findNoise(xi, yi, zi);
        anyNoise = any(xol) | any(yol) | any(zol);
        % interpolate
        if anyNoise
            [xi, yi, zi] = interpolateNoise(x, y, z, xol, yol, zol, t);
        end
        iter = iter + 1;
    end
    
    zi = medfilt1(zi, smoothWindowSamp);
    zi(1) = z(1);

end

function [xol, yol, zol] = findNoise(x, y, z)

    % calculate intersample delta
    xd = delta(x);
    yd = delta(y);
    zd = delta(z);
    
    % find absolute outliers > 350 m/s, mark neighbouring samples
    xol = growidx(abs(xd) > (250 / 1000), 1);
    yol = growidx(abs(yd) > (250 / 1000), 1);
    zol = growidx(abs(zd) > (250 / 1000), 1);
    
    % find statistical outliers
    xd(xol) = nan;
    yd(yol) = nan;
    zd(zol) = nan;
    xol = xol | detectOutliers(xd, 2);
    yol = yol | detectOutliers(yd, 2);
    zol = zol | detectOutliers(zd, 2);
        
    % include NaNs for intepolation
    xol = xol | isnan(x);
    yol = yol | isnan(y);
    zol = zol | isnan(z);

end

function [xi, yi, zi] = interpolateNoise(x, y, z, xol, yol, zol, t)

    if any(xol)
        xi = interp1(t(~xol), x(~xol), t, 'linear');
    else 
        xi = x;
    end
    
    if any(yol)
        yi = interp1(t(~yol), y(~yol), t, 'linear');
    else
        y1 = y;
    end
    
    if any(zol)
        zi = interp1(t(~zol), z(~zol), t, 'pchip');
    else
        zi = z;
    end
    
end
    
    
    
% %     xd = smooth(xd, smoothWindowSamp);
% %     yd = smooth(yd, smoothWindowSamp);
% %     zd = smooth(zd, smoothWindowSamp);
% % 
% %     
% %     
% %     
% %     
% %     % find outliers
% %     xol = detectOutliers(xd, 2.5);
% %     yol = detectOutliers(yd, 2.5);
% %     zol = detectOutliers(zd, 2.5);
%     
%     
%     
% subplot(3, 1, 1), hold on, scatter(t(xol), x(xol), [], 'r')    
% subplot(3, 1, 2), hold on, scatter(t(yol), y(yol), [], 'r')    
% subplot(3, 1, 3), hold on, scatter(t(zol), z(zol), [], 'r')    
%     
%     
%     
%     
%     
%     
%     
%     % smooth
%     x = smooth(x, smoothWindowSamp);
%     y = smooth(y, smoothWindowSamp);
%     z = smooth(z, smoothWindowSamp);
%     
% 
%     

%     
%     
%     
%     
%     
%     
%     
%     
%     
%     
%     
%     
% 
%     subplot(3, 1, 1)
%     hold on
%     plot(t, xd, 'r')
%     
%     subplot(3, 1, 2)
%     hold on
%     plot(t, yd, 'r')
%     
%     subplot(3, 1, 3)
%     hold on
%     plot(t, zd, 'r')
% 
% 
% 
% 
% 
% 
% 
%     
% 
%     
%     % get head coords, calculate intersample delta
%     [x, y, z] = etHeadPos_getCoords(mb);
%     x = smooth(x, smoothWindowSamp);
%     y = smooth(y, smoothWindowSamp);
%     z = smooth(z, smoothWindowSamp);
%     xd = [nan; x(2:end) - x(1:end - 1)];
%     yd = [nan; y(2:end) - y(1:end - 1)];
%     zd = [nan; z(2:end) - z(1:end - 1)];
%     
%     % convert intersample delta from mm/sample to m/s
%     xd_ms = (xd * sr) / 1000;
%     yd_ms = (yd * sr) / 1000;
%     zd_ms = (zd * sr) / 1000;
%     
%     % remove delta outliers
%     xd_ms = removeOutliers(xd_ms, 3);
%     yd_ms = removeOutliers(yd_ms, 3);
%     zd_ms = removeOutliers(zd_ms, 3);
%     
%     % remove samples above velocity cutoff
%     cut_vel = 350;                              % 350 metres/sec
%     cut_idx_x = abs(xd_ms) > cut_vel;
%     cut_idx_y = abs(yd_ms) > cut_vel;
%     cut_idx_z = abs(zd_ms) > cut_vel;
%     xd_ms(cut_idx_x) = nan;
%     yd_ms(cut_idx_y) = nan;
%     zd_ms(cut_idx_z) = nan;
%     
%     % euclidean distance
%     vel = sqrt((xd_ms .^ 2) + (yd_ms .^ 2) + (zd_ms .^ 2));
%     
%     
%     
%     if plotSmoothing
%         figure('name', sprintf('Smoothing window: %ds, %d samps',...
%             smoothWindow, smoothWindowSamp))
%         subplot(1, 3, 1:2)
%         plot(x)
%         hold on
%         subplot(1, 3, 3)
%         histogram(x)
%         hold on
%     end
%     
%     % smooth
%     x = medfilt1(x, smoothWindowSamp);
%     y = medfilt1(y, smoothWindowSamp);
%     z = medfilt1(z, smoothWindowSamp);
%     
%     if plotSmoothing, 
%         subplot(1, 3, 1:2)
%         plot(x)
%         legend({'Raw', 'Smooth'})
%         subplot(1, 3, 3)
%         histogram(x)
%         hold on
%     end
%  
% 
%     % calculate 3D distance
%     delta = sqrt((xd .^ 2) + (yd .^ 2) + (zd .^ 2));
% 
%     % total distance
%     dis = nansum(delta);
% 
% end