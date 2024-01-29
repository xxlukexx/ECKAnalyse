function writeTimestamp(pth, timeStamp)

    filename = [pth, filesep, '_timeStamp.mat'];
    save(filename, 'timeStamp')

end