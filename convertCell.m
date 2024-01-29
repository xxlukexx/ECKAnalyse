function out = convertCell(data, format)

    if ~iscell(data)
        error('Data argument must be a cell array.')
    end
    
    out = data;
    nRows = size(data, 1);
    nCols = size(data, 2);
    
    for r = 1:nRows
        for c = 1:nCols
            
            if isnumeric(data{r, c}) && strcmpi(format, 'string')
                out{r, c} = num2str(data{r, c});
            elseif ischar(data(r, c)) && strcmpi(format, 'number')
                out{r, c} = str2num(data{r, c});
            end
            
        end
    end
                
end