function [varargout] = etListEvents(eventBuffer)

    varargout = {};
    
    if ~exist('eventBuffer', 'var')
        error('Must pass an event buffer to this function.')
    end
    
    if isempty(eventBuffer)
        fprintf('<EMPTY?>\n')
        varargout{1} = '';
        return
    end

    % headers and timestamps
    out = cell(size(eventBuffer, 1) + 1, 4);
    out(1, :) = {'LocalTime', 'RemoteTime', 'ElapsedTime', 'Event(s)'};
    out(2:end, 1:2) = eventBuffer(:, 1:2);
    
    % calculate elapsed time
    timeS = double((cell2mat(eventBuffer(:, 2))) - eventBuffer{1, 2}) / 1000000;
    secsInDay = 60 * 60 * 24;
    timeProp = timeS / secsInDay;
    out(2:end, 3) = cellstr(datestr(timeProp, 'HH:MM:SS.FFF'));
    
    % new formatting
    for e = 1:size(eventBuffer, 1)
        ev = eventBuffer{e, 3};
        if ischar(ev)
            out{e + 1, 4} = ev;
        elseif isnumeric(ev)
            out{e + 1, 4} = num2str(ev);
        elseif iscell(ev)
            out{e + 1, 4} = cell2char(ev);
        end  
    end
    
%     for e = 1:size(eventBuffer, 1)
%         ev = eventBuffer{e, 3};
%         if ischar(ev)
%             out{e + 1, 4} = [' | ',  ev];
%         elseif isnumeric(ev)
%             out{e + 1, 4} = [' | ', num2str(ev)];
%         elseif iscell(ev)
%             ev_text = '';
%             for evd = 1:length(ev)
%                 if ischar(ev{evd})
%                     ev_text = [ev_text, ' | ', ev{evd}];
%                 elseif isnumeric(ev{evd})
%                     ev_text = [ev_text, ' | ', num2str(ev{evd})];
%                 end
%             end
%             out{e + 1, 4} = ev_text;
%         end  
%     end
    
    
    if nargout == 1
        varargout{1} = out;
    else
        disp(out)
    end        
    
end
    