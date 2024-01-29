function [table, hdr, success, outcome] = etAOIMetrics(mb, tb, AOIS)

    tmpHdr = {...
        'Prop',...
        'Duration',...
        'EntryTimeRel',...
        'EntryTimeAbs',...
        'NumFixations',...
        };
    
    numAOIS = length(AOIS);
    hdr = {};
    table = {};
    
    success = true;
    outcome = 'SUCCESS';
    
    % preprocess
    mb = etAverageEyeBuffer(mb);
    
    if all(isnan(mb(:, 7))) || all(isnan(mb(:, 8)))
        success = false;
        outcome = 'No valid samples';
        return
    end
       
    for a = 1:numAOIS
        
        % number of valid (non missing) samples
        valSamp = sum(mb(:, 7) ~= -1 & ~isnan(mb(:, 7)) &...
            mb(:, 8) ~= -1 & ~isnan(mb(:, 8)));
        
        % proportion of gaze in AOI
        hit =...
            mb(:, 7) >= AOIS(a).rect(1) &...
            mb(:, 8) >= AOIS(a).rect(2) &...
            mb(:, 7) <= AOIS(a).rect(3) &...
            mb(:, 8) <= AOIS(a).rect(4);
        prop = sum(hit) / valSamp;
                
        % find contigous runs of samples 
        ct = findcontig(hit, 1);
            
        % duration of gaze in AOI 
        if prop > 0 && ~isempty(ct)

            % calculate on/offets and durations
            onsets = tb(ct(:, 1), 1);
            offsets = tb(ct(:, 2), 1);
            durs = double(offsets - onsets);
            
            % since findconting will miss single samples, total up the
            % number of single samples 
            fs = etDetermineSampleRate(tb);
            durSingle = sum(hit) * (1000000 / fs);
            
            % calculate total duration, from contiguous runs and from
            % single samples
            dur = (sum(durs) + durSingle) / 1000000;

            % fixations (sort of)
            numFix = size(ct, 1);

            % first entry
            firstOnset = find(onsets >= tb(1, 1), 1, 'first');
            entryAbs = onsets(firstOnset);
            entryRel = double(entryAbs - tb(1, 1)) / 1000000;
            if isempty(entryAbs), entryAbs = inf; entryRel = inf; end
           
        else
            
            dur = 0;
            entryRel = inf;
            entryAbs = inf;
            numFix = 0;
            
        end
        
        hdr = [hdr, cellfun(@(x) [AOIS(a).name, '.', x], tmpHdr, 'uniform', 0)];
        
        table = [table, {...
            prop,...
            dur,...
            entryRel,...
            entryAbs,...
            numFix,...
            }];     
        
    end

end