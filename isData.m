function out = isData(filename)

    [path, file, ext] = fileparts(filename);
    out = strcmpi(ext, '.mat') && ~isempty(strfind(file, 'eckdata'));
        
end