function magRect = magnifyRect(rect, mag)

    % find centre
    x=(rect(1) + rect(3)) / 2;
    y=(rect(2) + rect(4)) / 2;

    % subtract centre
    rectTmp = [rect(1) - x, rect(2) - y, rect(3) - x, rect(4) - y];

    % scale
    rectTmp = rectTmp * mag;

    % add centre back again
    magRect = [rectTmp(1) + x, rectTmp(2) + y, rectTmp(3) + x, rectTmp(4) + y];

end