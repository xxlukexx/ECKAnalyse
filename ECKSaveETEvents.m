function ECKSaveETEvents( filePathEvents, eventBuffer, cmdEcho )
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

if ~exist('cmdEcho', 'var') || isempty(cmdEcho)
    cmdEcho = true;
end

tab = cell2table(eventBuffer);
writetable(tab, filePathEvents);

% % open file
% fid=fopen(filePathEvents, 'W');
% 
% fprintf(fid, 'LocalTime, RemoteTime, Event, EventData\n');
% 
% for curRow=1:size(eventBuffer,1)
% 
%     % write remote and local time
%     fprintf(fid, '%d,%d', eventBuffer{curRow,1}, eventBuffer{curRow,2});
% 
%     curVal=eventBuffer{curRow,3};
% 
%     if iscell(curVal)
%     % write any further vars
%         for curVar=1:size(eventBuffer{curRow,3},2)
% 
%             curVal=eventBuffer{curRow,3}{1,curVar};
% 
%             if isnumeric(curVal)
%                 outVal=num2str(curVal);
%             else
%                 outVal=curVal;
%             end
% 
%             fprintf(fid,',%s',outVal);
% 
%         end
% 
%     elseif isnumeric(curVal)
% 
%         % determine whether float or int
%         if isfloat(curVal)
%             fprintf(fid,',%f',curVal);
%         elseif isinteger(curVal)
%             fprintf(fid,',%d',curVal);
%         else 
%             fclose(fid);
%             error('Unknown numeric data type (not float or int).')
%         end
% 
%     elseif ischar(curVal)
% 
%         fprintf(fid,',%s',curVal);
% 
%     else
%         
%         fclose(fid);
%         error('Unknown data type (not cell, numeric, or char).')
% 
%     end
% 
%     fprintf(fid,'\n');
% 
% end
% 
% fclose(fid);

end

