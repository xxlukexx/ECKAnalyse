function [colour_constants] = etAoIColourConstants

    colour_constants.face = [[1:255]', zeros(255, 2)];
    colour_constants.eyes = [[1:255]', [1:255]', zeros(255, 1)];
    colour_constants.mouth = [zeros(255, 1), [1:255]', zeros(255, 1)];
    
end