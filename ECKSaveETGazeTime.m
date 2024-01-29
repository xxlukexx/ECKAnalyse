function [ ] = ECKSaveETGazeTime( filePath, mainBuffer, timeBuffer, cmdEcho )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

if ~exist('cmdEcho', 'var') || isempty(cmdEcho)
    cmdEcho = true;
end

if cmdEcho, fprintf('\tSaving gaze and time buffers...'); end
         
varNames = {...
    'RemoteTime',...
    'TriggerSignal',...
    'Left.3D.UCS.x',...
    'Left.3D.UCS.y',...
    'Left.3D.UCS.z',...
    'Left.3D.REL.x',...
    'Left.3D.REL.y',...
    'Left.3D.REL.z',...
    'Left.x',...
    'Left.y',...
    'Left.3D.x',...
    'Left.3D.y',...
    'Left.3D.z',...
    'Left.Diameter',...
    'Left.Validity',...
    'Right.3D.UCS.x',...
    'Right.3D.UCS.y',...
    'Right.3D.UCS.z',...
    'Right.3D.REL.x',...
    'Right.3D.REL.y',...
    'Right.3D.REL.z',...
    'Right.x',...
    'Right.y',...
    'Right.3D.x',...
    'Right.3D.y',...
    'Right.3D.z',...
    'Right.Diameter',...
    'Right.Validity'};
varNames = fixTableVariableNames(varNames);

data = [double(timeBuffer), mainBuffer];
tab = array2table(data, 'VariableNames', varNames);
writetable(tab, filePath)
% % open file with 64-bit data types
% fid=fopen(filePath, 'W','ieee-le.l64');
% 
% % write headers
% fprintf(fid, [...
%     'RemoteTime, TriggerSignal, Left.3D.UCS.x, Left.3D.UCS.y, Left.3D.UCS.z,',...
%     'Left.3D.REL.x, Left.3D.REL.y, Left.3D.REL.z, Left.x, Left.y,',...
%     'Left.3D.x, Left.3D.y, Left.3D.z, Left.Diameter, Left.Validity,',...
%     'Right.3D.UCS.x, Right.3D.UCS.y, Right.3D.UCS.z,',...
%     'Right.3D.REL.x, Right.3D.REL.y, Right.3D.REL.z, Right.x, Right.y,',...
%     'Right.3D.x, Right.3D.y, Right.3D.z, Right.Diameter, Right.Validity\n']);
% 
% % loop through rows
% for curRow=1:size(mainBuffer,1)
% 
%     % time data
%     fprintf(fid, '%d,%d', timeBuffer(curRow,1), timeBuffer(curRow,2));
% 
%     % gaze data
% %     fprintf(fid, ',%0.15f', mainBuffer(curRow, :));
%     for curCol=1:size(mainBuffer,2)
% 
%         fprintf(fid, ',%0.15f', mainBuffer(curRow, curCol));
% 
%     end
% 
%     % newline
%     fprintf(fid,'\n');
% 
% end
% 
% fclose(fid);

if cmdEcho, fprintf('done.\n'); end

end
