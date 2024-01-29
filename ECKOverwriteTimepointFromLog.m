function ECKOverwriteTimepointFromLog(path_mat)
% loads all mat export (preprocessed) datasets from a folder, looks for a
% TimePoint variable in the log, and replaces the main TimePoint variable
% with it. Useful when segmentation/preproc has picked up the wrong time
% point, but the value in the log is correct

    d = dir([path_mat, filesep, '*.mat']);
    num = length(d);
    
    for f = 1:num
        
        file_data = fullfile(d(f).folder, d(f).name);
        tmp = load(file_data);
        if ~isfield(tmp, 'data')
            continue
        end
        data = tmp.data;
        
        lg = ECKLog2Table(data.Log);
        if ismember('TimePoint', lg.Properties.VariableNames)
            data.TimePoint = lg.TimePoint(1);
        end
        
        parsave(file_data, 'data');
        fprintf('[%d of %d] %s\n', f, num, file_data)
        
    end




end