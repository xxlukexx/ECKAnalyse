function sf = sortSF(sf)

    [~, ord] = sort(sf.sfTime);
    sf.sfTime = sf.sfTime(ord);
    sf.sfFrame = sf.sfFrame(ord);
    
end