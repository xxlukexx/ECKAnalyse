function mb = etRemoveSaccades(mb, tb, sds)

    if ~exist('sds', 'var') || isempty(sds)
        sds = 1.5;
    end
    
    vel = etCalculateVelocity(mb, tb);
    [m, sd] = deNANMeanSD(vel);
   
    crit = m + (sds * sd);
    sac = abs(vel) > crit;
    
    mb(sac, 7) = nan;
    mb(sac, 8) = nan;
    mb(sac, 20) = nan;
    mb(sac, 21) = nan;

end