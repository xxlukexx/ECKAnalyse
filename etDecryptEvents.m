function eb = etDecryptEvents(eb_enc, links, tasks, key)

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
%     rng(opKey, 'v5normal');

    % filter links to only include those in the tasks list
    tIdx = [];
    for t = 1:length(tasks)
        tIdx = [tIdx; find(strcmpi(links(:, 1), tasks(t)))];
    end
    links = links(tIdx, :);
    
    % make a copy of the event buffer
    eb = eb_enc;
    
    % loop through events and process
    numEvents = size(eb_enc, 1);
    for e = 1:numEvents
        
        ev = eb_enc{e, 3};
        timeStamp = eb_enc{e, 2};
        
        lab_enc = {};
        loc = 0;
        if ischar(ev)
            lab_enc = eb_enc{e, 3};
            loc = 1;
        elseif iscell(ev)
            if ischar(ev{1})
                lab_enc = eb_enc{e, 3}{1};
                loc = 2;
            end
        end
        
        if ~isempty(lab_enc)
            
            lab = decrypt(lab_enc, timeStamp);
           
            found = find(strcmpi(links(:, 2), lab), 1, 'first');
            
            if ~isempty(found)
                switch loc
                    case 1
                        % label
                        eb{e, 3} = lab;
                    case 2
                        % data
                        eb{3, 3}{1} = lab;
                end
            end
        end
            
    end
    
    function out = decrypt(in, ts)
        
        ascIn = double(in);
%         cipher = randi(96, 1, length(ascIn));
        tsChar = num2str(ts);
        tsCipher = floor(mean(double(tsChar)));
        enc = ascIn - opKey - tsCipher;
        encUnder = enc <= 0;
        if any(encUnder), enc(encUnder) = enc(encUnder) + 96; end
        out = char(enc);
        
    end
    
end