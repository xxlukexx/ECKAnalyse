function localRoot = getLocalRoot(location, project)

    tab = {...
    %   location        project         root
        'mbp15_home',   'ph2_et',       '/Volumes/LM_HOME/Projects/Phase 2'                                     ;...
        'imac_work',    'ph2_et',       '/Volumes/Data/Projects/Phase 2'                                        ;...
        'mbp15_home',    'ph2_visits',   '/Users/lukemason/Google Drive/CBCD/BASIS/Phase 2/ET/visit_dates.xlsx'  };
    
    found = find(strcmpi(tab(:, 1), location) & strcmpi(tab(:, 2), project));
    
    if isempty(found)
        error('Not found.')
    end
    
    localRoot = tab{found, 3};

end