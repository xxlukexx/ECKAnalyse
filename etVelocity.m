function [vel] = etVelocity(gx, gy)

% gx = smooth(gx);
% gy = smooth(gy);

gxD = abs(gx(2:end) - gx(1:end - 1));
gyD = abs(gy(2:end) - gy(1:end - 1));
vel = [0; sqrt((gxD .^ 2) + (gyD .^ 2))];

end