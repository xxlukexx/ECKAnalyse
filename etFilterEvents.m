function [eventBufferOut, idx] = etFilterEvents(eventBuffer, dataMask, exactMatch)

    if isempty(eventBuffer) || (size(eventBuffer, 1) == 1 &&...
            eventBuffer{1, 1} == 0 && eventBuffer{1, 2} == 0)
        eventBufferOut = {};
        return
    end
    
    % determine the type of data mask - simple label, or more complex
    if ischar(dataMask)
        if isempty(strfind(dataMask, '*'))
            soughtLabel = dataMask;
            searchType = 1;
        else
            soughtLabel = dataMask;
            searchType = 3;
        end
    elseif isnumeric(dataMask)
        soughtLabel = num2str(dataMask);
        searchType = 1;
    elseif iscell(dataMask)
        searchType = 2;
    end
    
    if ~exist('exactMatch', 'var') || isempty(exactMatch)
        exactMatch = false;
    end

    % add index numbers to events
    numEvents = size(eventBuffer, 1);
    eventRowIndex = 1:numEvents;
    events = [eventBuffer, num2cell(eventRowIndex')];

    % filter events to only text or only cell
    labelIdx = cellfun(@ischar, events(:, 3));
    labelEvents = events(labelIdx, :);
    dataEvents = events(~labelIdx, :);
    
    % init vars
    foundDataEvents = {};
    foundLabelEvents = {};

    switch searchType
        case 1  % simple lable

            % look for onset events by label, firstly in text events...
            if ~exactMatch
                foundLabelEvents =...
                    labelEvents(...
                        ~cellfun(@isempty, (strfind(labelEvents(:, 3),...
                        soughtLabel))), :);
            else
                foundLabelEvents =...
                    labelEvents(...
                        strcmpi(labelEvents(:, 3), soughtLabel), :);
            end

            % ...now in data events
            if ~exactMatch                        
                foundDataEvents = ...
                    dataEvents(...
                        cellfun(@any, ...
                            (cellfun(@(x) strcmpi(x, soughtLabel),dataEvents(:, 3),...
                            'UniformOutput', false))), :);
            else
                foundDataEvents = ...
                    dataEvents(...
                    ~cellfun(@isempty, (...
                    strfind(...
                    cellfun(@(x) x{1}, dataEvents(:,3), 'UniformOutput', false),...
                    soughtLabel))), :);
            end

            % put found events back into one array
            eventBufferOut = etCombineSortEvents({foundLabelEvents, foundDataEvents});

        case 2  % complex (data mask)
            
            % only search in data events, as labels do not have the right sort
            % of data to use a data mask against
            error('Not yet implemented!')
            
        case 3 % text based mask (mask contains *)
            
            % convert events to text
            evTxt = etListEvents(eventBuffer);
            
            % remove headers
            evTxt = evTxt(2:end, 4);
            
            switch exactMatch
                
                case false
                    
                    % do a string search with wildcard via regexp. this will return
                    % any matches, e.g. (EEG_EVENT*11) will return (EEG_EVENT | 11)
                    % but also (EEG_EVENT | 114). In other words, it treats
                    % (EEG_EVENT*11) as (*EEG_EVENT*11*).
                    dataMaskRegExp = regexptranslate('wildcard', dataMask);
                    idx = cellfun(@(x) ~isempty(regexp(x, dataMaskRegExp, 'once')),...
                        evTxt);
                    
                case true
            
                    % this is a totally different (but much slower) method.
                    % It is able to filter more selectively, so that
                    % (EEG_EVENT*11) returns only (EEG_EVENT | 11) but NOT
                    % (EEG_EVENT | 115)
                    
                    evPP = cellfun(@(x) strsplit(x, ' '), evTxt,...
                        'uniform', 0);
                    maskPP = strsplit(dataMask, '*');
                    idx = false(length(evTxt), 1);
                    for e = 1:length(evTxt)
                        idx(e) =...
                            sum(cell2mat(cellfun(@(x) strcmpi(evPP{e}, x),...
                            maskPP, 'uniform', 0))) == length(maskPP);
                    end
                    
            end
            
            eventBufferOut = eventBuffer(idx, :);          

    end



end