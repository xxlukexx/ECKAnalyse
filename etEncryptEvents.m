function eb = etEncryptEvents(eb, links, tasks, key)

    % check input args
    if ~exist('links', 'var') || isempty(links)
        error('Invalid or empty links array passed.')
    end
    
    if ischar(links)
        if exist(links, 'file')
            tmp = load(links);
            links = tmp.links;
        else
            error('Attempted to load passed links argument as a file, file not found.')
        end
    elseif ~iscell(links) && ~size(links, 2) == 2
        error('Invalid or empty links array passed.')
    end
    
    % seed random number generator with encryption key
    ascKey = double(key);
    opKey = floor(mean(ascKey));

    % filter links to only include those in the tasks list
    tIdx = [];
    for t = 1:length(tasks)
        tIdx = [tIdx; find(strcmpi(links(:, 1), tasks(t)))];
    end
    links = links(tIdx, :);
    
    % loop through events and process
    numEvents = size(eb, 1);
    for e = 1:numEvents
        
        ev = eb{e, 3};
        timeStamp = eb{e, 2};
        
        lab = {};
        loc = 0;
        if ~isempty(ev) && ischar(ev)
            lab = eb{e, 3};
            loc = 1;
        elseif ~isempty(ev) && iscell(ev)
            if ischar(ev{1})
                lab = eb{e, 3}{1};
                loc = 2;
            end
        end
        
        if ~isempty(lab)
            
            lab_enc = encrypt(lab, timeStamp);

            found = find(strcmpi(links(:, 2), lab), 1, 'first');
            if ~isempty(found)
                switch loc
                    case 1
                        % label
                        eb{e, 3} = lab_enc;
                        enc;
                    case 2
                        % data
                        eb{e, 3}{1} = lab_enc;
                end
            end
        end
            
    end
    
    function out = encrypt(in, ts)
        
        ascIn = double(in);
        tsChar = num2str(ts);
        tsCipher = floor(mean(double(tsChar)));
        enc = ascIn + opKey + tsCipher;
        encOver = enc > 128;
        if any(encOver), enc(encOver) = enc(encOver) - 96; end
        out = char(enc);
        
    end
    
end