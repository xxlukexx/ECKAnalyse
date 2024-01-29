function [xDeg, yDeg] = deg2norm(x, y, screenW, screenH, dist)

    screenWRad  = 2 * atan(screenW / 2 ./ dist);
    screenHRad  = 2 * atan(screenH / 2 ./ dist);
    screenWDeg  = screenWRad * (180/pi);
    screenHDeg  = screenHRad * (180/pi);
    xDeg        = x ./ screenWDeg;
    yDeg        = y ./ screenHDeg;

end