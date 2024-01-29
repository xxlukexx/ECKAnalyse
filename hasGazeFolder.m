function [has, path_gaze] = hasGazeFolder(sessionFolder)

    path_gaze = [sessionFolder, filesep, 'gaze'];
    has = isGazeFolder(path_gaze);
    
%     disp(sessionFolder)
%     disp(gazePath)
    
end