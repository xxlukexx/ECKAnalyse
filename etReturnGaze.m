function varargout = etReturnGaze(mb, format, varargin)

    if nargout ~= nargin - 2
        error('Num arguments in doesn''t match number of arguments out.')
    end
        
    switch format
        case 'analyticssdk'
            s.lx = mb(:, 7);
            s.ly = mb(:, 8);
            s.lval = mb(:, 13);
            s.ldis = mb(:, 3);
            s.rx = mb(:, 20);
            s.ry = mb(:, 21);
            s.rval = mb(:, 26);
            s.rdis = mb(:, 16);
            
        otherwise
            error('Not supported.')

    end
    
    exp = cellfun(@(x) sprintf('%s = s.%s;', x, x), varargin, 'uniform', false);
    cellfun(@eval, exp);
    exp = cellfun(@(i, var) sprintf('varargout{%d} = %s;', i, var),...
        num2cell(1:length(varargin)), varargin, 'uniform', false);
    cellfun(@eval, exp);
    
end
    
    
    
    