function out = etCharacteriseDataLoss(mb)

    out = zeros(size(mb, 1), 1);
    
    missingEyes = mb(:, 13) == 4 & mb(:, 26) == 4;
    
    gazeOnScreen =...
        (mb(:, 7) < 1 & mb(:, 7) > 0 &...
        mb(:, 8) < 1 & mb(:, 8) > 0)...
        |...
        (mb(:, 20) < 1 & mb(:, 21) > 0 &...
        mb(:, 20) < 1 & mb(:, 21) > 0);
    
    gazeOffScreen = ~missingEyes & ~gazeOnScreen;
    
    out(gazeOffScreen) = 1;
    out(gazeOnScreen) = 2;
    
end