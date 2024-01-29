function etHeadPos_plot(varargin)

    % process input args - either [mb, (tb)] or [x, y, z, (tb)]
    if nargin == 1 || nargin == 2       % mb, (tb)
        mb = varargin{1};
        if nargin == 2
            tb = varargin{2};
        end
        % extract head pos
        [lx, ly, lz, rx, ry, rz] = etHeadPos_getCoords(mb);
        % determine whether head pos l/r already averaged
        eyesAvged =...
            isequaln(lx, rx) && isequaln(ly, ry) && isequaln(lz, rz);
    elseif nargin > 2
        lx = varargin{1};
        ly = varargin{2};
        lz = varargin{3};
        eyesAvged = true;   % assume eyes were averaged if x, y, z is passed
        if nargin == 4
            tb = varargin{4};
        end
    end

    % make time or sample vector, depending on whether a timebuffer was
    % passed
    tbPresent = exist('tb', 'var') && ~isempty(tb);
    if ~tbPresent
        t = 1:length(lx);
        xlab = 'Samples';
    else
        t = etTimeBuffer2Secs(tb);
        xlab = 'Seconds';
    end

    figure(...
        'name',     'Head Position',...
        'units',    'normalized',...
        'position', [0.25, 0.25, .75, 0.75]);
%         'toolbar',  'none',...
%         'menubar',  'none',...
    % x
    subplot(3, 1, 1)
    scatter(t, lx)
    if ~eyesAvged
        hold on
        scatter(t, rx)
    end
    xlabel(xlab);
    title('X')
    
    % y
    subplot(3, 1, 2)
    scatter(t, ly)
    if ~eyesAvged
        hold on
        scatter(t, ry)
    end
    xlabel(xlab);
    title('Y')
    
    % z
    subplot(3, 1, 3)
    scatter(t, lz)
    if ~eyesAvged
        hold on
        scatter(t, rz)
        legend('Left eye', 'Right eye')
    end
    xlabel(xlab);
    title('Z')
    
end