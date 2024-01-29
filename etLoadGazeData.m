function [metaData] = etLoadGazeData(metaData, loadGazeData)

    fprintf('Loading gaze data: ');
    
    for curEntry = 1:size(metaData, 1)

        % paths
        curLog          =   metaData{curEntry, 7};
        curPath         =   metaData{curEntry, 4};
        curP            =   metaData{curEntry, 1};
        
        mainFound       =   findFilename('mainBuffer', [curPath, filesep, 'gaze']);
        timeFound       =   findFilename('timeBuffer', [curPath, filesep, 'gaze']);
        eventFound      =   findFilename('eventBuffer', [curPath, filesep, 'gaze']);

        if ~isempty(mainFound), curGazePath = mainFound(1, :); end
        if ~isempty(timeFound), curTimePath = timeFound(1, :); end
        if ~isempty(eventFound), curEventPath = eventFound(1, :); end
%         
%         curGazePath     =   [curPath, '/gaze', '/mainBuffer_', curP, '_.mat'];
%         if ~exist(curGazePath, 'file')
%             curGazePath = [curPath, '/gaze', '/mainBuffer.mat'];
%         end
%         
%         curTimePath     =   [curPath, '/gaze', '/timeBuffer_', curP, '_.mat'];
%         if ~exist(curTimePath, 'file')
%             curTimePath = [curPath, '/gaze', '/timeBuffer.mat'];
%         end
%         
%         curEventPath    =   [curPath, '/gaze', '/eventBuffer_', curP, '_.mat'];
%         if ~exist(curEventPath, 'file')
%             curEventPath = [curPath, '/gaze', '/eventBuffer.mat'];
%         end
        
%         if ~(exist(curGazePath, 'file') && exist(curTimePath, 'file') &&...
%                 exist(curEventPath, 'file'))
%             
%             % clear the weird 005 ASCII code that Matlab fucking puts into the
%             % strings above for no apparent reason other than being generally a
%             % cunt
%             curGazePath = strrep(curGazePath, char(005), '');
%             curTimePath = strrep(curTimePath, char(005), '');
%             curEventPath = strrep(curEventPath, char(005), '');
%             
%         end

        % load session data
        if exist('curGazePath', 'var') &&...
                exist('curTimePath', 'var') &&...
                exist('curEventPath', 'var')
            
            try
                load(curGazePath);
                load(curTimePath);
                load(curEventPath);

                % store data
                metaData{curEntry, 8} = mainBuffer;
                metaData{curEntry, 9} = timeBuffer;
                metaData{curEntry, 10} = eventBuffer;
            catch ERR
            end
            
            fprintf('.');
            
        end
        
    end
    
    fprintf('\n');

end