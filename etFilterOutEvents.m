function [mbOut, tbOut] = etFilterOutEvents(mb, tb, eb, onSought,...
    offSought)

    % find onset and offset events
    onEv = etFilterEvents(eb, onSought);
    offEv = etFilterEvents(eb, offSought);    
    
    if isempty(onEv) || isempty(offEv) || all(all(mb == 0)) || all(all(tb == 0))
        mbOut = mb;
        tbOut = tb;
        return
    end

    if size(onEv) ~= size(offEv)
        error('Different no. of on/offset events returned.')
    end
    
    % load data up til first onset into output var
    offTime = onEv{1, 2};
    offSamp = etTimeToSample(tb, offTime);
    mbOut = mb(1:offSamp, :);
    tbOut = tb(1:offSamp, :);

    % loop through and load data between off-onset pairs
    for curEv = 1:size(onEv, 1) - 1
        onTime = offEv{curEv, 2};
        onSamp = etTimeToSample(tb, onTime);
        
        offTime = onEv{curEv + 1, 2};
        offSamp = etTimeToSample(tb, offTime);
        
        mbOut = [mbOut; mb(onSamp:offSamp, :)];
        tbOut = [tbOut; tb(onSamp:offSamp, :)];
    end
    
    % load data from last offset til end
    onTime = offEv{end, 2};
    onSamp = etTimeToSample(tb, onTime);
    mbOut = [mbOut; mb(onSamp:end, :)];
    tbOut = [tbOut; tb(onSamp:end, :)];
    
end