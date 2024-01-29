function tab = etDQ2Table(dq)

    tab = table;
    numRows = length(dq);
    for r = 1:numRows
        tab = [tab; array2table([dq{r}.missing, dq{r}.mono, dq{r}.bino],...
            'variablenames', {'prop_missing', 'prop_mono', 'prop_bino'})];
    end
        
end