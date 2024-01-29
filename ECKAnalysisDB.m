classdef ECKAnalysisDB < handle
    
    properties (SetAccess = private)
        FailedIngest
    end
    
    properties (Dependent)
        AllowParallelProcessing
        Data
        OpsTable
    end
    
    properties (Dependent, SetAccess = private)
        NumData
        NumProcNeeded
        DuplicateTable
        NSummary
        WideTable
        WideSummaryTable
        WaveSummaryTable
        TallTable
        MissingTable
        IDWaveTable
    end
    
    properties (Access = private)
        pData
        pOps
        pAllowParallelProcessing = true
        pParForArg = inf
    end
    
    methods
        
        function obj = ECKAnalysisDB
            obj.pData = table;
            obj.pOps = {};
        end
        
        function Ingest(obj, pth, site, wave, id)
            
            if ~ischar(pth)
                error('Path must be char.')
            end
            
            if ~exist(pth, 'dir') && ~exist(pth, 'file')
                error('Path not found: %s', pth)
            end
            
            if ~exist('site', 'var') || isempty(site)
                site = 'NONE';
             end
            
            if ~exist('wave', 'var') || isempty(wave)
                wave = 'NONE';
            end
            
            doAdd = false;
            doUpdate = false;
            updateLastSeen = false;
            
%             try
            
                % check whether we have seen this data before
                [seen, dataKey] = obj.Seen(pth);
                if seen
                    % already in db, check if it has changed
                    obj.pData.LastSeen(dataKey) = now;
                    [changed, hash] = obj.Changed(pth, dataKey);
                    if changed
                        % changed, so update, don't add
                        doUpdate = true;
                    else
                        updateLastSeen = true;
                    end
                else
                    % not seen, so add it
                    hash = recmd5(pth);
                    doAdd = true;
                end
                
                % if no ID supplied, try to get it
                if ~exist('id', 'var') || isempty(id)
                    [success, id] = getIDFromSessionFolder(pth);
                else
                    success = true;
                end

                if doAdd
                    tmp = table;
                    canProc = success;
                    needsProc = success;
                    tmp.ID =                        {id};
                    tmp.Site =                      {site};
                    tmp.Wave =                      {wave};
                    tmp.SessionPath =               {pth};
                    tmp.FirstSeen =                 now;
                    tmp.LastSeen =                  tmp.FirstSeen;
                    tmp.GUID =                      {GetGUID};
                    tmp.Hash =                      {hash};
                    tmp.CanProcess =                canProc;
                    tmp.NeedsProcessing =           needsProc;
                    tmp.Version =                   1;
                    obj.pData =                     [obj.pData; tmp];
                end

                if doUpdate
                    [success, id] = getIDFromSessionFolder(pth);
                    canProc = success;
                    needsProc = success;
                    obj.pData.ID{dataKey} =         id;
                    obj.pData.Site{dataKey} =       site;
                    obj.pData.Wave{dataKey} =       wave;
                    obj.pData.LastSeen(dataKey) =   now;
                    obj.pData.Version(dataKey) =    obj.pData.Version(dataKey) + 1;
                    tmp.Hash{dataKey} =             hash;
                    tmp.CanProcess(dataKey) =       canProc;
                    tmp.NeedsProcessing(dataKey) =  needsProc;                
                    obj.ClearOps(dataKey);
                end

                if updateLastSeen
                    obj.pData(dataKey, :).LastSeen = now;
                end
                
%             catch ERR
%                 
%                 idx = size(obj.FailedIngest, 1);
%                 idx = idx + 1;
%                 obj.FailedIngest{idx, 1} = pth;
%                 obj.FailedIngest{idx, 2} = ERR.message;
%                 
%             end
            
        end
        
        function [seen, dataKey] = Seen(obj, pth)
            if isempty(obj.pData)
                seen = false;
                dataKey = [];
                return
            end
            dataKey = find(strcmpi(obj.pData.SessionPath, pth));
            if isempty(dataKey)
                seen = false;
                return
            end
            seen = true;
        end
        
        function [changed, newHash] = Changed(obj, pth, dataKey)
            oldHash = obj.pData.Hash{dataKey};
            newHash = recmd5(pth);
            changed = ~isequal(oldHash, newHash);
        end
        
        function Remove(obj, dataKey)
            if ~isnumeric(dataKey) || dataKey < 1 || dataKey > size(obj.pData, 1)
                error('Invalid data key.')
            end
            obj.pData(dataKey, :) = [];
        end
        
        function AddOp(obj, dataKey, op)
            if ~iscell(op), op = {op}; end
            if isempty(obj.pOps)
                idx = 1;
            else
                idx = length(obj.pOps.DataKey) + 1;
            end
            
            for o = 1:length(op)
                obj.pOps.DataKey(idx) = dataKey;
                obj.pOps.Operation{idx} = op{o}.Operation;
                obj.pOps.Success(idx) = op{o}.Success;
                obj.pOps.Outcome{idx} = op{o}.Outcome;
                if isfield(op{o}, 'ExtraData')
                    obj.pOps.ExtraData{idx} = op{o}.ExtraData;
                end
                idx = idx + 1;
            end
        end
            
        function ClearOps(obj, dataKey)
            if isempty(obj.pOps), return, end
            if exist('dataKey', 'var') && ~isempty(dataKey)
                opsKey = find(obj.pOps.DataKey == dataKey);
                if isempty(opsKey), return, end
                fnames = fieldnames(obj.pOps);
                for f = 1:length(fnames)
                    obj.pOps.(fnames{f})(opsKey) = [];
                end
%                 obj.pOps(opsKey, :) = [];
            else
                obj.pOps = [];
            end
        end
        
        function dataKey = GetKey(obj, pth)
            if isempty(obj.pData)
                dataKey = [];
                return
            end
            dataKey = find(strcmpi(obj.pData.SessionPath, pth));
        end
        
        function [needed, pth, id, site, wave, dataKey] = GetNext(obj)
            pth = [];
            id = [];
            wave = [];
            site = [];
            dataKey = [];
            if obj.NumProcNeeded == 0
                needed = false;
                return
            end
            needed = true;
            dataKey = find(obj.pData.NeedsProcessing, 1, 'first');
            pth = obj.pData.SessionPath{dataKey};
            id = obj.pData.ID{dataKey};
            wave = obj.pData.Wave{dataKey};
            site = obj.pData.Site{dataKey};
        end
        
        function ResetProc(obj, dataKey)
            if ~exist('dataKey', 'var') || isempty(dataKey)
                % reset all
                obj.pData.NeedsProcessing = obj.pData.CanProcess;
%                 obj.pData.NeedsProcessing = true(size(obj.pData, 1), 1);
            else
                if ~isnumeric(dataKey)
                    error('Data keys must be numeric.')
                elseif any(dataKey < 1 | dataKey > obj.NumData)
                    error('Invalid data key.')
                else
                    obj.pData.NeedsProcessing(dataKey) = true;
                end
            end
        end
        
        function ProcFinished(obj, dataKey)
            obj.pData.NeedsProcessing(dataKey) = false;
        end
        
        function tab_summary = PlotTaskBySiteWave(obj, fun, numericOnly)
            if isempty(obj.pOps)
                return
            end
            warning('Multiple sites not yet implemented - this may crash.')
            % set default function to sum
            if ~exist('fun', 'var') || isempty(fun)
                fun = @sum;
            end
            % set default for only showing numeric component of wave
            if ~exist('numericOnly', 'var') || isempty(numericOnly)
                numericOnly = false;
            end                
            % get site * wave subs/labels
            tab = obj.WideTable;
            % extract number component from wave variable (if requested)
            if numericOnly
                waveNum = cellfun(@(x)...
                    str2double(regexp(x, '\d*', 'match')), tab.Wave);
                tab.Wave = arrayfun(@num2str, waveNum, 'uniform', false);
            end
            
            [site_u, ~, site_s] = unique(tab.Site);
            numSites = length(site_u);
            site_lab = cellfun(@(x) ['site_', x], site_u, 'uniform', 0);
            
            [wave_u, ~, wave_s] = unique(tab.Wave);
            numWaves = length(wave_u);
            % sort waves by numeric content (if possible)
            wave_u_num = cellfun(@(x) str2double(regexp(x, '\d*', 'match')),...
                wave_u, 'uniform', false);
            if ~all(cellfun(@isempty, wave_u_num))
                [~, so] = sort(cell2mat(wave_u_num));
                wave_u = wave_u(so);
                canSort = true;
            else 
                canSort = false;
            end
            wave_lab = cellfun(@(x) ['wave_', x], wave_u, 'uniform', 0);

            % get list of variables to summarise (ops)
            opNames = tab.Properties.VariableNames(13:end);
            numOps = length(opNames);
            val = zeros(numWaves, numOps, numSites);
            for o = 1:length(opNames)
                val(:, o) =...
                    accumarray([wave_s, site_s], tab.(opNames{o}), [], fun);
            end
            if canSort, val = val(so, :); end
            
            % make table
            tab_summary = cell2table([wave_u, num2cell(val)],...
                'variablenames', ['Wave', opNames]);
            
            % make mean lines for each wave
            mu_y = median(val, 2);
            
            % plot
            figure('menubar', 'none', 'name', 'Site * Wave summary',...
                'numbertitle', 'off');
            for s = 1:numSites
                subplot(numSites, 1, s)
                bar(val', 1)
                hold on
                xl = xlim;
                lineCols = parula(numWaves);
                for w = 1:numWaves
                    set(gca, 'colororderindex', w);
                    plot(xl, [mu_y(w), mu_y(w)], 'color', [lineCols(w, :), .5],...
                        'linewidth', 3);
                end
                set(gca, 'xtick', 1:numOps)
                set(gca, 'xticklabels', opNames)
                set(gca, 'XTickLabelRotation', 90)
                set(gca,'TickLabelInterpreter','none')
                xlabel('Operation')
                ylabel('Count')
                legend(wave_lab, 'interpreter', 'none')
                title(site_lab{s}, 'interpreter', 'none')
                set(gca, 'fontsize', 12)
                set(gca, 'ygrid', 'on')
                set(gca, 'yminorgrid', 'on')                
            end
            
        end
        
        function PlotPresenceByWave(obj, op)
            % if no ops, return
            if isempty(obj.pOps)
                return 
            end         
            oldInterpreter = get(groot, 'DefaultAxesTickLabelInterpreter');
            set(groot, 'DefaultAxesTickLabelInterpreter', 'none')
            % get presence table
            agg = obj.PresenceTable(op);
            wave_u = agg.Properties.VariableNames;
            ids = agg.Properties.RowNames;
            % convert to array
            agg = agg{:, :};
            % plot
%             figure
            hm = heatmap(agg, 'Colormap', [.8, 0, 0; .4, .8, .4]);
            hm.ColorbarVisible = 'off';
            hm.MissingDataColor = [1, 1, 1];
            % label only those IDs with missing/failed data
            id_u = unique(ids);
%             id_u = unique(obj.Data.ID);
%             wave_u = unique(obj.Data.Wave);
            anyFailed = any(agg ~= 2, 2);
            id_u(~anyFailed) = {''};
            hm.YDisplayLabels = ids;
            if ~isempty(wave_u)
                hm.XDisplayLabels = wave_u;
            end
            set(groot, 'DefaultAxesTickLabelInterpreter', oldInterpreter)
        end
        
        function [ids, tab, ops] = ListMissingIDs(obj, task)
            
            wt = obj.WideTable;
            idx = ~wt.(task);
            tab =  wt(idx, :);
            ids = tab.ID;
            
            ot = obj.OpsTable;
            idx = ismember(ot.ID, ids) & strcmpi(ot.Operation, task);
            ops = ot(idx, :);
            
        end
        
        function val = get.Data(obj)
            val = obj.pData;
        end
        
        function set.Data(obj, val)
%             warning('No type checking here - be careful!')
            obj.pData = val;
        end
        
        function val = get.NumData(obj)
            val = size(obj.pData, 1);
        end
        
        function val = get.NumProcNeeded(obj)
            if isempty(obj.pData)
                val = 0;
                return
            end
            val = sum(obj.pData.NeedsProcessing);
        end
        
        function [has, keys, groupedDups] = HasDuplicates(obj)
            if isempty(obj.pData)
                has = false;
                keys = [];
                return
            end
            
            id = obj.pData.ID;
            site = obj.pData.Site;
            wave = obj.pData.Wave;
            
            % check for empty values
            idEmpty = cellfun(@isempty, id);
            if any(idEmpty)
                id(idEmpty) = repmat({'ERROR'}, sum(idEmpty), 1);
            end
            
            siteEmpty = cellfun(@isempty, site);
            if any(siteEmpty)
                site(siteEmpty) = repmat({'ERROR'}, sum(siteEmpty), 1);
            end       
            
            waveEmpty = cellfun(@isempty, wave);
            if any(siteEmpty)
                wave(waveEmpty) = repmat({'ERROR'}, sum(waveEmpty), 1);
            end
            
            % make string of id, site, wave
            labs = cellfun(@(x, y, z) [x, y, z], id, site, wave,...
                'uniform', false);
            uLab = unique(labs);
            
            % compare unique list of id/site/wave with actual list -
            % difference in size means there are some duplicates
            if length(labs) ~= length(uLab)
                has = true;
                tb = tabulate(labs);
                dupTabIdx = cell2mat(tb(:, 2)) > 1;
                tb = tb(dupTabIdx, :);
                keys = find(...
                    cellfun(@(x) ~isempty(find(strcmpi(tb(:, 1), x), 1)),...
                    labs));
                groupedDups = cellfun(@(x) find(strcmpi(x, labs)),...
                    tb(:, 1), 'uniform', false);
            else
                has = false;
                keys = [];
            end
        end
        
        function val = get.DuplicateTable(obj)
            val = obj.WideTable;
            [hasDup, keysDup] = obj.HasDuplicates;
            if hasDup
                val = val(keysDup, :);
            else
                val = [];
            end
        end
        
        function AutoCombine(obj)
            % check for dups, get keys for groups of dups
            [has, dupKeys] = obj.HasDuplicates;
            if ~has, fprintf('No duplicates found.'), return, end
            % get session paths for duplicates
            sesPaths = obj.Data.SessionPath(dupKeys);
            % strip off session paths, to leave just path to ID folder
            parts = cellfun(@(x) strsplit(x, filesep), sesPaths,...
                'uniform', false);
            idPaths = cellfun(@(x) [filesep, fullfile(x{1:end - 1})], parts,...
                'uniform', false);
            % take unqiue values, since we'll see a separate ID folder for
            % each duplicate 
            idPaths = unique(idPaths);
            % summarise sessions
            recAction = cell(size(idPaths));
            dupSmry = cellfun(@summariseSession, idPaths, 'uniform',...
                false);
            numDup = size(dupSmry, 1);
            for d = 1:numDup
                numSes = size(dupSmry{d}, 1);
                taskSmry = dupSmry{d}(:, 5);
                % determine recommended action
                actionStr = {...
                    'Do nothing'                                ;... % 1
                    'Combine',                                  ;... % 2
                    'Do nothing - other sessions were empty'    ;... % 3
                    'Delete'                                    };   % 4
                
                % only one session (indicates totally empty sessions, since
                % these will not be read by summariseSession)
                if length(taskSmry) == 1
                    % do nothing
                    recAction{d} = 1;
                elseif isequal(taskSmry{:})  % all data the same 
                    % keep first and delete
                    recAction{d}(1, 1) = 2;
                    if numSes > 1, recAction{d}(2:numSes, 1) = 4; end
                else   % data are different - combine all
                    recAction{d} = repmat(2, numSes, 1);
                end
                
                dupSmry{d} = [dupSmry{d}, num2cell(recAction{d}),...
                    actionStr(recAction{d})];
            end
            % summarise for display
            actSmry = vertcat(dupSmry{:});
            actSmry = cell2table(actSmry(:, [1, 2, 7]),...
                'variablenames', {'ID', 'Timepoint', 'Action'});
            disp(actSmry)
            % ask for input
            resp = input('Continue to combining? (y/n) >', 's');
            if isempty(strfind(lower(resp), 'y'))
                fprintf('Cancelled.\n')
            end
            % combine
            parfor (d = 1:numDup, obj.pParForArg)
                shortList = dupSmry{d}(recAction{d} == 2, :);
                if ~isempty(shortList)
                    combineSession2(shortList(:, 3))
                end
            end
        end
        
        function [ids_notInDB, ids_notInList] = CrossCheck(obj, ids)
            % if ids are numbers, convert to cell
            if ~iscell(ids) 
                if ~isnumeric(ids)
                    error('ids must be a cell array or numeric vector.')
                else
                    ids = num2cell(ids);
                end
            end
            % convert any numeric elements to char
            isnum = cellfun(@isnumeric, ids);
            ids(isnum) = cellfun(@num2str, ids(isnum), 'uniform', false);
            % get database IDs, convert numeric to char
            ids_adb = obj.Data{:, 1};
            isnum = cellfun(@isnumeric, ids_adb);
            ids_adb(isnum) = cellfun(@num2str, ids_adb(isnum), 'uniform', false);
            % find ids that are not in the databse
            notInDB = cellfun(@(x) ~ismember(x, ids_adb), ids);
            ids_notInDB = sort(ids(notInDB));
            % find ids that are in the database, but not in the list
            notInList = cellfun(@(x) ~ismember(x, ids), ids_adb);
            ids_notInList = sort(ids_adb(notInList));
        end
        
        function val = get.NSummary(obj)
           % make summary
            [site_u, ~, site_s] = unique(obj.pData.Site);
            [wave_u, ~, wave_s] = unique(obj.pData.Wave);
            N = accumarray([site_s, wave_s], 1, [], @sum);
            val = cell2table([site_u, num2cell(N)], 'variablenames',...
                ['Site', fixTableVariableNames(wave_u)']); 
        end
        
        function val = get.WideTable(obj)
            val = [];
            if isempty(obj.pData)
                return
            end
            if isempty(obj.pOps)
                val = obj.pData;
                return
            end
            val = obj.pData;
            
            % get unique operations and make headers
            s = struct(obj.pOps);
            uOp = unique(s.Operation);
            numOps = length(uOp);

            % loop through data and add ops to the temp table
            tmpTable = false(size(val, 1), length(uOp));
            for key = 1:size(val, 1)
                idx = find(obj.pOps.DataKey == key);
                if isempty(idx), continue, end
                numOps = length(idx);
                for o = 1:numOps
                    operation = obj.pOps.Operation(idx(o));
                    success = obj.pOps.Success(idx(o));
                    col = find(strcmpi(uOp, operation), 1, 'first');
                    tmpTable(key, col) = success;
                end
            end
            
            % add to data table
            val = [val, array2table(tmpTable, 'variablenames',...
                fixTableVariableNames(uOp))];
        end
        
        function val = get.WideSummaryTable(obj)
            val = [];
            if isempty(obj.pData)
                return
            end
            if isempty(obj.pOps)
                val = obj.pData;
                return
            end
            
            % get table
            wt = obj.WideTable;
            if isempty(wt), val = []; return, end
            
            % find numeric/logical columns
            numCols = size(wt, 2);
            if numCols == 11, val = []; return, end
            isNum = false(1, numCols);
            for c = 11:numCols
                isNum(c) = isnumeric(wt{1, c}) | islogical(wt{1, c});
            end
            
            % summarise
            data = double(wt{:, isNum});
            varNames = {'Sum', 'Prop', 'Min', 'Max', 'Mean', 'SD'};
            rowNames = wt.Properties.VariableNames(11:numCols);            
            summary = [sum(data); prop(data); min(data); max(data);...
                mean(data); std(data)]';
            val = array2table(summary, 'RowNames', rowNames,...
                'VariableNames', varNames);                    
        end
        
        function val = get.WaveSummaryTable(obj)
            
            val = [];
            if isempty(obj.pData)
                return
            end
            if isempty(obj.pOps)
                val = obj.pData;
                return
            end
            
            ot = obj.OpsTable;
            
            idNum = extractNumeric(ot.ID);
            idx_empty = ~cellfun(@isscalar, idNum);
            idx_suc = cell2mat(ot.Success);
            idNum(idx_empty | ~idx_suc) = [];
            ot(idx_empty | ~idx_suc, :) = [];
            
            [wave_u, ~, wave_s] = unique(ot.Wave);
            [op_u, ~, op_s] = unique(ot.Operation);
            [site_u, ~, site_s] = unique(ot.Site);
            

            
            m = accumarray([op_s, wave_s, site_s], double(cell2mat(ot.Success)), [], @sum);
            mid = accumarray([op_s, wave_s, site_s], double(cell2mat(idNum)), [], @max);

            varNames = fixTableVariableNames(wave_u);
            rowNames = fixTableVariableNames(op_u);
            val = struct;
            for s = 1:length(site_u)
                val(s).site = site_u{s};
                val(s).table = array2table(mid(:, :, s), 'VariableNames', varNames, 'RowNames', rowNames);
            end
            
        end
            
        function val = get.OpsTable(obj)
            val = table;
            if isempty(obj.pOps), return, end
            val.DataKey = obj.pOps.DataKey';
            val.ID = obj.pData.ID(obj.pOps.DataKey);
            val.Site = obj.pData.Site(obj.pOps.DataKey);
            val.Wave = obj.pData.Wave(obj.pOps.DataKey);
            val.Operation = obj.pOps.Operation';
            val.Success = num2cell(obj.pOps.Success');
            val.Outcome = obj.pOps.Outcome';
%             % get ExtraData field, replace empty with nan
%             emptyED = cellfun(@isempty, obj.pOps.ExtraData);
%             ed = cell(size(emptyED));
%             ed(~emptyED) = obj.pOps.ExtraData(~emptyED);
%             val.ExtraData = ed';
        end
        
        function val = PresenceTable(obj, op)
            % get ops table
            ot = obj.OpsTable;
            % check op exists
            % filter for requested op
            filterIdx = strcmpi(ot.Operation, op);
            ot = ot(filterIdx, :);
            % check op exists
            if isempty(ot)
                error('Operation ''%s'' not found.', op)
            end
            % attempt to convert wave to numeric. If wave contains numbers
            % (e.g. 5mo) then this will allow sorting in ascending order
            wave_n = extractNumeric(ot.Wave);
            if all(~isempty(wave_n))
                if iscell(wave_n)
                    wave_n = cell2mat(wave_n);
                end
                % replace wave with numeric
                wave = wave_n;
            else
                % can't extract numbers, so use the existing wave values
                wave = ot.Wave;
            end
            % make site/wave/ID subscripts
            [wave_u, ~, wave_s] = unique(wave);
            if isempty(wave_u), wave_u = {'none'}; end
            [id_u, ~, id_s] = unique(ot.ID);
            % add one to success, so that 1 = false, 2 = true and 0 can be
            % reserved for missing datasets (so that we can differentiate
            % between failed and missing)
            suc = cell2mat(ot.Success) + 1;
            % aggregate
            val = accumarray([id_s, wave_s], suc, [], @sum);
            val(val == 0) = nan;
            % make into table
            if isnumeric(wave_u)
                wave_u = arrayfun(@(x) sprintf('Wave_%d', x), wave_u, 'uniform', false);
            end
            val = array2table(val, 'RowNames', id_u,...
                'VariableNames', wave_u');
        end
        
        function val = get.MissingTable(obj)
            % get all data
            tab = obj.Data;
            % attempt to convert wave to numeric. If wave contains numbers
            % (e.g. 5mo) then this will allow sorting in ascending order
            wave_n = extractNumeric(tab.Wave);
            if all(~isempty(wave_n))
                if iscell(wave_n)
                    wave_n = cell2mat(wave_n);
                end
                % replace wave with numeric
                wave = wave_n;
            else
                % can't extract numbers, so use the existing wave values
                wave = tab.Wave;
            end
            % make site/wave/ID subscripts
            [wave_u, ~, wave_s] = unique(wave);
            [id_u, ~, id_s] = unique(tab.ID);  
            % aggregate
            agg = ~accumarray([id_s, wave_s], ones(size(tab, 1), 1), [],...
                @sum);
            % summarise
            val = table;
            for col = 1:size(agg, 2)
                % get indices of missing IDs for this wave
                idx = find(agg(:, col));
                ids_missing = id_u(idx);
                wave_missing = repmat(wave_u(col), length(idx), 1);
                tmp = table;
                tmp.ID = ids_missing;
                tmp.Wave = wave_missing;
                val = [val; tmp];
            end
        end
        
        function val = get.IDWaveTable(obj)
            
            % filter only to those that can be processed
            tab = obj.Data(logical(obj.Data.CanProcess), :);
            
            % get subs
            [id_u, ~, id_s] = unique(tab.ID);
            [wave_u, ~, wave_s] = unique(tab.Wave);
            ni = length(id_s);
            
            % convert numeric waves to cell
            if isnumeric(wave_u) 
                wave_u = arrayfun(@(x) sprintf('Wave_%d', x), wave_u, 'uniform', false);
            elseif all(cellfun(@(x) ~isnan(str2double(x)), wave_u))
                wave_u = cellfun(@(x) sprintf('Wave_%s', x), wave_u, 'uniform', false);
            end
            
            % build inclusion table
            data = accumarray([id_s, wave_s], ones(ni, 1), [], @sum);
            
            % make table
            val = table;
            val.ID = id_u;
            val = [val, array2table(data, 'VariableNames', fixTableVariableNames(wave_u))];
            
        end
        
        function val = get.AllowParallelProcessing(obj)
            val = obj.pAllowParallelProcessing;
        end
        
        function set.AllowParallelProcessing(obj, val)
            if ~islogical(val)
                error('AllowParallelProcessing must be logical (true or false).')
            else
                if val
                    obj.pParForArg = inf;
                else
                    obj.pParForArg = 0;
                end
                obj.pAllowParallelProcessing = val;
            end
        end
                
%         function val = get.TallTable(obj)
%             tab = obj.WideTable;
%             if isempty(tab), return, end
%             val = table;
% %             val(:, :) = [];
% %             val.Properties.VariableNames(14:end) = [];
%             varNames = tab.Properties.VariableNames;
%             for r = 1:size(tab, 1)
%                 idx = size(val, 1) + 1;
%                 for v = 1:12
%                     val.(varNames{v})(idx) = tab.(varNames{v})(r);
%                 end
%                 for v = 13:length(varNames)
%                     val.Opea
%                 end
%             end
%             
%         end
        
    end

end
