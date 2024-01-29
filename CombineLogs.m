function [logOut] = CombineLogs(logA, logB)

    if ~isfield(logB, 'FunName')
        logB.FunName = struct;
    end
    
    % find any entries in B that exist in A
    existFound = cellfun(@(x) strcmpi(logB.FunName, x),...
        logA.FunName, 'UniformOutput', false);
    
    % loop through tasks
    for curA = 1:length(logA.FunName)
        curB = find(existFound{curA});
        
        if ~isempty(curB)
            % current task (in A) exists in B - concat data
            
            % check number of headings is the same
            headA = logA.Headings{curA};
            headB = logB.Headings{curB};
            headComp = cellfun(@(x) strcmpi(x, headB), headA, ...
                'UniformOutput', false);
            
            % do headers differ across logs? if so, remake each log with
            % matching (sorted) headings, and NaNs where there is missing
            % data
            if any(cellfun(@(x) ~any(x), headComp))
                
                % compile all headings (across both logs)
                headMaster = unique([headA, headB]);
                
                % find headings that are missing from log A
                missA = cellfun(@(x) strcmpi(sort(headA), x), headMaster,...
                    'UniformOutput', false);
                missLogA = cellfun(@(x) all(~x), missA);
                missIdxA = find(missLogA);
                missHeadA = headMaster(missIdxA);
                
                % if any were missing, append to log A
                if ~isempty(missHeadA)
                    % append headers, and NULL to data
                    logA.Headings{curA} = [logA.Headings{curA},...
                        missHeadA];
                    nullCol = repmat(cellstr('NULL'), size(logA.Data{curA}, 1),...
                        length(missIdxA));
                    logB.Data{curA} = [logA.Data{curA}, nullCol];
                end
                
                % find headings that are missing from log B
                missB = cellfun(@(x) strcmpi(sort(headB), x), headMaster,...
                    'UniformOutput', false);
                missLogB = cellfun(@(x) all(~x), missB);
                missIdxB = find(missLogB);
                missHeadB = headMaster(missIdxB);                
                
                % if any were missing, append to log A
                if ~isempty(missHeadB)
                    % append headers, and NULL to data
                    logB.Headings{curB} = [logB.Headings{curB},...
                        missHeadB];
                    nullCol = repmat(cellstr('NULL'), size(logB.Data{curB}, 1),...
                        length(missIdxB));
                    logB.Data{curB} = [logB.Data{curB}, nullCol];
                end
                
                % sort both logs 
                [logB.Headings{curB}, soB] = sort(logB.Headings{curB});
                logB.Data{curB} = logB.Data{curB}(:, soB);
                
                [logA.Headings{curA}, soA] = sort(logA.Headings{curA});
                logA.Data{curA} = logA.Data{curA}(:, soA);

                % remake log table
                logB.Table{curB} = [logB.Headings{curB};...
                    logB.Data{curB}];       
                
                logA.Table{curA} = [logA.Headings{curA};...
                    logA.Data{curA}];   
            end
            
            % concat
            logB.Data{curB} = [logB.Data{curB}; logA.Data{curA}];
            logB.Table{curB} = [logB.Table{curB}; logA.Data{curA}];
            
            % check for dupes
            numRows = size(logB.Data{curB}, 1); rowA = 1;
            if numRows > 1
                while rowA < numRows 
                    rowB = rowA + 1;
                    while rowB <= numRows
                        tmpA = logB.Data{curB}(rowA, :);
                        tmpB = logB.Data{curB}(rowB, :);
                        if length(tmpA) == length(tmpB)
                            match = false(1, length(tmpA)); 
                            cl = 1;
                            while cl <= length(tmpA) 
                                if isempty(tmpA{cl}) && isempty(tmpA{cl})
                                    match(cl) = true;
                                elseif isnumeric(tmpA{cl}) && isnumeric(tmpB{cl})
                                    match(cl) = all(tmpA{cl} == tmpB{cl});
                                elseif ischar(tmpA{cl}) && ischar(tmpB{cl})
                                    if length(tmpA{cl}) == length(tmpB{cl}) 
                                        match(cl) = all(tmpA{cl} == tmpB{cl});
                                    end
                                elseif iscell(tmpA{cl}) && iscell(tmpB{cl})
                                    match(cl) = numel(tmpA{cl}) == numel(tmpB{cl});
                                else
                                    match(cl) = false;
                                end
                                cl = cl + 1;
                            end
                        end
                        if all(match)
                            logB.Data{curB}(rowB, :) = [];
                            numRows = size(logB.Data{curB}, 1);
                        else
                            rowB = rowB + 1;
                        end
                    end
                    rowA = rowA + 1;
                end
            end
            
            % rebuild table
            logB.Table{curB} = [logB.Headings{curB}; logB.Data{curB}];
                   
        else
            % current task (in A) does not exist in B - append data
            logB.FunName{end + 1} = logA.FunName{curA};
            logB.Data{end + 1} = logA.Data{curA};
            logB.Headings{end + 1} = logA.Headings{curA};
            logB.Table{end + 1} = logA.Table{curA};
        end     
    end
            
    logOut = logB;
    
end