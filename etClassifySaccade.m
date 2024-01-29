function isSac = etClassifySaccade(mainBuffer, timeBuffer)
    
    % plot details
    msz = 5;
    
    % get gaze
    mb = etPreprocess(mainBuffer, 'removemissing', true);
    [lx, ly, rx, ry] = etReturnGaze(mb, 'analyticssdk',...
        'lx', 'ly', 'rx', 'ry');
    % get time
    t = etTimeBuffer2Secs(timeBuffer);
    % distance
    ldis = sqrt((diff(lx) .^ 2) + (diff(ly) .^ 2));
    rdis = sqrt((diff(rx) .^ 2) + (diff(ry) .^ 2));
    % distance diff
    disdiff = nanzscore(rdis - ldis);
    % diff outliers
    useRight = [false; disdiff < 1];
    % clean/avg l ,r
    x = lx;
    y = ly;
    x(useRight) = rx(useRight);
    y(useRight) = ry(useRight);
    % distance
    dis = sqrt((diff(x) .^ 2) + (diff(y) .^ 2));
    tdelta = diff(t);
    dis = dis ./ tdelta;
    % threshold saccades
    isSac = [false; dis > 50];
    
    x(isSac) = nan;
    y(isSac) = nan;
    
    % lowess
%     lsx = smooth(lx, 'rloess');
%     lsy = smooth(ly, 'rloess');
%     rsx = smooth(rx, 'rloess');
%     rsy = smooth(ry, 'rloess');
    
    %%
%     figure
%     
%     subplot(5, 1, 1)
%     scatter(t, lx, msz);
%     hold on
%     scatter(t, rx, msz);
%     title('x')
% 
%     subplot(5, 1, 2)
%     scatter(t, ly, msz);
%     hold on
%     scatter(t, ry, msz);
%     title('y')
%     
%     subplot(5, 1, 3)
%     scatter(t(2:end), ldis, msz);
%     hold on
%     scatter(t(2:end), rdis, msz);
%     title('euclidean distance')
%     yl = get(gca, 'ylim');
%     
%     subplot(5, 1, 4)
%     scatter(t(2:end), dis, msz);
%     
%     subplot(5, 1, 5)
%     scatter(t, x, msz);
%     hold on
%     scatter(t, y, msz);
%     title('x, y')
% 
%     subplot(5, 1, 5)
%     scatter(t, lsy, msz);
%     hold on
%     scatter(t, rsy, msz);
%     title('y')
    %%
    

end