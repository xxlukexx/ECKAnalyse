function combined_log = CombineLogs2(logA, logB)

    % check log structure
    expected_fields = {'FunName', 'Data', 'Headings', 'Table'};
    if ~all(ismember(fieldnames(logA), expected_fields))
        error('logA invalid format.')
    elseif ~all(ismember(fieldnames(logB), expected_fields))
        error('logB invalid format.')
    end
    
    % if both are equal, our work is done
    if isequal(logA, logB)
        combined_log = logA;
        return
    end

    % find unique tasks from both logs
    allTasks = unique([logA.FunName, logB.FunName]);
    numTasks = length(allTasks);
    
    % for each task, loop through and combine 
    for t = 1:numTasks
       
        task = allTasks{t};
        combined_log.FunName{t} = task;
        
        % find task from each log
        idxA = find(strcmp(logA.FunName, task), 1);
        idxB = find(strcmp(logB.FunName, task), 1);
        if isempty(idxA) && ~isempty(idxB)
            % only in log B
            combined_log.Data{t} = logB.Data{idxB};
            combined_log.Headings{t} = logB.Headings{idxB};
            
        elseif isempty(idxB) && ~isempty(idxA)
            % only in A
            combined_log.Data{t} = logA.Data{idxA};
            combined_log.Headings{t} = logA.Headings{idxA};
            
        elseif isempty(idxA) && isempty(idxB)
            error('Could not find task %s', task)
            
        else
            datA = logA.Data{idxA};
            hdrA = logA.Headings{idxA};
            datB = logB.Data{idxB};
            hdrB = logB.Headings{idxB};

            tabA = cell2table(datA, 'VariableNames', fixTableVariableNames(hdrA));
            tabB = cell2table(datB, 'VariableNames', fixTableVariableNames(hdrB));

            % check if both are equal
            fprintf('Tables match: %d %d\t\t', t, isequal(tabA, tabB))
            fprintf('Headers match: %d %d\n', t, isequal(hdrA, hdrB))
                    
            if isequal(tabA, tabB)
                % both tables equal, jus take A
                combined_log.Data{t} = datA;
                combined_log.Headings{t} = hdrA;

            elseif isequal(hdrA, hdrB)
                % headers match - vertcat data
                combined_log.Data{t} = [datA; datB];
                combined_log.Headings{t} = hdrA;

            else
                error('Mismatched headers not yet implemented!')

            end
            
        end

        % de-dup - first make signature of data in each row
%         tmpTab = cell2table(combined_log.Data{t}, 'VariableNames',...
%             combined_log.Headings{t});
        tmpTab = cell2table(combined_log.Data{t});
%         [~, uRow, ~] = unique(tmpTab, 'rows');
        
        numRows = size(combined_log.Data{t}, 1);
        sig = cell(numRows, 1);
        for r = 1:numRows
            row = combined_log.Data{t}(r, :);
            sig{r} = cell2char(row);
        end

        [~, uRow, ~] = unique(sig);
        combined_log.Data{t} = combined_log.Data{t}(uRow, :);

        % make table field
        combined_log.Table{t} =...
            [combined_log.Headings{t}; combined_log.Data{t}];
                    
    end
        
end