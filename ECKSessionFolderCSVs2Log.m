function lg = ECKSessionFolderCSVs2Log(path_ses)

    d = dir([path_ses, filesep, '*.csv']);
    num = length(d);
    lg = struct;
    for i = 1:length(d)
        tab = readtable(fullfile(d(i).folder, d(i).name));
        lg.FunName{i} = strrep(d(i).name, '.csv', '');
        lg.Headings{i} = tab.Properties.VariableNames;
        lg.Data{i} = table2cell(tab);
        lg.Table{i} = [lg.Headings{i}; lg.Data{i}];
    end

end