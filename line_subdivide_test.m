tic

numLines = size(quiv, 2) / 2;
numSegs = 5;
out = zeros(2, numLines * (numSegs - 1) * 2);
tmp = zeros(2, numSegs);
so = [1, sort(repmat(2:numSegs - 1, 1, 2)), numSegs];
c1 = 1;
c2 = 2 * (numSegs - 1);
for l = 1:2:numLines * 2
   
    x1 = quiv(1, l);
    y1 = quiv(2, l);
    x2 = quiv(1, l + 1);
    y2 = quiv(2, l + 1);
    
%     c1 = (numSegs - 1) * (l - 1) + 1;
%     c2 = (numSegs - 1) * l * 2;
    tmp(1, :) = linspace(x1, x2, numSegs);
    tmp(2, :) = linspace(y1, y2, numSegs);
    out(:, c1:c2) = tmp(:, so);
    
    c1 = c1 + (2 * (numSegs - 1));
    c2 = c2 + (2 * (numSegs - 1));
    
end

toc