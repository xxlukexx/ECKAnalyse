function [session, segments] = ECKDataSegmentsToStruct(data)

    if ~isa(data, 'ECKData')
        error('Input must be ECKData.')
    end
    
    warning off MATLAB:structOnObject
    
    % convert ECKData to struct
    session = struct(data);
    
    % rename 'timepoint' to 'schedule'
    session.Schedule = session.TimePoint;
    
    % rename 'segments' to 'segmentation'
    session.Segmentation = session.Segments;
    
    % remove irrelevant fields
    session = rmfield(session, {...
        'Segments',...
        'TimePoint',...
        'CacheFolder',...
        'Loaded',...
        'Cached',...
        'Type',...
        'SessionPath',...
        'Paths',...
        'Tracker',...
        'GazeLoaded',...
        'NumSegments',...
        'cached',...
        'cacheFile',...
        'data',...
        'loaded'});
    
    % break apart into segments
    numTasks = length(session.Segmentation);
    segments = cell(1, numTasks);
    for t = 1:numTasks
        
        % get task name, and built name in "xxx_trial" format
        task = session.Segmentation(t).Task;
        jobLabel = session.Segmentation(t).JobLabel;
        if ~contains(task, '_trial')
            taskTrial = [task, '_trial'];
        else
            taskTrial = task;
        end
        segments{t}.Task = task;
        segments{t}.JobLabel = jobLabel;
        
        % copy metadata
        segments{t}.ParticipantID = session.ParticipantID;
        segments{t}.Schedule = session.Schedule;
        segments{t}.Site = session.Site;
        segments{t}.Battery = session.Battery;
        segments{t}.CounterBalance = session.CounterBalance;
%         segments{t}.FamilyID = session.ExtraData.FamilyID;
        segments{t}.FamilyID = 'UNKNOWN';
        segments{t}.SessionGUID = session.GUID;
        
        % copy ET segments
        segments{t}.Segments = session.Segmentation(t).Segment;
            
        % segment log data
        if isfield(session, 'Log') && isfield(session.Log, 'FunName')
            idx = strcmpi(session.Log.FunName, taskTrial);
            if ~isempty(idx)
                segments{t}.Log.FunName = session.Log.FunName(idx);
                segments{t}.Log.Headings = session.Log.Headings(idx);
                segments{t}.Log.Data = session.Log.Data(idx);
                segments{t}.Log.Table = session.Log.Table(idx);
            end
        else
            segments{t}.Log = struct;
        end
        
    end
        
    warning on MATLAB:structOnObject

end