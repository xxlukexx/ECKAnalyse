function [heading, data] = etCollateTask(metaData, taskName)

    st = ECKStatus(sprintf('Collating task %s...\n', taskName));
    
    if ~(iscell(metaData) && size(metaData, 2) == 10)
        dc = checkDataIn(metaData);
        if isa(dc, 'ECKDataContainer')
            metaData = dc.LegacyMetadata;
        else
            error('Must pass either ECKData, ECKDataContainer or metaData.')
        end
    end
    
%     % check format of data
%     if isa(metaData, 'ECKDataContainer')
%         dc = metaData;
%         metaData = cell(length(dc.Data), 7);
%         for d = 1:length(dc.Data)
%             metaData{d, 1} = dc.Data{d}.ParticipantID;
%             if isnumeric(dc.Data{d}.TimePoint)
%                 metaData{d, 2} = num2str(dc.Data{d}.TimePoint);
%             elseif ischar(dc.Data{d}.TimePoint)
%                 metaData{d, 2} = dc.Data{d}.TimePoint;
%             else
%                 error('TimePoint is not char or numeric.')
%             end
%             metaData{d, 7} = dc.Data{d}.Log;
%         end
%     end
    
    heading={};
    data={};
    newData = {};
    newHeading = {};

    % loop through all log files, search for tasks that match the supplied
    % task name. collect all headings and data from each matching log, and
    % store in a cell array
    for curEntry = 1:size(metaData, 1)
        
        if isfield(metaData{curEntry, 7}, 'FunName')
        
            % search for task name
            taskIdx = find(strcmpi(metaData{curEntry, 7}.FunName, taskName));
            if ~isempty(taskIdx)

                st.Status = sprintf('Collating task %s (%d of %d)...\n',...
                    taskName, curEntry, size(metaData, 1));

                % get headings 
                newHeading{end + 1} = metaData{curEntry, 7}.Headings{taskIdx};

                % get number of rows of data to be added, and repeat PID and
                % timepoint 
                dataRows = size(metaData{curEntry, 7}.Data{taskIdx},1);
                PID = cellstr(repmat(metaData{curEntry, 1}, [dataRows, 1]));
                tp_tmp = repmat(metaData{curEntry, 3}, [dataRows, 1]);
                if isnumeric(tp_tmp)
                    timePoint = tp_tmp;
                else
                    timePoint = cellstr(tp_tmp);
                end

                % add data  
                newData{end + 1} = metaData{curEntry, 7}.Data{taskIdx}; 

%                 % check for ParticipantID and TimePoint headers, if not present
%                 % add them
% %                 if ~any(strcmpi(newHeading{end}, 'TimePoint'))
%                     newHeading{end} = ['DC_TimePoint', newHeading{end}];
%                     newData{end} = [timePoint, newData{end}];
% %                 end
% 
% %                 if ~any(strcmpi(newHeading{end}, 'ParticipantID'))
%                     newHeading{end} = ['DC_ParticipantID', newHeading{end}];
%                     newData{end} = [PID, newData{end}];
% %                 end

            end
            
        end
                    
    end
        
    if ~isempty(newData)
            
        % combine logs of different length
        hdrLens = cellfun(@length, newHeading);
        if all(hdrLens(1) == hdrLens)
            % all the same length - just concat
            heading = newHeading{1};
            data = vertcat(newData{:});
        else
            warning('Number of columns varies between logs. Columns will be sorted to allow combination.')
            masterHeadings = unique(horzcat(newHeading{:}));
            for curLog = 1:length(newHeading)

                % find missing heading
                miss = cellfun(@(x) strcmpi(sort(newHeading{curLog}), x),...
                    masterHeadings, 'UniformOutput', false);
                missLog = cellfun(@(x) all(~x), miss);
                missIdx = find(missLog);
                missHead = masterHeadings(missIdx);

                % append 
                newHeading{curLog} = [newHeading{curLog}, missHead];
                newData{curLog} = [newData{curLog}, repmat(cellstr(repmat(...
                    'NULL', size(newData{curLog}, 1), 1)), 1, length(missIdx))];
                [newHeading{curLog}, sortOrd] = sort(newHeading{curLog});
                newData{curLog} = newData{curLog}(:, sortOrd);

            end

            % write final data to output args
            heading = masterHeadings;
            data = vertcat(newData{:});

        end
    end
    
end