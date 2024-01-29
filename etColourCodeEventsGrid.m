function [grid, maxLen] = etColourCodeEventsGrid(grid, sel)

    wb = waitbar(0, 'Coding events');

    ev = grid(:, 4);
    
    % has max length been requested?
    if nargout == 1 
        maxLen = [];
        calcLen = false;
    else
        calcLen = true;
    end
    
    % if no selection vector has been passed, assume none
    if ~exist('sel', 'var') || isempty(sel)
        sel = false(length(grid), 1);
    end
    
    % filter events with a XXX_YYYYY structure (i.e. take the first bit of
    % the label before an underscore). If there is no underscore, use the
    % whole label
    
    [uLab, labIdx] = etEventGridPrefixes(ev);
    
    % prepare colours
    iconCol = hsv(length(uLab));
    iconCol = round(iconCol * 255);
%     iconColHex = reshape(dec2hex(iconCol', 2), [size(iconCol, 1), 6]);
    iconColHex = cell2mat(arrayfun(@(x) dec2hex(x, 2), iconCol, 'uniform', 0));
    
    selBGCol = [140, 220, 150];
    selBGColHex = [dec2hex(selBGCol(1), 2), dec2hex(selBGCol(2), 2), dec2hex(selBGCol(3), 2)];
    
    % loop through and assing colour HTML tag to each unique label
    formatEv = grid;
    for row = 1:size(grid, 1)
                
        if mod(row, 500) == 0
            wb = waitbar(row / length(ev), wb, 'Coding events');
        end

        % look up colour for icon
        curIconCol = iconColHex(labIdx(row), :);
        
        % set BG colour for selection (on all but label columns)
        if sel(row)
            % set it for label columns
            formatEv{row, 4} = [...
                '<html><table border=0><TR><TC><TD width=10 bgcolor=#',...
                curIconCol, '></TD></TC><TC><TD bgcolor=#', selBGColHex, '><b>' ev{row},...
                '</b></TD></TC></TR></table></html>'];
        else
            formatEv{row, 4} = [...
                '<html><table border=0><TR><TC><TD width=10 bgcolor=#',...
                curIconCol, '></TD></TC><TC><TD>', ev{row},...
                '</TD></TC></TR></table></html>'];
        end
        
    end
    
    % get max width of text (if requested)
    if calcLen
        gridChar = cellfun(@num2str, grid, 'uniform', 0);
        maxLen = max(cellfun(@(x) size(x, 2), gridChar));
    end
    
    grid = formatEv;
    close(wb)
    
end