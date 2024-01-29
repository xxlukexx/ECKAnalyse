function [md] = etCombineSessions(md)

    % first loop through all entries to find min and max time values (these
    % will be used to figure out the correct order to combine data)
    tMin = zeros(size(md, 1), 1);
    tMax = zeros(size(md, 1), 1);
    
    for d = 1:size(md, 1)
        
        if ~isempty(md{d, 9})
            tMin(d) = min(md{d, 9}(:,1));
            tMax(d) = max(md{d, 9}(:,1));
        else
            % if no data in this entry, set it's max to the maximum value
            % that can be stored in a double, to be sure it will end up
            % combined at the end of the list
            tMin(d) = realmax('double');
            tMax(d) = realmax('double');
        end
        
    end
    
    % check data types of participant ID, time point and battery
    if all(cellfun(@isnumeric, md(:, 1)))
        md(:, 1) = cellstr(cellfun(@num2str, md(:, 1)));
    end

    if all(cellfun(@isnumeric, md(:, 2)))
        md(:, 2) = cellstr(cellfun(@num2str, md(:, 2)));
    end
    
    if all(cellfun(@isnumeric, md(:, 3)))
        md(:, 3) = cellstr(cellfun(@num2str, md(:, 3), 'uniform', 0));
    end
    
    % loop through again, this time looking for repeats
    d = 1;
    while d < size(md, 1)
        
        % variables
        id          =   md{d, 1};    
        tp          =   md{d, 2};
        bat         =   md{d, 3};
        
        % find duplicates
        dupP = strcmpi(id, md(:, 1));
        dupTP = strcmpi(tp, md(:, 2));
        dupBattery = strcmpi(bat, md(:, 3));
        cnd = dupP & dupTP & dupBattery;
        idx = find(cnd);
        
        % sort duplicate indexes according to start times of gaze data, so
        % that we combine sessions in the correct order
        
        
        % combine duplicates
        if size(idx, 1) > 1 
            
            for curIdx = 2:size(idx, 1)

                % combine rows
                newDat = md{idx(curIdx),8};
                md{d,8} = [md{d,8};...
                                            newDat];

                newDat = md{idx(curIdx),9};
                md{d,9} = [md{d,9};...
                                            newDat];

                newDat = md{idx(curIdx),10};
                md{d,10} = [md{d,10};...
                                            newDat];
                                        
                md{d, 7} = CombineLogs2(...
                    md{d, 7}, md{idx(curIdx), 7});
                                        
            end
                           
            % mark current entry as safe
            cnd(d) = 0;
            
            % remove duplicate row(s)
            md = md(~cnd,:);

        end
        
        d = d + 1;
        
    end

end