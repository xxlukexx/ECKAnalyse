function sfEvents = etSortSFEvents(sfEvents)

    [~, ord] = sort(cell2mat(sfEvents(:, 1)));
    sfEvents = sfEvents(ord, :);
    
end