function dis = etHeadPos_Distance(x, y, z)

    % calculate distance between each sample, separately on each axis
    xd = abs(x(2:end) - x(1:end - 1));
    yd = abs(y(2:end) - y(1:end - 1));
    zd = abs(z(2:end) - z(1:end - 1));

    % calculate 3D distance
    delta = sqrt((xd .^ 2) + (yd .^ 2) + (zd .^ 2));

    % total distance
    dis = nansum(delta);
         
end