function match = compareTimes(pth, timeStamp)

    match = false;
    filename = [pth, filesep, '_timeStamp.mat'];
    if exist(filename, 'file')
        tmp = load(filename);
        match = tmp.timeStamp == timeStamp;
    end

end

