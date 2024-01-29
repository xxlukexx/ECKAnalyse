function dataOut = ECKLogColumn(hdr, data, colHdr)

    col = find(strcmpi(hdr, colHdr));
    if isempty(col)
        dataOut = [];
        return
    end
    
    dataOut = data(:, col);

end