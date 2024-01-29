function [rmsx, rmsy, rmsz] = etHeadPos_rms(varargin)

    % if mainbuffer was supplied, get x, y, z
    if nargin == 1
        [x, y, z] = etHeadPos_getCoords(varargin{1});
    elseif nargin == 3
        x = varargin{1};
        y = varargin{2};
        z = varargin{3};
    else
        error('Input must be either mainbuffer or [x, y, z].')
    end
    
    % calculate RMS
    rmsx = sqrt(nansum(diff(x) .^ 2)) / (max(x) - min(x));
    rmsy = sqrt(nansum(diff(y) .^ 2)) / (max(y) - min(y));
    rmsz = sqrt(nansum(diff(z) .^ 2)) / (max(z) - min(z));
    
end
