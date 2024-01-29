function t = etTimeVectorFromBuffer(timeBuffer, format)

    % zero timestamps in buffer
    t = timeBuffer(:, 1) - timeBuffer(1, 1);
    
    if exist('format', 'var')
        switch format
            case 'us'
                t = double(t);
            case 'ms'
                t = double(t) / 1e3;
            otherwise % assume secs
                t = double(t) / 1e6;
        end
    else
        % if no format supplied, assume secs
        t = double(t) / 1e6;
    end
                
end