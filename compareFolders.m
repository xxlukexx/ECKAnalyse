function [same, numA, numB] = compareFolders(a, b)

    % recursively search through both folders and subfoldesr
    da = rdir(a);
    db = rdir(b);
    
    % delete mac crap (.DS_Store)
    idx = cellfun(@(x) ~isempty(strfind(x, '.DS_Store')), {da.name}');
    if ~isempty(idx), da(idx) = []; end
    idx = cellfun(@(x) ~isempty(strfind(x, '.DS_Store')), {db.name}');
    if ~isempty(idx), db(idx) = []; end
    
    % store lengths
    numA = length(da);
    numB = length(db);
    
    % compare lengths
    if numA ~= numB
        same = false;
        return
    end
    
    % get lengths of each path
    lena = length(a) + 2;
    lenb = length(b) + 2;
    
    % loop through and compare names, dates and sizes
    same = true;
    for f = 1:numA
        
%         same = same && ...
%             strcmp(da(f).name(lena:end), db(f).name(lenb:end)) &&...
%             da(f).datenum == db(f).datenum &&...
%             da(f).bytes == db(f).bytes;

        same = same && ...
            strcmp(da(f).name(lena:end), db(f).name(lenb:end)) &&...
            da(f).datenum == db(f).datenum &&...
            da(f).bytes == db(f).bytes;
        
    end

end