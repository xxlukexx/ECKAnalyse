function sfEvents = etRemoveInvalidSFEvents(sfEvents)

    % zero event timestamps
    t = double(cell2mat(sfEvents(:, 2)) - sfEvents{1, 2}) / 1e6;
    
    % remove negatives (events that shouldn't be in there)
    rem = t < 0;
    sfEvents(rem, :) = [];
    
end