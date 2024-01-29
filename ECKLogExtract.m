function [ data, headingIdx, logFunIdx ] = ECKLogExtract( log, trialFun, headings )

    if ~exist('trialFun', 'var') || isempty(trialFun) || ~ischar(trialFun)
        error('Must supply a valid trial function name.')
    end

    if ~exist('headings', 'var') || isempty(headings) ||...
            ~(ischar(headings) || iscell(headings))
        error('Must supply headings as either char or cell array of chars.')
    end
    
    % if headings is a string, convert to a cell
    if ischar(headings), headings={headings}; end
    headingIdx = nan(size(headings));
    
    % find log
    logFunIdx = find(strcmpi(log.FunName,trialFun),1,'first');
    
    if isempty(logFunIdx)
%         error('No log for trial function %s was found.', trialFun)
        data = [];
    else

        % find columns
        numHeadings = size(headings, 2);
        numSamples = size(log.Data{logFunIdx}, 1);
        headFound = zeros(1,numHeadings);
        data = cell(numSamples, numHeadings);

        for curHead = 1:numHeadings

            % find header
            headSought = headings{curHead};
            headFound =...
                find(strcmpi(log.Headings{logFunIdx}, headSought), 1, 'first');

            if isempty(headFound)
                error('Heading "%s" (and perhaps others) not found in log file.',...
                    headSought);
            end
            
            % find associated data
            data(:, curHead) = log.Data{logFunIdx}(:, headFound);
            headingIdx(curHead) = headFound;

        end
        
    end

end

